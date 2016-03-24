module ActiveFedora::Orders
  class ListNode
    attr_reader :rdf_subject
    attr_accessor :prev, :next, :target
    attr_writer :next_uri, :prev_uri
    attr_accessor :proxy_in, :proxy_for
    def initialize(node_cache, rdf_subject, graph = RDF::Repository.new)
      @rdf_subject = rdf_subject
      @graph = graph
      @node_cache = node_cache
      Builder.new(rdf_subject, graph).populate(self)
    end

    # Returns the next proxy or a tail sentinel.
    # @return [ActiveFedora::Orders::ListNode]
    def next
      @next ||=
        if next_uri
          node_cache.fetch(next_uri) do
            node = self.class.new(node_cache, next_uri, graph)
            node.prev = self
            node
          end
        end
    end

    # Returns the previous proxy or a head sentinel.
    # @return [ActiveFedora::Orders::ListNode]
    def prev
      @prev ||=
        if prev_uri
          node_cache.fetch(prev_uri) do
            node = self.class.new(node_cache, prev_uri, graph)
            node.next = self
            node
          end
        end
    end

    # Graph representation of node.
    # @return [ActiveFedora::Orders::ListNode::Resource]
    def to_graph
      g = Resource.new(rdf_subject)
      g.proxy_for = target_uri
      g.proxy_in = proxy_in.try(:uri)
      g.next = self.next.try(:rdf_subject)
      g.prev = prev.try(:rdf_subject)
      g
    end

    # Object representation of proxyFor
    # @return [ActiveFedora::Base]
    def target
      @target ||=
        if proxy_for.present?
          node_cache.fetch(proxy_for) do
            ActiveFedora::Base.from_uri(proxy_for, nil)
          end
        end
    end

    def target_uri
      RDF::URI(ActiveFedora::Base.id_to_uri(target_id)) if target_id
    end

    def target_id
      MaybeID.new(@target.try(:id) || proxy_for).value
    end

    # Persists target if it's been accessed or set.
    def save_target
      if @target
        @target.save
      else
        true
      end
    end

    def proxy_in_id
      MaybeID.new(@proxy_in.try(:id) || proxy_in).value
    end

    # Returns an ID whether or not the given value is a URI.
    class MaybeID
      attr_reader :uri_or_id
      def initialize(uri_or_id)
        @uri_or_id = uri_or_id
      end

      def value
        id_composite.new([uri_or_id], translator).to_a.first
      end

      private

        def id_composite
          ActiveFedora::Associations::IDComposite
        end

        def translator
          ActiveFedora::Base.translate_uri_to_id
        end
    end

    # Methods necessary for association functionality
    def destroyed?
      false
    end

    def marked_for_destruction?
      false
    end

    def valid?
      true
    end

    def changed_for_autosave?
      true
    end

    def new_record?
      @target && @target.new_record?
    end

    private

      attr_reader :next_uri, :prev_uri, :graph, :node_cache

      class Builder
        attr_reader :uri, :graph
        def initialize(uri, graph)
          @uri = uri
          @graph = graph
        end

        def populate(instance)
          instance.proxy_for = resource.proxy_for.first
          instance.proxy_in = resource.proxy_in.first
          instance.next_uri = resource.next.first
          instance.prev_uri = resource.prev.first
        end

        private

          def resource
            @resource ||= Resource.new(uri, data: graph)
          end
      end

      class Resource < ActiveTriples::Resource
        property :proxy_for, predicate: ::RDF::Vocab::ORE.proxyFor, cast: false
        property :proxy_in, predicate: ::RDF::Vocab::ORE.proxyIn, cast: false
        property :next, predicate: ::RDF::Vocab::IANA.next, cast: false
        property :prev, predicate: ::RDF::Vocab::IANA.prev, cast: false
        def final_parent
          parent
        end
      end
  end
end
