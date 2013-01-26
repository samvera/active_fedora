module ActiveFedora
  module RdfList
    attr_reader :graph, :subject
    def initialize(graph, subject)
      @graph = graph
      @subject = subject
    end
    def first
      self[0] 
    end

    def [](idx)
      idx == 0 ?  head.value : tail[idx-1]
    end

    def size
      tail ?  tail.size + 1 : 0
    end

    def value
      v = graph.query([subject, RDF.first, nil]).first
      return v.object if v.object.uri?
      if v.object.resource?
        type = graph.query([v.object, RDF.type, nil]).first
        return ActiveFedora::RdfNode.rdf_registry[type.object].new(graph, v.object)
      end
      v
    end

    def head
      @head ||= self.class.new(graph, subject)
    end

    def tail
      rest = graph.query([subject, RDF.rest, nil]).first
      return unless rest
      self.class.new(graph, rest.object)
    end
  end
end
