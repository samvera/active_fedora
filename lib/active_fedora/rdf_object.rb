module ActiveFedora
  module RdfObject
    extend ActiveSupport::Concern

    included do
      include RdfNode
    end

    def graph
      @graph ||= RDF::Graph.new
      insert_type_assertion
      @graph 
    end

    def initialize(graph=RDF::Graph.new, subject=nil)
      @graph = graph
      @subject = subject
    end

    def get_values(subject, predicate)
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      return TermProxy.new(@graph, @subject, predicate)
    end

    private
    
    def insert_type_assertion
      rdf_type = self.class.rdf_type
      @graph.insert([@subject, RDF.type, rdf_type]) if rdf_type
    end
  end
end
