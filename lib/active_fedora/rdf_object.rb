module ActiveFedora
  module RdfObject
    extend ActiveSupport::Concern

    included do
      include RdfNode
      attr_reader :rdf_subject, :graph
    end

    def graph
      @graph ||= RDF::Graph.new
      @graph 
    end


    def initialize(graph, subject=nil)
      subject ||= RDF::Node.new
      @graph = graph
      @rdf_subject = subject
      insert_type_assertion
    end

    private
    
    def insert_type_assertion
      rdf_type = self.class.rdf_type
      @graph.insert([@rdf_subject, RDF.type, rdf_type]) if rdf_type
    end
  end
end
