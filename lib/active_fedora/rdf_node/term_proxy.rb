module ActiveFedora
  module RdfNode
    class TermProxy

      attr_reader :graph, :subject, :predicate, :options

      delegate :class, :to_s, :==, :kind_of?, :each, :each_with_index, :map,
               :empty?, :as_json, :is_a?, :to_ary, :to_a, :inspect, :first,
               :last, :include?, :count, :size, :join, :[], :to => :values

      # @param graph RDF::Graph
      # @param subject RDF::URI
      # @param options Hash
      def initialize(graph, subject, predicate, options)
        @graph = graph
        @subject = subject
        @predicate = predicate
        @options = options
      end

      def build
        new_subject = RDF::Node.new
        graph.graph.insert([subject, predicate, new_subject])
        graph.target_class(predicate).new(graph.graph, new_subject)
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
            klass =  class_from_rdf_type(v, predicate)
            values << v if klass == ActiveFedora.class_from_string(options[:class_name], graph.class)
          else
            values << v
          end
        end

        if options[:class_name]
          values = values.map{ |found_subject| class_from_rdf_type(found_subject, predicate).new(graph.graph, found_subject)}
        end
        
        values
      end
      
      private 

      # Look for a RDF.type assertion on this node to see if an RDF class is specified.
      # Two classes may be valid for the same predicate (e.g. hasMember)
      # If no RDF.type assertion is found, fall back to using target_class
      def class_from_rdf_type(subject, predicate)
        q = RDF::Query.new do
          pattern [subject, RDF.type, :value]
        end

        type_uri = []
        q.execute(graph.graph).each do |sol| 
          type_uri << sol.value
        end
        
        klass = ActiveFedora::RdfNode.rdf_registry[type_uri.first]
        klass ||= graph.target_class(predicate)
        klass
      end

    end
  end
end
