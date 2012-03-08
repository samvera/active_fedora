module ActiveFedora 
  class Config
    attr_reader :credentials
    def initialize(val)
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
          ActiveSupport::Deprecation.warn("Configuring fedora with \":url\" without :user and :password is no longer supported.")
          u = URI.parse @credentials[:url]
          @credentials[:user] = u.user
          @credentials[:password] = u.password
          @credentials[:url] = "#{u.scheme}://#{u.host}:#{u.port}#{u.path}"
        end
        unless @credentials.has_key?(:user) && @credentials.has_key?(:password) && @credentials.has_key?(:url)
          raise ActiveFedora::ConfigurationError, "Fedora configuration must provide :user, :password and :url."
        end
    end
  end
end
