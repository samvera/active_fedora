module ActiveFedora
  module SemanticNode 
    extend ActiveSupport::Concern
    included do
      class_attribute :class_relationships_desc
    end
    attr_accessor :relationships_loaded
    attr_accessor :load_from_solr, :subject

    def assert_kind_of(n, o,t)
      raise "Assertion failure: #{n}: #{o} is not of type #{t}" unless o.kind_of?(t)
    end

    def clear_relationships
      @relationships_loaded = false
      @object_relations = nil
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
    # @param [Symbol, String] predicate
    # @param [URI, ActiveFedora::Base] target Either a string URI or an object that is a kind of ActiveFedora::Base 
    # TODO is target ever a AF::Base anymore?
    def add_relationship(predicate, target, literal=false)
      #raise ArgumentError, "predicate must be a symbol. You provided `#{predicate.inspect}'" unless predicate.class.in?([Symbol, String])
      object_relations.add(predicate, target, literal)
      rels_ext.content_will_change! if object_relations.dirty
    end

    # Clears all relationships with the specified predicate
    # @param predicate
    def clear_relationship(predicate)
      relationships(predicate).each do |target|
        object_relations.delete(predicate, target) 
      end
      rels_ext.content_will_change! if object_relations.dirty
    end

    # Checks that this object is matches the model class passed in.
    # It requires two steps to pass to return true
    #   1. It has a hasModel relationship of the same model
    #   2. kind_of? returns true for the model passed in
    # This method can most often be used to detect if an object from Fedora that was created
    # with a different model was then used to populate this object.
    # @param [Class] model_class the model class name to check if an object conforms_to that model
    # @return [Boolean] true if this object conforms to the given model name
    def conforms_to?(model_class)
      if self.kind_of?(model_class)
        #check has model and class match
        mod = relationships.first(:predicate=>Predicates.find_graph_predicate(:has_model))
        if mod
          expected = self.class.to_class_uri
          if mod.object.to_s == expected
            return true
          else
            raise "has_model relationship check failed for model #{model_class} raising exception, expected: '#{expected}' actual: '#{mod.object.to_s}'"
          end
        else
          raise "has_model relationship does not exist for model #{model_class} check raising exception"
        end
      else
        raise "kind_of? check failed for model #{model_class}, actual #{self.class} raising exception"
      end
      return false
    end

    #
    # Remove a Rels-Ext relationship from the Object.
    # @param predicate
    # @param obj Either a string URI or an object that responds to .pid 
    def remove_relationship(predicate, obj, literal=false)
      object_relations.delete(predicate, obj)
      self.relationships_are_dirty = true
      rels_ext.content_will_change!
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
      rels.map {|o| o.respond_to?(:internal_uri) ? o.internal_uri : o }.compact   #TODO, could just return the object
    end

    def load_relationships
      @relationships_loaded = true
      content = rels_ext.content
      return unless content.present?
      RelsExtDatastream.from_xml content, rels_ext
    end

    def ids_for_outbound(predicate)
      (object_relations[predicate] || []).map do |o|
        o = o.to_s if o.kind_of? RDF::Literal
        o.kind_of?(String) ? self.class.pid_from_uri(o) : o.pid
      end
    end

    # Return hash that persists relationship metadata defined by has_relationship calls
    # @return [Hash] Hash of relationship subject (:self or :inbound) mapped to nested hashs of each relationship name mapped to another hash relationship options 
    # @example For the following relationship
    #
    #  has_relationship "audio_records", :has_part, :type=>AudioRecord
    #  
    #  Results in the following returned by relationships_desc
    #  {:self=>{"audio_records"=>{:type=>AudioRecord, :singular=>nil, :predicate=>:has_part, :inbound=>false}}}
    def relationships_desc
      @relationships_desc ||= self.class.relationships_desc
    end

    # Return hash of relationship names and predicate pairs (inbound and outbound).
    # It retrieves this information via the relationships_desc hash in the class.
    # @return [Hash] A hash of relationship names (inbound and outbound) mapped to predicates used
    def relationship_predicates
      return @relationship_predicates if @relationship_predicates
      @relationship_predicates = {}
      relationships_desc.each_pair do |subj, names|
        @relationship_predicates[subj] = {}
        names.each_pair do |name, args|
          @relationship_predicates[subj][name] = args[:predicate]
        end
      end
      @relationship_predicates
    end

    # Return hash of outbound relationship names and predicate pairs
    # @return [Hash] A hash of outbound relationship names mapped to predicates used
    def outbound_relationship_predicates
      relationship_predicates.has_key?(:self) ? relationship_predicates[:self] : {}
    end

    # Return hash of inbound relationship names and predicate pairs
    # @return [Hash] A hash of inbound relationship names mapped to predicates used
    def inbound_relationship_predicates
      relationship_predicates.has_key?(:inbound) ? relationship_predicates[:inbound] : {}
    end


    module ClassMethods

      # @param [String] uri a uri (as a string)
      # @returns [String] the pid component of the URI
      def pid_from_uri(uri)
        uri.gsub("info:fedora/", "")
      end

      # Return hash that persists relationship metadata defined by has_relationship calls.  If you implement a child class of ActiveFedora::Base it will inherit
      # the relationship descriptions defined there by merging in the class
      # instance variable values.  It will also do this for any level of 
      # ancestors.
      # @return [Hash] Hash of relationship subject (:self or :inbound) mapped to nested hashs of each relationship name mapped to another hash relationship options
      # @example
      #  For the following relationship
      #
      #  has_relationship "audio_records", :has_part, :type=>AudioRecord
      #  
      #  Results in the following returned by relationships_desc
      #  {:self=>{"audio_records"=>{:type=>AudioRecord, :singular=>nil, :predicate=>:has_part, :inbound=>false}}}
      def relationships_desc
        #get any relationship descriptions from superclasses
        if @class_relationships_desc.nil?
          @class_relationships_desc ||= Hash[:self => {}]

          #get super classes
          super_klasses = []
          #insert in reverse order so the child overwrites anything in parent
          super_klass = self.superclass
          while !super_klass.nil?
            super_klasses.insert(0,super_klass)
            super_klass = super_klass.superclass
          end
        
          super_klasses.each do |super_klass|
            if super_klass.respond_to?(:relationships_desc)
              super_rels = super_klass.relationships_desc
              super_rels.each_pair do |subject,rels|
                @class_relationships_desc[subject] = {} unless @class_relationships_desc.has_key?(subject)
                @class_relationships_desc[subject].merge!(rels)
              end
            end
          end
        end
        @class_relationships_desc
      end
    
    end
  end
end
