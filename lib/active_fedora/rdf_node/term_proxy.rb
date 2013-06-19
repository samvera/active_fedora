module ActiveFedora
  module RdfNode
    class TermProxy

      attr_reader :graph, :subject, :predicate, :options

      delegate *(Array.public_instance_methods - [:__send__, :__id__, :class, :object_id] + [:as_json]), :to => :values

      # @param graph RDF::Graph
      # @param subject RDF::URI
      # @param options Hash
      def initialize(graph, subject, predicate, options)
        @graph = graph
        @subject = subject
        @predicate = predicate
        @options = options
      end

      def build(attributes=nil)
        new_subject = RDF::Node.new
        graph.graph.insert([subject, predicate, new_subject])
        graph.target_class(predicate).new(graph.graph, new_subject).tap do |node|
          node.attributes = attributes if attributes
        end
      end

      def <<(*values)
        values.each { |value| graph.append(subject, predicate, value) }
        values
      end

      def delete(*values)
        values.each do |value| 
          graph.delete_predicate(subject, predicate, value)
        end

        values
      end

      def values
        values = []

        graph.query(subject, predicate).each do |solution|
          v = solution.value
          v = v.to_s if v.is_a? RDF::Literal
          if options[:type] == :date
            v = Date.parse(v)
          end
          # If the user provided options[:class_name], we should query to make sure this 
          # potential solution is of the right RDF.type
          if options[:class_name]
            klass =  class_from_rdf_type(v)
            values << v if klass == ActiveFedora.class_from_string(options[:class_name], graph.class)
          else
            values << v
          end
        end

        if options[:class_name]
          values = values.map{ |found_subject| class_from_rdf_type(found_subject).new(graph.graph, found_subject)}
        end
        
        values
      end
      
      private 

      def target_class
        graph.target_class(predicate)
      end

      # Look for a RDF.type assertion on this node to see if an RDF class is specified.
      # Two classes may be valid for the same predicate (e.g. hasMember)
      # If no RDF.type assertion is found, fall back to using target_class
      def class_from_rdf_type(subject)
        q = RDF::Query.new do
          pattern [subject, RDF.type, :value]
        end

        type_uri = []
        q.execute(graph.graph).each do |sol| 
          type_uri << sol.value
        end
        
        klass = ActiveFedora::RdfNode.rdf_registry[type_uri.first]
        klass ||= target_class
        klass
      end

    end
  end
end
