require 'rdf'
module ActiveFedora
  module SemanticNode 
    extend ActiveSupport::Concern
    included do
      class_attribute  :class_relationships, :internal_uri
      self.class_relationships = {}
    end
    attr_accessor :relationships_loaded, :load_from_solr, :subject

    def assert_kind_of(n, o,t)
      raise "Assertion failure: #{n}: #{o} is not of type #{t}" unless o.kind_of?(t)
    end

    def object_relations
      load_relationships if !relationships_loaded
      @object_relations ||= RelationshipGraph.new
    end
    
    def relationships_are_dirty
      object_relations.dirty
    end
    def relationships_are_dirty=(val)
      object_relations.dirty = val
    end

    # Add a relationship to the Object.
    # @param predicate
    # @param object Either a string URI or an object that is a kind of ActiveFedora::Base 
    def add_relationship(predicate, target, literal=false)
      object_relations.add(predicate, target, literal)
      rels_ext.dirty = true
    end

    # Create an RDF statement
    # @param uri a string represending the subject
    # @param predicate a predicate symbol
    # @param target an object to store
    def build_statement(uri, predicate, target, literal=false)
      ActiveSupport::Deprecation.warn("ActiveFedora::Base#build_statement has been deprecated.")
      raise "Not allowed anymore" if uri == :self
      target = target.internal_uri if target.respond_to? :internal_uri
      subject =  RDF::URI.new(uri)  #TODO cache
      unless literal or target.is_a? RDF::Resource
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
      end
      if literal
        object = RDF::Literal.new(target)
      elsif target.is_a? RDF::Resource
        object = target
      else
        object = RDF::URI.new(target)
      end
      RDF::Statement.new(subject, find_graph_predicate(predicate), object)
    
    end
                  
    

    #
    # Remove a Rels-Ext relationship from the Object.
    # @param predicate
    # @param object Either a string URI or an object that responds to .pid 
    def remove_relationship(predicate, obj, literal=false)
      object_relations.delete(predicate, obj)
      self.relationships_are_dirty = true
      rels_ext.dirty = true
    end

    def inbound_relationships(response_format=:uri)
      rel_values = {}
      inbound_relationship_predicates.each_pair do |name,predicate|
        objects = self.send("#{name}",{:response_format=>response_format})
        items = []
        objects.each do |object|
          if (response_format == :uri)    
            #inbound relationships are always object properties
            items.push(object.internal_uri)
          else
            items.push(object)
          end
        end
        unless items.empty?
          rel_values.merge!({predicate=>items})
        end
      end
      return rel_values  
    end
    
    def outbound_relationships()
      relationships.statements
    end
    
    # If no arguments are supplied, return the whole RDF::Graph.
    # if a predicate is supplied as a parameter, then it returns the result of quering the graph with that predicate
    def relationships(*args)
      load_relationships if !relationships_loaded

      if args.empty?
        raise "Must have internal_uri" unless internal_uri
        return object_relations.to_graph(internal_uri)
      end
      rels = object_relations[args.first] || []
      rels.map {|o| o.respond_to?(:internal_uri) ? o.internal_uri : o }   #TODO, could just return the object
    end

    def load_relationships
      self.relationships_loaded = true
      content = rels_ext.content
      return unless content.present?
      RelsExtDatastream.from_xml content, rels_ext
    end

    def ids_for_outbound(predicate)
      (object_relations[predicate] || []).map do |o|
        o = o.to_s if o.kind_of? RDF::Literal
        o.kind_of?(String) ? o.gsub("info:fedora/", "") : o.pid
      end
    end
    
  end


end
