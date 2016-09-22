module ActiveFedora
  module Orders
    ##
    # Ruby object representation of an ORE doubly linked list.
    class OrderedList
      include Enumerable
      attr_reader :graph, :head_subject, :tail_subject
      attr_writer :head, :tail
      delegate :each, to: :ordered_reader
      delegate :length, to: :to_a
      # @param [::RDF::Enumerable] graph Enumerable where ORE statements are
      #   stored.
      # @param [::RDF::URI] head_subject URI of head node in list.
      # @param [::RDF::URI] tail_subject URI of tail node in list.
      def initialize(graph, head_subject, tail_subject)
        @graph = if graph.respond_to?(:graph)
                   graph.graph.data
                 else
                   graph
                 end
        @head_subject = head_subject
        @tail_subject = tail_subject
        @node_cache ||= NodeCache.new
        @changed = false
        tail
      end

      # @return [HeadSentinel] Sentinel for the top of the list. If not empty,
      #  head.next is the first element.
      def head
        @head ||= HeadSentinel.new(self, next_node: build_node(head_subject))
      end

      # @return [TailSentinel] Sentinel for the bottom of the list. If not
      #   empty, tail.prev is the first element.
      def tail
        @tail ||=
          begin
            if tail_subject
              TailSentinel.new(self, prev_node: build_node(tail_subject))
            else
              head.next
            end
          end
      end

      # @param [Integer] key Position of the proxy
      # @return [ListNode] Node for the proxy at the given position
      def [](key)
        list = ordered_reader.take(key + 1)
        list[key]
      end

      # @return [ListNode] Last node in the list.
      def last
        if empty?
          nil
        else
          tail.prev
        end
      end

      # @param [Array<ListNode>] Nodes to remove.
      # @return [OrderedList] List with node removed.
      def -(other)
        other.each do |node|
          delete_node(node)
        end
        self
      end

      # @return [Boolean]
      def empty?
        head.next == tail
      end

      # @param [ActiveFedora::Base] target Target to append to list.
      # @option [::RDF::URI, ActiveFedora::Base] :proxy_in Proxy in to
      #   assert on the created node.
      def append_target(target, proxy_in: nil)
        node = build_node(new_node_subject)
        node.target = target
        node.proxy_in = proxy_in
        append_to(node, tail.prev)
      end

      # @param [Integer] loc Location to insert target at
      # @param [ActiveFedora::Base] target Target to insert
      def insert_at(loc, target, proxy_in: nil)
        node = build_node(new_node_subject)
        node.target = target
        node.proxy_in = proxy_in
        if loc.zero?
          append_to(node, head)
        else
          append_to(node, ordered_reader.take(loc).last)
        end
      end

      # @param [Integer] loc Location to insert target at
      # @param [String] proxy_for proxyFor to add
      def insert_proxy_for_at(loc, proxy_for, proxy_in: nil)
        node = build_node(new_node_subject)
        node.proxy_for = proxy_for
        node.proxy_in = proxy_in
        if loc.zero?
          append_to(node, head)
        else
          append_to(node, ordered_reader.take(loc).last)
        end
      end

      # @param [ListNode] node Node to delete
      def delete_node(node)
        node = ordered_reader.find { |x| x == node }
        if node
          prev_node = node.prev
          next_node = node.next
          node.prev.next = next_node
          node.next.prev = prev_node
          @changed = true
          node
        end
      end

      # @param [Integer] loc Index of node to delete.
      def delete_at(loc)
        return nil if loc.nil?
        arr = ordered_reader.take(loc + 1)
        delete_node(arr.last) if arr.length == loc + 1
      end

      # @param obj target of node to delete.
      def delete_target(obj)
        nodes_to_remove = ordered_reader.select { |list_node| obj.id == list_node.target_id }
        nodes_to_remove.each { |list_node| delete_node(list_node) }
        nodes_to_remove.last.try(:target)
      end

      # @return [Boolean] Whether this list was changed since instantiation.
      def changed?
        @changed
      end

      # Marks this ordered list as about to change. Useful for when changing
      # proxies individually.
      def order_will_change!
        @changed = true
      end

      # @return [::RDF::Graph] Graph representation of this list.
      def to_graph
        ::RDF::Graph.new.tap do |g|
          array = to_a
          array.map(&:to_graph).each do |resource_graph|
            g << resource_graph
          end
        end
      end

      # Marks this list as not changed.
      def changes_committed!
        @changed = false
      end

      # @return IDs of all ordered targets, in order
      def target_ids
        to_a.map(&:target_id)
      end

      # @return The node all proxies are a proxy in.
      # @note If there are multiple proxy_ins this will log a warning and return
      #   the first.
      def proxy_in
        proxies = to_a.map(&:proxy_in_id).compact.uniq
        if proxies.length > 1
          ActiveFedora::Base.logger.warn "WARNING: List contains nodes aggregated under different URIs. Returning only the first."
        end
        proxies.first
      end

      private

        attr_reader :node_cache

        def append_to(source, append_node)
          source.prev = append_node
          if append_node.next
            append_node.next.prev = source
            source.next = append_node.next
          else
            self.tail = source
          end
          append_node.next = source
          @changed = true
        end

        def ordered_reader
          ActiveFedora::Aggregation::OrderedReader.new(self)
        end

        def build_node(subject = nil)
          return nil unless subject
          node_cache.fetch(subject) do
            ActiveFedora::Orders::ListNode.new(node_cache, subject, graph)
          end
        end

        def new_node_subject
          node = ::RDF::URI("##{::RDF::Node.new.id}")
          while node_cache.key?(node)
            node = ::RDF::URI("##{::RDF::Node.new.id}")
          end
          node
        end

        class NodeCache
          def initialize
            @cache ||= {}
          end

          def fetch(uri)
            @cache[uri] ||= yield if block_given?
          end

          def key?(key)
            @cache.key?(key)
          end
        end

        class Sentinel
          attr_reader :parent
          attr_writer :next, :prev
          def initialize(parent, next_node: nil, prev_node: nil)
            @parent = parent
            @next = next_node
            @prev = prev_node
          end

          attr_reader :next

          attr_reader :prev

          def nil?
            true
          end

          def rdf_subject
            nil
          end
        end

        class HeadSentinel < Sentinel
          def initialize(*args)
            super
            @next ||= TailSentinel.new(parent, prev_node: self)
          end
        end

        class TailSentinel < Sentinel
          def initialize(*args)
            super
            prev.next = self if prev && prev.next != self
          end
        end
    end
  end
end
