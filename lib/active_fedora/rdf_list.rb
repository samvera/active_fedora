module ActiveFedora
  module RdfList
    attr_reader :graph, :subject
    def initialize(graph, subject)
      @graph = graph
      @subject = subject
      first = graph.query([subject, RDF.first, nil]).first
      graph.insert([subject, RDF.first, RDF.nil]) unless first
      graph.insert([subject, RDF.rest, RDF.nil])
    end

    def rdf_subject
      subject
    end

    def first
      self[0] 
    end

    def [](idx)
      idx == 0 ?  head.value : tail[idx-1]
    end

    def []=(idx, value)
      idx == 0 ?  head.value=value : tail_or_create(idx-1).value=value
    end

    def size
      if tail
        tail.size + 1
      elsif graph.query([subject, RDF.first, RDF.nil]).first
        0
      else
        1
      end
    end

    def inspect
      "[ #{value ? value.inspect : 'nil'}, #{tail.inspect}]"
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

    def value=(obj)
      graph.delete([subject, RDF.first, RDF.nil])
      if obj.respond_to? :rdf_subject
        graph.insert([subject, RDF.first, obj.rdf_subject]) # an ActiveFedora::RdfObject
      else
        graph.insert([subject, RDF.first, obj])
      end
    end

    def head
      @head ||= self.class.new(graph, subject)
    end

    def tail
      rest = graph.query([subject, RDF.rest, nil]).first
      return if rest.object == RDF.nil
      self.class.new(graph, rest.object)
    end

    def tail_or_create(idx)
      rest = graph.query([subject, RDF.rest, nil]).first
      obj = if rest.object != RDF.nil 
        self.class.new(graph, rest.object)
      else
        #add a tail
        graph.delete([subject, RDF.rest, RDF.nil])
        tail = RDF::Node.new
        graph.insert([subject, RDF.rest, tail])
        self.class.new(graph, tail)
      end

      idx == 0 ? obj : obj.tail_or_create(idx-1)
    end
  end
end
