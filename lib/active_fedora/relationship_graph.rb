module ActiveFedora
  class RelationshipGraph

    attr_accessor :relationships, :dirty


    def initialize 
      self.dirty = false
      self.relationships = Hash.new { |h, k| h[k] = [] }
    end

    def has_predicate?(predicate)
      relationships.has_key? predicate
    end
    
    def add(predicate, object, literal=false)
      unless relationships.has_key? predicate
        relationships[predicate] = []
      end
      object = RDF::Literal.new(object) if literal
      unless relationships[predicate].include?(object)
        @dirty = true
        relationships[predicate] << object
      end
    end

    # Remove the statement matching the predicate and object
    # [predicate] the predicate to delete
    # [object] the object to delete, if nil, all statements with this predicate are deleted.
    def delete(predicate, object = nil)
      return unless relationships.has_key? predicate
      if object.nil?
        @dirty = true
        relationships.delete(predicate)
        return
      end
      if relationships[predicate].include?(object)
        @dirty = true
        relationships[predicate].delete(object)
      end
      if object.respond_to?(:internal_uri) && relationships[predicate].include?(object.internal_uri)
        @dirty = true
        relationships[predicate].delete(object.internal_uri)
      elsif object.is_a? String 
        relationships[predicate].delete_if{|obj| obj.respond_to?(:internal_uri) && obj.internal_uri == object}
      end
    end

    def [](predicate)
      relationships[predicate]
    end
    
    def to_graph(subject_uri)
      # need to destroy relationships and rewrite it.
      subject =  RDF::URI.new(subject_uri)
      graph = RDF::Graph.new
      relationships.each do |predicate, values|
        values.each do |object|
          graph.insert build_statement(subject,  predicate, object)
        end
      end

      graph
    end

    # Create an RDF statement
    # @param uri a string represending the subject
    # @param predicate a predicate symbol
    # @param target an object to store
    def build_statement(uri, predicate, target)
      raise "Not allowed anymore" if uri == :self
      target = target.internal_uri if target.respond_to? :internal_uri
      subject =  RDF::URI.new(uri)  #TODO cache
      if target.is_a? RDF::Literal or target.is_a? RDF::Resource
        object = target
      else
        begin
          target_uri = (target.is_a? URI) ? target : URI.parse(target)
          if target_uri.scheme.nil?
            raise ArgumentError, "Invalid target \"#{target}\". Must have namespace."
          end
          if target_uri.to_s =~ /\A[\w\-]+:[\w\-]+\Z/
            raise ArgumentError, "Invalid target \"#{target}\". Target should be a complete URI, and not a pid."
          end
        rescue URI::InvalidURIError
          raise ArgumentError, "Invalid target \"#{target}\". Target must be specified as a literal, or be a valid URI."
        end
        object = RDF::URI.new(target)
      end
      predicate = ActiveFedora::Predicates.find_graph_predicate(predicate) unless predicate.kind_of? RDF::URI
      RDF::Statement.new(subject, predicate, object)
    
    end

  end
end
