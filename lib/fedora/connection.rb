require "base64"
gem 'multipart-post'
require 'net/http/post/multipart'
require 'net/http/persistent'
require 'cgi'
require "mime/types"
require 'net/http'
require 'net/https'



module Fedora
  # This class is based on ActiveResource::Connection so MIT license applies.
  class ConnectionError < StandardError # :nodoc:
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message  = message
    end

    def to_s
      "Failed with #{response.code} #{@message.to_s}"
    end
  end

  # 3xx Redirection
  class Redirection < ConnectionError # :nodoc:
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end    
  end 

  # 4xx Client Error
  class ClientError < ConnectionError; end # :nodoc:
  
  # 400 Bad Request
  class BadRequest < ClientError; end # :nodoc
  
  # 401 Unauthorized
  class UnauthorizedAccess < ClientError; end # :nodoc
  
  # 403 Forbidden
  class ForbiddenAccess < ClientError; end # :nodoc
  
  # 404 Not Found
  class ResourceNotFound < ClientError; end # :nodoc:
  
  # 409 Conflict
  class ResourceConflict < ClientError; end # :nodoc:

  # 415 Unsupported Media Type
  class UnsupportedMediaType < ClientError; end # :nodoc:

  # 5xx Server Error
  class ServerError < ConnectionError; end # :nodoc:

  # 405 Method Not Allowed
  class MethodNotAllowed < ClientError # :nodoc:
    def allowed_methods
      @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
    end
  end

  # Class to handle connections to remote web services.
  # This class is used by ActiveResource::Base to interface with REST
  # services.
  class Connection

    CLASSES = [
      Net::HTTP::Delete,
      Net::HTTP::Get,
      Net::HTTP::Head,
      Net::HTTP::Post,
      Net::HTTP::Put
    ].freeze

    MIME_TYPES = {
      :binary => "application/octet-stream",
      :json   => "application/json",
      :xml    => "text/xml",
      :none   => "text/plain"
    }.freeze


    attr_reader :site, :surrogate
    attr_accessor :format

    class << self
      def requests
        @@requests ||= []
      end
    end

    # The +site+ parameter is required and will set the +site+
    # attribute to the URI for the remote resource service.
    def initialize(site, format = ActiveResource::Formats[:xml], surrogate=nil)
      raise ArgumentError, 'Missing site URI' unless site
      self.site = site
      self.format = format
      @surrogate=surrogate
    end

    ##
    # Perform an HTTP Delete, Head, Get, Post, or Put.

    CLASSES.each do |clazz|
      verb = clazz.to_s.split("::").last.downcase

      define_method verb do |*args|
        path = args[0]
        params = args[1] || {}

        response_for clazz, path, params
      end
    end

    # Set URI for remote service.
    def site=(site)
      @site = site.is_a?(URI) ? site : URI.parse(site)
    end


    private

    # Makes request to remote service.
    def response_for(clazz, path, params)
      logger.debug "#{clazz} #{path}"
      request = clazz.new path
      request.body = params[:body]

      handle_request request, params[:upload], params[:type], params[:headers] || {}
    end


    def handle_request request, upload, type, headers
      handle_uploads request, upload, type
      handle_headers request, upload, type, headers
      result = http.request self.site, request
      handle_response(result)
    end

    ##
    # Handle chunked uploads.
    #
    # +request+: A Net::HTTP request Object.
    # +upload+: A Hash with the following keys:
    #   +:file+: The file to be HTTP chunked uploaded.
    #   +:headers+: A Hash containing additional HTTP headers.
    # +:type+: A Symbol with the mime_type.

    def handle_uploads request, upload, type
      return unless upload
      io = nil
      if upload[:file].is_a?(File)
         io = File.open upload[:file].path
      else
        io = upload[:file]
      end

      request.body_stream = io
    end


    def handle_headers request, upload, type, headers
      request.basic_auth(self.site.user, self.site.password) if self.site.user

      request.add_field "Accept", mime_type(type)
      request.add_field "Content-Type", mime_type(type) if requires_content_type? request

      headers.merge! chunked_headers upload
      headers.each do |header, value|
        request[header] = value
      end
    end

    ##
    # Setting of chunked upload headers.
    #
    # +upload+: A Hash with the following keys:
    #   +:file+: The file to be HTTP chunked uploaded.

    def chunked_headers upload
      return {} unless upload

      chunked_headers = {
        "Content-Type"      => mime_type(:binary),
        "Transfer-Encoding" => "chunked"
      }.merge upload[:headers] || {}
    end

    def requires_content_type? request
      [Net::HTTP::Post, Net::HTTP::Put].include? request.class
    end

    # Handles response and error codes from remote service.
    def handle_response(response)
      message = "Error from Fedora: #{response.body}"
      logger.debug "Response: #{response.code}"
      case response.code.to_i
      when 301,302
        raise(Redirection.new(response))
      when 200...400
        response
      when 400
        raise(BadRequest.new(response, message))
      when 401
        raise(UnauthorizedAccess.new(response, message))
      when 403
        raise(ForbiddenAccess.new(response, message))
      when 404
        raise(ResourceNotFound.new(response, message))
      when 405
        raise(MethodNotAllowed.new(response, message))
      when 409
        raise(ResourceConflict.new(response, message))
      when 415
        raise UnsupportedMediaType.new(response, message)
      when 422
        raise(ResourceInvalid.new(response, message))
      when 423...500
        raise(ClientError.new(response, message))
      when 500...600
        raise(ServerError.new(response, message))
      else
        raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
      end
    end

    def mime_type type
      if type.kind_of? String
        type
      else
        MIME_TYPES[type] || MIME_TYPES[:xml]
      end
    end

    # Creates new Net::HTTP instance for communication with
    # remote service and resources.
    def http
      @http ||= Net::HTTP::Persistent.new#(@site)
      if(@site.is_a?(URI::HTTPS))
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        if (defined?(SSL_CLIENT_CERT_FILE) && !SSL_CLIENT_CERT_FILE.nil? && defined?(SSL_CLIENT_KEY_FILE) && !SSL_CLIENT_KEY_FILE.nil? && defined?(SSL_CLIENT_KEY_PASS) && !SSL_CLIENT_KEY_PASS.nil?)
          @http.cert = OpenSSL::X509::Certificate.new( File.read(SSL_CLIENT_CERT_FILE) )
          @http.key = OpenSSL::PKey::RSA.new( File.read(SSL_CLIENT_KEY_FILE), SSL_CLIENT_KEY_PASS )
        end
      end
      @http
    end

  end
end
