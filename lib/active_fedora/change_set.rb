module ActiveFedora
  # a Hash of properties that have changed and their present values
  class ChangeSet
    attr_reader :object, :graph, :changed_attributes

    # @param [ActiveFedora::Base] object The resource that has associations and properties
    # @param [RDF::Graph] graph The RDF graph that holds the current state
    # @param [Array] changed_attributes A list of properties that have changed
    def initialize(object, graph, changed_attributes)
      @object = object
      @graph = graph
      @changed_attributes = changed_attributes
    end

    delegate :empty?, to: :changes

    # @return [Hash<RDF::URI, RDF::Queryable::Enumerator>] hash of predicate uris to statements
    def changes
      @changes ||= changed_attributes.each_with_object({}) do |key, result|
        if object.association(key.to_sym).present?
          # This is always an ActiveFedora::Reflection::RDFPropertyReflection
          predicate = object.association(key.to_sym).reflection.predicate
          result[predicate] = graph.query(subject: object.rdf_subject, predicate: predicate)
        elsif object.class.properties.keys.include?(key)
          predicate = graph.reflections.reflect_on_property(key).predicate
          results = graph.query(subject: object.rdf_subject, predicate: predicate)
          new_graph = child_graphs(results.map(&:object))
          results.each do |res|
            new_graph << res
          end
          result[predicate] = new_graph
        elsif key == 'type'.freeze
          # working around https://github.com/ActiveTriples/ActiveTriples/issues/122
          predicate = ::RDF.type
          result[predicate] = graph.query(subject: object.rdf_subject, predicate: predicate).select do |statement|
            !statement.object.to_s.start_with?("http://fedora.info/definitions/v4/repository#", "http://www.w3.org/ns/ldp#")
          end
        elsif object.local_attributes.include?(key)
          raise "Unable to find a graph predicate corresponding to the attribute: \"#{key}\""
        end
      end
    end

    private

      # @return [RDF::Graph] A graph containing child graphs from changed
      #   attributes.
      def child_graphs(objects)
        child_graphs = ::RDF::Graph.new
        objects.each do |object|
          graph.query(subject: object).each do |statement|
            # Have to filter out Fedora triples.
            unless FedoraStatement.new(statement).internal?
              child_graphs << statement
            end
          end
        end
        child_graphs
      end
  end

  class FedoraStatement
    attr_reader :value
    def initialize(value)
      @value = value
    end

    def internal?
      value.object.to_s.start_with?("http://www.jcp.org", "http://fedora.info") ||
        value.predicate.to_s.start_with?("http://fedora.info")
    end
  end
end
