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
    end

    module ClassMethods
      # TODO merge this with RDFDatastream.config
      def config
        @config ||= {}
      end
    end

    def initialize(graph=RDF::Graph.new, subject=nil)
      @graph = graph
      @subject = subject

    end

    def get_values(subject, predicate)
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      return TermProxy.new(@graph, @subject, predicate)
    end
  end
end
