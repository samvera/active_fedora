module ActiveFedora
  # = Active Fedora Ldp Cache
  class LdpCache
    module ClassMethods
      # Enable the query cache within the block if Active Fedora is configured.
      # If it's not, it will execute the given block.
      def cache(&block)
        connection = ActiveFedora.fedora.connection
        connection.cache(&block)
      end

      # Disable the query cache within the block if Active Fedora is configured.
      # If it's not, it will execute the given block.
      def uncached(&block)
        ActiveFedora.fedora.connection.uncached(&block)
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      ActiveFedora.fedora.connection.enable_cache!

      response = @app.call(env)
      response[2] = Rack::BodyProxy.new(response[2]) do
        reset_cache_settings
      end

      response
    ensure
      reset_cache_settings
    end

    private

      def reset_cache_settings
        ActiveFedora.fedora.connection.clear_cache
        ActiveFedora.fedora.connection.disable_cache!
      end
  end
end
