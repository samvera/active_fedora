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
    end

    def host
      @config[:url]
    end

    def base_path
      @config[:base_path] || '/'
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

    def connection
      @connection ||= begin
        init_base_path
        build_connection
      end
    end

    def clean_connection
      @clean_connection ||= CleanConnection.new(connection)
    end

    def ldp_resource_service
      @service ||= LdpResourceService.new(connection)
    end

    SLASH = '/'.freeze
    BLANK = ''.freeze

    # Call this to create a Container Resource to act as the base path for this connection
    def init_base_path
      return if @initialized
      connection = build_connection

      connection.head(root_resource_path)
      ActiveFedora::Base.logger.info "Attempted to init base path `#{root_resource_path}`, but it already exists" if ActiveFedora::Base.logger
      @initialized = true
      false
    rescue Ldp::NotFound
      unless host.downcase.end_with?("/rest")
        ActiveFedora::Base.logger.warn "Fedora URL (#{host}) does not end with /rest. This could be a problem. Check your fedora.yml config"
      end
      @initialized = connection.put(root_resource_path, BLANK).success?
    end

    # Remove a leading slash from the base_path
    def root_resource_path
      @root_resource_path ||= base_path.sub(SLASH, BLANK)
    end

    def build_connection
      # The InboundRelationConnection does provide more data, useful for
      # things like ldp:IndirectContainers, but it's imposes a significant
      # performance penalty on every request
      #   @connection ||= InboundRelationConnection.new(CachingConnection.new(authorized_connection))
      CachingConnection.new(authorized_connection, omit_ldpr_interaction_model: true)
    end

    def authorized_connection
      options = {}
      options[:ssl] = ssl_options if ssl_options
      connection = Faraday.new(host, options)
      connection.basic_auth(user, password)
      connection
    end
  end
end
