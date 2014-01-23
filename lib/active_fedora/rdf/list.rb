module ActiveFedora::Rdf
  ##
  # An implementation of RDF::List intregrated with ActiveFedora::Rdf.
  #
  # A thoughtful reflection period is encouraged before using the
  # rdf:List concept in your data. The community may pursue other
  # options for ordered sets.
  class List < RDF::List
    include ActiveFedora::Rdf::NestedAttributes
    extend Configurable
    extend Properties

    delegate :rdf_subject, :mark_for_destruction, :marked_for_destruction?, :set_value, :get_values, :parent, :dump, :attributes=, to: :resource
    alias_method :to_ary, :to_a

    class << self
      def from_uri(uri, vals)
        list = ListResource.from_uri(uri, vals)
        self.new(list.rdf_subject, list)
      end
    end

    def resource
      graph
    end

    def initialize(*args)
      super
      parent = graph.parent if graph.respond_to? :parent
      @graph = ListResource.new(subject) << graph unless graph.kind_of? Resource
      graph << parent if parent
      graph.list = self
      graph.singleton_class.properties = self.class.properties
      graph.singleton_class.properties.keys.each do |property|
        graph.singleton_class.send(:register_property, property)
      end
      graph.insert RDF::Statement.new(subject, RDF.type, RDF.List)
      graph.reload
    end

    def []=(idx, value)
      raise IndexError "index #{idx} too small for array: minimum 0" if idx < 0

      if idx >= length
        (idx - length).times do
          self << RDF::OWL.Nothing
        end
        return self << value
      end
      each_subject.with_index do |v, i|
        next unless i == idx
        resource.set_value(v, RDF.first, value)
      end
    end

    ##
    # Override to return AF::Rdf::Resources as values, where
    # appropriate.
    def each(&block)
      return super unless block_given?

      super do |value|
        block.call(node_from_value(value))
      end
    end

    ##
    # Do these like #each.
    def first
      node_from_value(super)
    end

    def shift
      node_from_value(super)
    end

    ##
    # Find an AF::Rdf::Resource from the value returned by RDF::List
    def node_from_value(value)
      if value.kind_of? RDF::Resource
        type_uri = resource.query([value, RDF.type, nil]).to_a.first.try(:object)
        klass = ActiveFedora::Rdf::Resource.type_registry[type_uri]
        klass ||= Resource
        return klass.from_uri(value,resource)
      end
      value
    end

    ##
    # This class is the graph/Resource that backs the List and
    # supplies integration with the rest of ActiveFedora::Rdf
    class ListResource < Resource
      attr_reader :list

      def list=(list)
        @list ||= list
      end

      def attributes=(values)
        raise ArgumentError, "values must be a Hash, you provided #{values.class}" unless values.kind_of? Hash
        values.with_indifferent_access.each do |key, value|
          if self.singleton_class.properties.keys.map{ |k| "#{k}_attributes"}.include?(key)
            klass = properties[key[0..-12]]['class_name']
            klass = ActiveFedora.class_from_string(klass, final_parent.class) if klass.is_a? String
            value.is_a?(Hash) ? attributes_hash_to_list(values[key], klass) : attributes_to_list(value, klass)
          end
        end
        persist!
        super
      end

      private
        def attributes_to_list(value, klass)
          value.each do |entry|
            item = klass.new()
            item.attributes = entry
            list << item
          end
        end

        def attributes_hash_to_list(value, klass)
          value.each do |counter, attr|
            item = klass.new()
            item.attributes = attr if attr
            list[counter.to_i] = item
          end
        end
    end

    ##
    # Monkey patch to allow lists to have subject URIs.
    # Overrides RDF::List to prevent URI subjects
    # from being replaced with nodes.
    #
    # @NOTE Lists built this way will return false for #valid?
    def <<(value)
      value = case value
        when nil         then RDF.nil
        when RDF::Value  then value
        when Array       then RDF::List.new(nil, graph, value)
        else value
      end

      if empty?
        resource.set_value(RDF.first, value)
        resource.insert([subject, RDF.rest, RDF.nil])
        resource << value if value.kind_of? Resource
        return self
      end
      super
      resource << value if value.kind_of? Resource
    end
  end
end
