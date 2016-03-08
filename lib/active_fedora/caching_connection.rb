module ActiveFedora
  class CachingConnection < Ldp::Client
    def initialize(host, options = {})
      super
      @cache = {}
      @cache_enabled = false
    end

    def get(url, options = {})
      if @cache_enabled
        cache_resource(url) { super }
      else
        super
      end
    end

    def post(*)
      clear_cache if @cache_enabled
      super
    end

    def put(*)
      clear_cache if @cache_enabled
      super
    end

    def patch(*)
      clear_cache if @cache_enabled
      super
    end

    # Enable the cache within the block.
    def cache
      old = @cache_enabled
      @cache_enabled = true
      yield
    ensure
      @cache_enabled = old
      clear_cache unless @cache_enabled
    end

    def enable_cache!
      @cache_enabled = true
    end

    def disable_cache!
      @cache_enabled = false
    end

    # Disable the query cache within the block.
    def uncached
      old = @cache_enabled
      @cache_enabled = false
      yield
    ensure
      @cache_enabled = old
    end

    def clear_cache
      @cache.clear
    end

    private

      def log(url)
        ActiveSupport::Notifications.instrument("ldp.active_fedora",
                                                id: url, name: "Load LDP", ldp_service: object_id) { yield }
      end

      def cache_resource(url, &_block)
        result =
          if @cache.key?(url)
            ActiveSupport::Notifications.instrument("ldp.active_fedora",
                                                    id: url, name: "CACHE", ldp_service: object_id)
            @cache[url]
          else
            @cache[url] = log(url) { yield }
          end
        result.dup
      end
  end
end
