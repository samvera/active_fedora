module ActiveFedora::Associations
  class DeleteProxy
    def self.call(proxy_ids:, proxy_class:)
      new(proxy_ids: proxy_ids, proxy_class: proxy_class).run
    end
    attr_reader :proxy_ids, :proxy_class

    def initialize(proxy_ids:, proxy_class:)
      @proxy_ids = proxy_ids
      @proxy_class = proxy_class
    end

    def run
      proxies.each(&:delete)
    end

    private

      def proxies
        @proxies ||= proxy_ids.map { |uri| uri_to_proxy(uri) }
      end

      def uri_to_proxy(uri)
        proxy_class.find(proxy_class.uri_to_id(uri))
      end
  end
end
