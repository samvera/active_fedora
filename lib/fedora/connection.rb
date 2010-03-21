require "base64"
gem 'multipart-post'
require 'net/http/post/multipart'
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
      "Failed with #{response.code} #{response.message if response.respond_to?(:message)}"
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

    # Set URI for remote service.
    def site=(site)
      @site = site.is_a?(URI) ? site : URI.parse(site)
    end

    # Execute a GET request.
    # Used to get (find) resources.
    def get(path, headers = {})
      format.decode(request(:get, path, build_request_headers(headers)).body)
    end

    # Execute a DELETE request (see HTTP protocol documentation if unfamiliar).
    # Used to delete resources.
    def delete(path, headers = {})
      request(:delete, path, build_request_headers(headers))
    end



    def raw_get(path, headers = {})
      request(:get, path, build_request_headers(headers))
    end
    def post(path, body='', headers={})
      do_method(:post, path, body, headers)
    end
    def put( path, body='', headers={})
      do_method(:put, path, body, headers)
    end

    private
    def do_method(method, path, body = '', headers = {})
      meth_map={:put=>Net::HTTP::Put::Multipart, :post=>Net::HTTP::Post::Multipart}
      raise "undefined method: #{method}" unless meth_map.has_key? method
      headers = build_request_headers(headers) 
      if body.respond_to?(:read)
        if body.respond_to?(:original_filename?)
          filename = File.basename(body.original_filename)
          io = UploadIO.new(body, mime_type,filename)
        elsif body.path
          filename = File.basename(body.path)
        else
          filename="NOFILE"
        end
        mime_types = MIME::Types.of(filename)
        mime_type ||= mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type

        io = nil
        if body.is_a?(File)
          io = UploadIO.new(body.path,mime_type)
        else
          io =UploadIO.new(body, mime_type, filename)
        end

        req = meth_map[method].new(path, {:file=>io}, headers)
        multipart_request(req)
      else
        request(method, path, body.to_s, headers)
      end
    end
    def multipart_request(req)
      result = nil
      result = http.start do |conn|
        conn.read_timeout=60600 #these can take a while
        conn.request(req)
      end
      handle_response(result)

    end

    # Makes request to remote service.
    def request(method, path, *arguments)
      result = http.send(method, path, *arguments)
      handle_response(result)
    end

    # Handles response and error codes from remote service.
    def handle_response(response)
      case response.code.to_i
      when 301,302
        raise(Redirection.new(response))
      when 200...400
        response
      when 400
        raise(BadRequest.new(response))
      when 401
        raise(UnauthorizedAccess.new(response))
      when 403
        raise(ForbiddenAccess.new(response))
      when 404
        raise(ResourceNotFound.new(response))
      when 405
        raise(MethodNotAllowed.new(response))
      when 409
        raise(ResourceConflict.new(response))
      when 422
        raise(ResourceInvalid.new(response))
      when 401...500
        raise(ClientError.new(response))
      when 500...600
        raise(ServerError.new(response))
      else
        raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
      end
    end

    # Creates new Net::HTTP instance for communication with
    # remote service and resources.
    def http
      http             = Net::HTTP.new(@site.host, @site.port)
      http.use_ssl     = @site.is_a?(URI::HTTPS)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl
      http
    end

    def default_header
      @default_header ||= { 'Content-Type' => format.mime_type }
    end

    # Builds headers for request to remote service.
    def build_request_headers(headers)
      headers.merge!({"From"=>surrogate}) if @surrogate
      authorization_header.update(default_header).update(headers)
    end

    # Sets authorization header; authentication information is pulled from credentials provided with site URI.
    def authorization_header
      (@site.user || @site.password ? { 'Authorization' => 'Basic ' + ["#{@site.user}:#{ @site.password}"].pack('m').delete("\r\n") } : {})
    end
  end
end
