require 'faraday'
require 'faraday-encoding'

module ActiveFedora
  class Fedora
    class << self
      def register(options = {})
        ActiveFedora::RuntimeRegistry.fedora_connection = Fedora.new(ActiveFedora.fedora_config.credentials.merge(options))
      end

      def instance
        register unless ActiveFedora::RuntimeRegistry.fedora_connection

        ActiveFedora::RuntimeRegistry.fedora_connection
      end

      def reset!
        ActiveFedora::RuntimeRegistry.fedora_connection = nil
      end
    end

    def initialize(config)
      @config = config

      validate_options
    end

    def host
      @config[:url].sub(/\/$/, BLANK)
    end

    def base_path
      @config[:base_path] || SLASH
    end

    def base_uri
      host + base_path.sub(/\/$/, BLANK)
    end

    def user
      @config[:user]
    end

    def password
      @config[:password]
    end

    def ssl_options
      @config[:ssl]
    end

    def request_options
      @config[:request]
    end

    def connection
      @connection ||= begin
        build_connection
      end
    end

    def clean_connection
      @clean_connection ||= CleanConnection.new(connection)
    end

    def caching_connection(options = {})
      CachingConnection.new(authorized_connection, options)
    end

    def ldp_resource_service
      @service ||= LdpResourceService.new(connection)
    end

    SLASH = '/'.freeze
    BLANK = ''.freeze

    # Remove a leading slash from the base_path
    def root_resource_path
      @root_resource_path ||= base_path.sub(SLASH, BLANK)
    end

    def build_connection
      # The InboundRelationConnection does provide more data, useful for
      # things like ldp:IndirectContainers, but it's imposes a significant
      # performance penalty on every request
      #   @connection ||= InboundRelationConnection.new(caching_connection(omit_ldpr_interaction_model: true))
      InitializingConnection.new(caching_connection(omit_ldpr_interaction_model: true), root_resource_path)
    end

    def authorized_connection
      options = {}
      options[:ssl] = ssl_options if ssl_options
      options[:request] = request_options if request_options
      Faraday.new(host, options) do |conn|
        conn.response :encoding # use Faraday::Encoding middleware
        conn.adapter Faraday.default_adapter # net/http
        if Gem::Version.new(Faraday::VERSION) < Gem::Version.new('2')
          conn.request :basic_auth, user, password
        else
          conn.request :authorization, :basic, user, password
        end
      end
    end

    def validate_options
      unless host.downcase.end_with?("/rest")
        ActiveFedora::Base.logger.warn "Fedora URL (#{host}) does not end with /rest. This could be a problem. Check your fedora.yml config"
      end
    end

    def ntriples_connection
      authorized_connection.tap { |conn| conn.headers['Accept'] = 'application/n-triples' }
    end

    def build_ntriples_connection
      ActiveFedora::InitializingConnection.new(ActiveFedora::CachingConnection.new(ntriples_connection, omit_ldpr_interaction_model: true), root_resource_path)
    end
  end
end
