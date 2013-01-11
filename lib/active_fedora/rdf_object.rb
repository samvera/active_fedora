module ActiveFedora
  module RdfObject
    extend ActiveSupport::Concern

    included do
      include RdfNode
      # class_attribute :config
      # self.config = {:predicate_mapping=>{}}
    end

    def graph
      @graph ||= RDF::Graph.new
      assert_type
      @graph 
    end

    def initialize(graph=RDF::Graph.new, subject=nil)
      @graph = graph
      @subject = subject
      #assert_type
    end

    def get_values(subject, predicate)
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      return TermProxy.new(@graph, @subject, predicate)
    end

    private
    
    def assert_type
      rdf_type = self.class.rdf_type
      @graph.insert([@subject, RDF.type, rdf_type]) if rdf_type
    end
  end
end
