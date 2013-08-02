module ActiveFedora
  module RdfList
    extend ActiveSupport::Concern
    include ActiveFedora::RdfNode
    
    attr_reader :graph, :subject
    
    # RdfList is a node of a linked list structure.
    # The RDF.first predicate points to the contained object
    # The RDF.rest predicate points to the next node in the list or 
    #   RDF.nil if this is the final node.
    # @see http://www.w3.org/TR/rdf-schema/#ch_list
    def initialize(graph, subject)
      @graph = graph
      @subject = subject
      first = graph.query([subject, RDF.first, nil]).first
      last = graph.query([subject, RDF.rest, nil]).first
      graph.insert([subject, RDF.first, RDF.nil]) unless first
      graph.insert([subject, RDF.rest, RDF.nil]) unless last
    end

    UNASSIGNABLE_KEYS = %w(_destroy )

    # Override assign_nested_attributes
    def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
      options = self.nested_attributes_options[association_name]
    
      # TODO
      #check_record_limit!(options[:limit], attributes_collection)
    
      if attributes_collection.is_a?(Hash)
        attributes_collection = attributes_collection.values
      end
    
      association = self.send(association_name)
      
      original_length_of_list = self.size
      attributes_collection.each_with_index do |attributes, index|
        attributes = attributes.with_indifferent_access
        minted_node = association.mint_node(attributes.except(*UNASSIGNABLE_KEYS))
        self[original_length_of_list+index] = minted_node
      end
    end


    # Override the method from RdfNode, enabling us to insert into the list.
    def insert_child(predicate, node)
      self[size] = node
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

    def clear(first_element=true)
      # Remove the pointed at element
      v = graph.query([subject, RDF.first, nil]).first
      # TODO - Recursive delete
      graph.delete([v.object, nil, nil])
      
      # Remove the tail
      tail.clear(false) if tail
      # clear the cache
      @tail = nil
      graph.delete([subject, nil, nil])
      if first_element
        # Re-add first/rest predicates if its the first node
        graph.insert([subject, RDF.first, RDF.nil])
        graph.insert([subject, RDF.rest, RDF.nil])
      end
    end

    def each &block
      yield(head.value)
      tail.each(&block) if tail
    end

    def to_ary
      if empty?
        []
      elsif tail
        [head.value] + tail.to_ary
      else
        [head.value]
      end
    end

    def empty?
      !tail && graph.query([subject, RDF.first, RDF.nil]).first
    end 

    def size
      if empty?
        0
      elsif tail
        tail.size + 1
      else
        1
      end
    end

    def inspect
      "[ #{value ? value.inspect : 'nil'}, #{tail.inspect}]"
    end

    def value
      v = graph.query([subject, RDF.first, nil]).first
      if v.object.uri?
        return v.object == RDF.nil ? nil : v.object
      end
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
      return @tail if @tail
      rest = graph.query([subject, RDF.rest, nil]).first
      return if rest.object == RDF.nil
      @tail = self.class.new(graph, rest.object)
    end

    def tail_or_create(idx)
      unless tail
        #add a tail
        graph.delete([subject, RDF.rest, RDF.nil])
        tail_node = RDF::Node.new
        graph.insert([subject, RDF.rest, tail_node])
        @tail = self.class.new(graph, tail_node)
      end

      idx == 0 ? @tail : @tail.tail_or_create(idx-1)
    end
  end
end
