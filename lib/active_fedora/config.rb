module ActiveFedora 
  class Config
    attr_reader :path, :credentials
    def initialize(config_path, env)
      @path = config_path
      val = YAML.load(File.open(config_path))[env]
      if val.is_a? Array
        init_shards(val)
      else 
        init_single(val)
      end
    end

    def sharded?
      credentials.is_a? Array
    end

    private

    def init_shards(vals)
        @credentials = vals.map(&:symbolize_keys)
    end

    def init_single(vals)
        @credentials = vals.symbolize_keys
        if @credentials[:url] && !@credentials[:user]
          ActiveSupport::Deprecation.warn("Using \":url\" in the fedora.yml file without :user and :password is no longer supported") 
          u = URI.parse @credentials[:url]
          @credentials[:user] = u.user
          @credentials[:password] = u.password
          @credentials[:url] = "#{u.scheme}://#{u.host}:#{u.port}#{u.path}"
        end
        unless @credentials.has_key?(:user) && @credentials.has_key?(:password) && @credentials.has_key?(:url)
          raise ActiveFedora::ConfigurationError, "You must provide user, password and url in the #{env} section of #{@path}"
        end
    end
  end
end
