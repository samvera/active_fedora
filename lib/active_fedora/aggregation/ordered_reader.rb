module ActiveFedora::Aggregation
  ##
  # Lazily iterates over a doubly linked list, fixing up nodes if necessary.
  class OrderedReader
    include Enumerable
    attr_reader :root
    def initialize(root)
      @root = root
    end

    def each
      proxy = first_head
      while proxy
        yield proxy unless proxy.nil?
        next_proxy = proxy.next
        next_proxy.try(:prev=, proxy) if next_proxy && next_proxy.prev != proxy
        proxy = next_proxy
      end
    end

    private

      def first_head
        root.head
      end
  end
end
