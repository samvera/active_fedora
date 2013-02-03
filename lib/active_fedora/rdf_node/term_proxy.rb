module ActiveFedora
  module RdfNode
    class TermProxy

      attr_reader :graph, :subject, :predicate, :options

      delegate :class, :to_s, :==, :kind_of?, :each, :map, :empty?, :as_json, 
               :is_a?, :to_ary, :inspect, :first, :last, :include?, :count, 
               :size, :join, :to => :values

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
          values << v
        end
        if options[:class_name]
          values = values.map{ |found_subject| graph.target_class(predicate).new(graph.graph, found_subject)}
        end
        
        values
      end

    end
  end
end
