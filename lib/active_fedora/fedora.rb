module ActiveFedora
  class Fedora
    def initialize(config)
      @config = config
      init_base_path
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

    def connection
      @connection ||= CachingConnection.new(authorized_connection)
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
      connection.head(root_resource_path)
      ActiveFedora::Base.logger.info "Attempted to init base path `#{root_resource_path}`, but it already exists" if ActiveFedora::Base.logger
      false
    rescue Ldp::NotFound
      if !host.downcase.end_with?("/rest")
        ActiveFedora::Base.logger.warn "Fedora URL (#{host}) does not end with /rest. This could be a problem. Check your fedora.yml config"
      end
      connection.put(root_resource_path, BLANK).success?
    end

    # Remove a leading slash from the base_path
    def root_resource_path
      @root_resource_path ||= base_path.sub(SLASH, BLANK)
    end

    def authorized_connection
      connection = Faraday.new(host)
      connection.basic_auth(user, password)
      connection
    end

  end
end
