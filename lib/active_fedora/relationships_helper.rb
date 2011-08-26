module ActiveFedora
  # This module is meant to extend semantic node to add functionality based on a relationship's name
  # It is meant to turn a relationship into just another attribute in a model.
  # The notion of a "relationship name" is used _internally_ to distinguish between the relationships you've set up using has_relationship and the implicit relationships that are based on the predicates themselves.
  #
  # @example
  #
  # has_relationship "parents" :is_member_of
  #
  # obj.parents is a relationship in ActiveFedora while :is_member_of is the literal RDF relationship in Fedora
  #
  # There are also several helper methods created for any relationship declared in ActiveFedora.  For the above example
  # the following methods are created:
  #
  # obj.parents_append(object)  Appends an object to the "parents" relationship
  # obj.parents_remove(object)  Removes an object from the "parents" relationship
  # obj.parents_query           Returns the query used against solr to retrieve objects linked via the "parents" relationship
  #
  # Note: ActiveFedora relationships can reflect filters ...
  module RelationshipsHelper
    attr_accessor :relationships_desc

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    

    # ** EXPERIMENTAL **
    # 
    # Return array of objects for a given relationship name
    # @param [String] Name of relationship to find
    # @return [Array] Returns array of objects linked via the relationship name given
    def find_relationship_by_name(name)
      rels = nil
      if inbound_relationship_names.include?(name)
        rels = relationships_by_name(false)[:inbound][name]
      elsif outbound_relationship_names.include?(name)
        rels = relationships_by_name[:self][name]
      end
      rels = [] if rels.nil?
      return rels
    end

     # ** EXPERIMENTAL **
    # 
    # Internal method that ensures a relationship subject such as :self and :inbound
    # exist within the relationships_desc hash tracking relationships metadata. 
    # This method just calls the class method counterpart of this method.
    # @param [Symbol] Subject name to register (will probably be something like :self or :inbound)
    def register_relationship_desc_subject(subject)
      self.class.register_relationship_desc_subject(subject)
    end
  
    # ** EXPERIMENTAL **
    # 
    # Internal method that adds a relationship description for a
    # relationship name and predicate pair to either an outbound (:self)
    # or inbound (:inbound) relationship types.  This method just calls the class method counterpart of this method.
    # @param [Symbol] Subject name to register
    # @param [String] Name of relationship being registered
    # @param [Symbol] Fedora ontology predicate to use
    # @param [Hash] Any options passed to has_relationship such as :type, :query_params, etc.
    def register_relationship_desc(subject, name, predicate, opts={})
      self.class.register_relationship_desc(subject, name, predicate, opts)
    end

    # ** EXPERIMENTAL **
    # 
    # Gets the relationships hash with subject mapped to relationship
    # names instead of relationship predicates (unlike the "relationships" method in SemanticNode)
    # It has an optional parameter of outbound_only that defaults true.
    # If false it will include inbound relationships in the results.
    # Also, it will only reload outbound relationships if the relationships hash has changed
    # since the last time this method was called.
    # @param [Boolean] if false it will include inbound relationships (defaults to true)
    # @return [Hash] Returns a hash of subject name (:self or :inbound) mapped to nested hashs of each relationship name mapped to an Array of objects linked via the relationship
    def relationships_by_name(outbound_only=true)
      #make sure to update if relationships have been updated
      if @relationships_are_dirty == true
        @relationships_by_name = relationships_by_name_from_class()
        @relationships_are_dirty = false
      end
      
      #this will get called normally on first fetch if relationships are not dirty
      @relationships_by_name ||= relationships_by_name_from_class()
      outbound_only ? @relationships_by_name : @relationships_by_name.merge(:inbound=>inbound_relationships_by_name)      
    end

    # ** EXPERIMENTAL **
    # 
    # Gets relationships by name from the class using the current relationships hash
    # and relationship name,predicate pairs.
    # @return [Hash] returns the outbound relationships with :self mapped to nested hashs of each relationship name mapped to an Array of objects linked via the relationship
    def relationships_by_name_from_class()
      rels = {}
      relationship_predicates.each_pair do |subj, names|
        if relationships.has_key?(subj)
          rels[subj] = {}
          names.each_pair do |name, predicate|
            rels[subj][name] = (relationships[subj].has_key?(predicate) ? relationships[subj][predicate] : [])
          end
        end
      end
      return rels
    end

        
    # ** EXPERIMENTAL **
    # 
    # Return hash of relationships_by_name defined within other objects' RELS-EXT
    # It returns a hash of relationship name to arrays of objects.  It requeries
    # solr each time this method is called.
    # @return [Hash] Return hash of each relationship name mapped to an Array of objects linked to this object via inbound relationships
    def inbound_relationships_by_name
      rels = {}
      if relationships_desc.has_key?(:inbound)&&!relationships_desc[:inbound].empty?()
        inbound_rels = inbound_relationships
      
        if relationship_predicates.has_key?(:inbound)
          relationship_predicates[:inbound].each do |name, predicate|
            rels[name] = inbound_rels.has_key?(predicate) ? inbound_rels[predicate] : []
          end
        end
      end
      return rels
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of outbound relationship names and predicate pairs
    # @return [Hash] A hash of outbound relationship names mapped to predicates used
    def outbound_relationship_predicates
      relationship_predicates.has_key?(:self) ? relationship_predicates[:self] : {}
    end

    # ** EXPERIMENTAL **
    # 
    # Return hash of inbound relationship names and predicate pairs
    # @return [Hash] A hash of inbound relationship names mapped to predicates used
    def inbound_relationship_predicates
      relationship_predicates.has_key?(:inbound) ? relationship_predicates[:inbound] : {}
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of relationship names and predicate pairs (inbound and outbound).
    # This method calls the class method version of this method to get the static settings
    # defined in the class definition.
    # @return [Hash] A hash of relationship names (inbound and outbound) mapped to predicates used
    def relationship_predicates
      @relationship_predicates ||= relationship_predicates_from_class
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of relationship names and predicate pairs from class.
    # It retrieves this information via the relationships_desc hash in the class.
    # @return [Hash] A hash of relationship names (inbound and outbound) mapped to predicates used
    def relationship_predicates_from_class
      rels = {}
      relationships_desc.each_pair do |subj, names|
        rels[subj] = {}
        names.each_pair do |name, args|
          rels[subj][name] = args[:predicate]
        end
      end
      return rels
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return array all relationship names
    # @return [Array] of relationship names for relationships declared via has_relationship in the class
    def relationship_names
      names = []
      relationships_desc.each_key do |subject|
            names = names.concat(relationships_desc[subject].keys)
        end
        names
    end

    # ** EXPERIMENTAL **
    # 
    # Return array of relationship names for all inbound relationships (coming from other objects' RELS-EXT and Solr)
    # @return [Array] of inbound relationship names for relationships declared via has_relationship in the class
    def inbound_relationship_names
        relationships_desc.has_key?(:inbound) ? relationships_desc[:inbound].keys : []
    end

    # ** EXPERIMENTAL **
    # 
    # Return array of relationship names for all outbound relationships (coming from this object's RELS-EXT)
    # @return [Array] of outbound relationship names for relationships declared via has_relationship in the class
    def outbound_relationship_names
        relationships_desc.has_key?(:self) ? relationships_desc[:self].keys : []
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of relationships_by_name defined within this object's RELS-EXT
    # It returns a hash of relationship name to arrays of objects
    # @return [Hash] Return hash of each relationship name mapped to an Array of objects linked to this object via outbound relationships
    def outbound_relationships_by_name
        relationships_desc.has_key?(:self) ? relationships_by_name[:self] : {}
    end
  
    # ** EXPERIMENTAL **
    # 
    # Returns true if the given relationship name is a relationship
    # @param [String] Name of relationship
    # @param [Boolean] If false checks inbound relationships as well (defaults to true)
    def is_relationship_name?(name, outbound_only=true)
      if outbound_only
        outbound_relationship_names.include?(name)
      else
        (outbound_relationship_names.include?(name)||inbound_relationship_names.include?(name))
      end
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash that persists relationship metadata defined by has_relationship calls
    # @return [Hash] Hash of relationship subject (:self or :inbound) mapped to nested hashs of each relationship name mapped to another hash relationship options 
    # @example For the following relationship
    #
    #  has_relationship "audio_records", :has_part, :type=>AudioRecord
    #  
    #  Results in the following returned by relationships_desc
    #  {:self=>{"audio_records"=>{:type=>AudioRecord, :singular=>nil, :predicate=>:has_part, :inbound=>false}}}
    def relationships_desc
      @relationships_desc ||= relationships_desc_from_class
    end
    
    # ** EXPERIMENTAL **
    # 
    # Get class instance variable relationships_desc that holds has_relationship metadata
    # @return [Hash] Hash of relationship subject (:self or :inbound) mapped to nested hashs of each relationship name mapped to another hash relationship options 
    def relationships_desc_from_class
      self.class.relationships_desc
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return the value of :type for the relationship for name passed in if defined
    # It defaults to ActiveFedora::Base.
    # @return [Class] the name of the class defined for a relationship by the :type option if present
    def relationship_model_type(name)
      if is_relationship_name?(name,true)
        subject = outbound_relationship_names.include?(name)? :self : :inbound
        if relationships_desc[subject][name].has_key?(:type)
          return class_from_name(relationships_desc[subject][name][:type])
        end
      end
      return nil  
    end

    # ** EXPERIMENTAL **
    # 
    # Add an outbound relationship for given relationship name
    # See ActiveFedora::SemanticNode::ClassMethods.has_relationship
    # @param [String] Name of relationship
    # @param [ActiveFedora::Base] object to add to the relationship (expects ActvieFedora::Base to be an ancestor)
    # @return [Boolean] returns true if add operation successful
    def add_relationship_by_name(name, object)
      if is_relationship_name?(name,true)
        if relationships_desc[:self][name].has_key?(:type)
          klass = class_from_name(relationships_desc[:self][name][:type])
          unless klass.nil?
            (assert_conforms_to 'object', object, klass)
          end
        end
        #r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>outbound_relationship_predicates[name],:object=>object})
        #add_relationship(r)
        add_relationship(outbound_relationship_predicates[name],object)
      else
        false
      end
    end
    
    # ** EXPERIMENTAL **
    # 
    # Remove an object for the given relationship name
    # @param [String] Relationship name
    # @param [ActiveFedora::Base] object to remove
    # @return [Boolean] return true if remove operation successful
    def remove_relationship_by_name(name, object)
      if is_relationship_name?(name,true)
        remove_relationship(outbound_relationship_predicates[name],object)
      else
        return false
      end
    end

    # ** EXPERIMENTAL **
    # 
    # Throws an assertion error if conforms_to? returns false for object and model_class
    # @param [String] Name of object (just label for output)
    # @param [ActiveFedora::Base] Expects to be an object that has ActiveFedora::Base as an ancestor of its class
    # @param [Class] The model class used in conforms_to? check on object
    def assert_conforms_to(name, object, model_class)
      raise "Assertion failure: #{name}: #{object.pid} does not have model #{model_class}, it has model #{relationships[:self][:has_model]}" unless object.conforms_to?(model_class)
    end
    
    # ** EXPERIMENTAL **
    # 
    # Checks that this object is matches the model class passed in.
    # It requires two steps to pass to return true
    #   1. It has a hasModel relationship of the same model
    #   2. kind_of? returns true for the model passed in
    # This method can most often be used to detect if an object from Fedora that was created
    # with a different model was then used to populate this object.
    # @param [Class] the model class name to check if an object conforms_to that model
    # @return [Boolean] true if this object conforms to the given model name
    def conforms_to?(model_class)
      if self.kind_of?(model_class)
        #check has model and class match
        if relationships[:self].has_key?(:has_model)
          r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_model, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(self.class))
          if relationships[:self][:has_model].first.to_s.eql?(r.object.to_s)
            return true
          else
            raise "has_model relationship check failed for model #{model_class} raising exception, expected: '#{r.object.to_s}' actual: '#{relationships[:self][:has_model].to_s}'"
          end
        else
          raise "has_model relationship does not exist for model #{model_class} check raising exception"
        end
      else
        raise "kind_of? check failed for model #{model_class}, actual #{self.class} raising exception"
      end
      return false
    end

    # Returns a Class symbol for the given string for the class name
    # @param [String] the class name as a string
    # @return [Class] the class as a Class object
    def class_from_name(name)
      klass = name.to_s.split('::').inject(Kernel) {|scope, const_name| 
      scope.const_get(const_name)}
      (!klass.nil? && klass.is_a?(::Class)) ? klass : nil
    end

    # Call this method to return the query used against solr to retrieve any
    # objects linked via the relationship name given.
    #
    # Instead of this method you can also use the helper method
    # [relationship_name]_query, i.e. method "parts_query" for relationship "parts" to return the same value
    # @param [String] The name of the relationship defined in the model
    # @return [String] The query used when querying solr for objects for this relationship
    # @example
    #   Class SampleAFObjRelationshipQueryParam < ActiveFedora::Base
    #     #points to all parents linked via is_member_of
    #     has_relationship "parents", :is_member_of
    #     #returns only parents that have a level value set to "series"
    #     has_relationship "series_parents", :is_member_of, :query_params=>{:q=>{"level_t"=>"series"}}
    #   end
    #   s = SampleAFObjRelationshipQueryParam.new
    #   obj = ActiveFedora::Base.new
    #   s.parents_append(obj)
    #   s.series_parents_query 
    #   #=> "(id:changeme\\:13020 AND level_t:series)" 
    #   SampleAFObjRelationshipQueryParam.relationship_query("series_parents")
    #   #=> "(id:changeme\\:13020 AND level_t:series)" 
    def relationship_query(relationship_name)
      query = ""
      if self.class.is_bidirectional_relationship?(relationship_name)
        id_array = []
        predicate = outbound_relationship_predicates["#{relationship_name}_outbound"]
        if !outbound_relationships[predicate].nil? 
          outbound_relationships[predicate].each do |rel|
            id_array << rel.gsub("info:fedora/", "")
          end
        end
        query = self.class.bidirectional_relationship_query(pid,relationship_name,id_array)
      elsif outbound_relationship_names.include?(relationship_name)
        id_array = []
        predicate = outbound_relationship_predicates[relationship_name]
        if !outbound_relationships[predicate].nil? 
          outbound_relationships[predicate].each do |rel|
            id_array << rel.gsub("info:fedora/", "")
          end
        end
        query = self.class.outbound_relationship_query(relationship_name,id_array)
      elsif inbound_relationship_names.include?(relationship_name)
        query = self.class.inbound_relationship_query(pid,relationship_name)
      end
      query
    end

  ## Deprecated method checks for HYDRA-541 methods renamed
  #
  # Old Name                                                      New Name
  # named_relationship                                            find_relationship_by_name
  # register_named_subject                                        register_relationship_desc_subject
  # register_named_relationship                                   register_relationship_desc
  # named_relationships                                           relationships_by_name
  # named_relationships_from_class                                relationships_by_name_from_class
  # named_inbound_relationships                                   inbound_relationship_names
  # outbound_named_relationship_predicates                        outbound_relationship_predicates
  # inbound_named_relationship_predicates                         inbound_relationship_predicates
  # named_relationship_predicates                                 relationship_predicates
  # named_relationship_predicates_from_class                      relationship_predicates_from_class
  # named_outbound_relationships                                  outbound_relationships_by_name
  # is_named_relationship?                                        is_relationship_name?
  # named_relationships_desc                                      relationships_desc
  # named_relationships_desc_from_class                           relationships_desc_from_class
  # named_relationship_type                                       relationship_model_type
  # add_named_relationship                                        add_relationship_by_name
  # remove_named_relationship                                     remove_relationship_by_name
  # assert_kind_of_model                                          assert_conforms_to
  # kind_of_model?                                                conforms_to?
  # named_relationship_query                                      relationship_query
  # CLASS METHODS                         
  # named_relationships_desc                                      relationships_desc
  # register_named_subject                                        register_relationship_desc_subject
  # register_named_relationship                                   register_relationship_desc
  # create_named_relationship_method                              create_relationship_name_methods
  # create_bidirectional_named_relationship_methods               create_bidirectional_relationship_name_methods
  # outbound_named_relationship_query                             outbound_relationship_query
  # inbound_named_relationship_query                              inbound_relationship_query
  # bidirectional_named_relationship_query                        bidirectional_relationship_query
  # named_predicate_exists_with_different_name?                   predicate_exists_with_different_relationship_name?

    # @deprecated Please use {#find_relationship_by_name} instead.
    def named_relationship(name)
      logger.warn("Deprecation: named_relationship has been deprecated.  Please call find_relationship_by_name instead.")
      find_relationship_by_name(name)
    end

    # @deprecated Please use {#register_relationship_desc_subject} instead.
    def register_named_subject(subject)
      logger.warn("Deprecation: register_named_subject has been deprecated.  Please call register_relationship_desc_subject instead.")
      register_relationship_desc_subject(subject)
    end 
    
    # @deprecated Please use {#register_relationship_desc} instead.
    def register_named_relationship(subject, name, predicate, opts)
      logger.warn("Deprecation: register_named_relationship has been deprecated.  Please call register_relationship_desc instead.")
      register_relationship_desc(subject, name, predicate, opts)
    end 

    # @deprecated Please use {#relationships_by_name} instead.
    def named_relationships(outbound_only=true)
      logger.warn("Deprecation: named_relationships has been deprecated.  Please call relationships_by_name instead.")
      relationships_by_name(outbound_only)
    end 

    # @deprecated Please use {#relationships_by_name_from_class} instead.
    def named_relationships_from_class
      logger.warn("Deprecation: named_relationships_from_class has been deprecated.  Please call relationships_by_name_from_class instead.")
      relationships_by_name_from_class
    end 

    # @deprecated Please use {#inbound_relationships_by_name} instead.
    def named_inbound_relationships
      logger.warn("Deprecation: named_inbound_relationships has been deprecated.  Please call inbound_relationships_by_name instead.")
      inbound_relationships_by_name
    end 

    # @deprecated Please use {#outbound_relationships_by_name} instead.
    def named_outbound_relationships
      logger.warn("Deprecation: named_outbound_relationships has been deprecated.  Please call outbound_relationships_by_name instead.")
      outbound_relationships_by_name
    end 

    # @deprecated Please use {#outbound_relationship_predicates} instead.
    def outbound_named_relationship_predicates
      logger.warn("Deprecation: outbound_named_relationship_predicates has been deprecated.  Please call outbound_relationship_predicates instead.")
      outbound_relationship_predicates
    end 

    # @deprecated Please use {#inbound_relationship_predicates} instead.
    def inbound_named_relationship_predicates
      logger.warn("Deprecation: inbound_named_relationship_predicates has been deprecated.  Please call inbound_relationship_predicates instead.")
      inbound_relationship_predicates
    end 

    # @deprecated Please use {#relationship_predicates} instead.
    def named_relationship_predicates
      logger.warn("Deprecation: named_relationship_predicates has been deprecated.  Please call relationship_predicates instead.")
      relationship_predicates
    end 

    # @deprecated Please use {#relationship_predicates_from_class} instead.
    def named_relationship_predicates_from_class
      logger.warn("Deprecation: named_relationship_predicates_from_class has been deprecated.  Please call relationship_predicates_from_class instead.")
      relationship_predicates_from_class
    end 

    # @deprecated Please use {#is_relationship_name?} instead.
    def is_named_relationship?(name, outbound_only=true)
      logger.warn("Deprecation: is_named_relationship? has been deprecated.  Please call is_relationship_name? instead.")
      is_relationship_name?(name,outbound_only)
    end 

    # @deprecated Please use {#relationships_desc} instead.
    def named_relationships_desc
      logger.warn("Deprecation: named_relationships_desc has been deprecated.  Please call relationships_desc instead.")
      relationships_desc
    end 

    # @deprecated Please use {#relationships_desc_from_class} instead.
    def named_relationships_desc_from_class
      logger.warn("Deprecation: named_relationships_desc_from_class has been deprecated.  Please call relationships_desc_from_class instead.")
      relationships_desc_from_class
    end 

    # @deprecated Please use {#relationship_model_type} instead.
    def named_relationship_type(name)
      logger.warn("Deprecation: named_relationship_type has been deprecated.  Please call relationship_model_type instead.")
      relationship_model_type(name)
    end 

    # @deprecated Please use {#add_relationship_by_name} instead.
    def add_named_relationship(name,object)
      logger.warn("Deprecation: add_named_relationship has been deprecated.  Please call add_relationship_by_name instead.")
      add_relationship_by_name(name,object)
    end 

    # @deprecated Please use {#remove_relationship_by_name} instead.
    def remove_named_relationship(name,object)
      logger.warn("Deprecation: remove_named_relationship has been deprecated.  Please call remove_relationship_by_name instead.")
      remove_relationship_by_name(name,object)
    end 

    # @deprecated Please use {#assert_conforms_to} instead.
    def assert_kind_of_model(name,object,model_class)
      logger.warn("Deprecation: assert_kind_of_model has been deprecated.  Please call assert_conforms_to instead.")
      assert_conforms_to(name,object,model_class)
    end 

    # @deprecated Please use {#conforms_to?} instead.
    def kind_of_model?(model_class)
      logger.warn("Deprecation: kind_of_model? has been deprecated.  Please call conforms_to? instead.")
      conforms_to?(model_class)
    end 

    # @deprecated Please use {#relationship_query} instead.
    def named_relationship_query(relationship_name)
      logger.warn("Deprecation: named_relationship_query has been deprecated.  Please call relationship_query instead.")
      relationship_query(relationship_name)
    end 

    module ClassMethods

      # ** EXPERIMENTAL **
      #  
      # Return hash that persists relationship metadata defined by has_relationship calls
      # @return [Hash] Hash of relationship subject (:self or :inbound) mapped to nested hashs of each relationship name mapped to another hash relationship options
      # @example
      # For the following relationship
      #
      #  has_relationship "audio_records", :has_part, :type=>AudioRecord
      # Results in the following returned by relationships_desc
      #  {:self=>{"audio_records"=>{:type=>AudioRecord, :singular=>nil, :predicate=>:has_part, :inbound=>false}}}
      def relationships_desc
        @class_relationships_desc ||= Hash[:self => {}]
      end

      # ** EXPERIMENTAL **
      #   
      # Internal method that ensures a relationship subject such as :self and :inbound
      # exist within the relationships_desc hash tracking relationships metadata. 
      # @param [Symbol] Subject name to register (will probably be something like :self or :inbound)
      def register_relationship_desc_subject(subject)
        unless relationships_desc.has_key?(subject) 
          relationships_desc[subject] = {} 
        end
      end
  
      # ** EXPERIMENTAL **
      # 
      # Internal method that adds relationship name and predicate pair to either an outbound (:self)
      # or inbound (:inbound) relationship types. Refer to ActiveFedora::SemanticNode.has_relationship for information on what metadata will be persisted.
      # @param [Symbol] Subject name to register
      # @param [String] Name of relationship being registered
      # @param [Symbol] Fedora ontology predicate to use
      # @param [Hash] Any options passed to has_relationship such as :type, :query_params, etc.
      def register_relationship_desc(subject, name, predicate, opts={})
        register_relationship_desc_subject(subject)
        opts.merge!({:predicate=>predicate})
        relationships_desc[subject][name] = opts
      end

      # Tests if the relationship name passed is in bidirectional
      # @param [String] relationship name to test
      # @return [Boolean]
      def is_bidirectional_relationship?(relationship_name)
        (relationships_desc.has_key?(:self)&&relationships_desc.has_key?(:inbound)&&relationships_desc[:self].has_key?("#{relationship_name}_outbound") && relationships_desc[:inbound].has_key?("#{relationship_name}_inbound")) 
      end

      # ** EXPERIMENTAL **
      #   
      # Used in has_relationship call to create dynamic helper methods to 
      # append and remove objects to and from a relationship
      # @param [String] relationship name to create helper methods for
      # @example
      # For the following relationship
      #
      #  has_relationship "audio_records", :has_part, :type=>AudioRecord
      #
      # Methods audio_records_append and audio_records_remove are created.
      # Boths methods take an object that is kind_of? ActiveFedora::Base as a parameter
      def create_relationship_name_methods(name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_relationship_by_name(name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_relationship_by_name(name,object)}
      end 

      #  ** EXPERIMENTAL **
      #  Similar to +create_relationship_name_methods+ except it is used when an ActiveFedora::Base model class
      #  declares has_bidirectional_relationship.  we are merely creating an alias for outbound portion of bidirectional
      #  @param [String] bidirectional relationship name
      #  @param [String] outbound relationship method name associated with the bidirectional relationship ([bidirectional_name]_outbound)
      #  @example
      #    has_bidirectional_relationship "members", :has_collection_member, :is_member_of_collection
      #    
      #    Method members_outbound_append and members_outbound_remove added
      #    This method will create members_append which does same thing as members_outbound_append
      #    and will create members_remove which does same thing as members_outbound_remove
      def create_bidirectional_relationship_name_methods(name,outbound_name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_relationship_by_name(outbound_name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_relationship_by_name(outbound_name,object)}
      end

      # Returns a solr query for retrieving objects specified in an outbound relationship.
      # This method is mostly used by internal method calls.
      # It enables the use of query_params defined within a relationship to attach a query filter
      # on top of just the predicate being used.  Because it is static it 
      # needs the pids defined within RELS-EXT for this relationship to be passed in.
      # If you are calling this method directly to get the query you should use the 
      # ActiveFedora::SemanticNode.relationship_query instead or use the helper method
      # [relationship_name]_query, i.e. method "parts_query" for relationship "parts".  This
      # method would only be called directly if you had something like an array of outbound pids
      # already in something like a solr document for object that has these relationships.
      # @param [String] The name of the relationship defined in the model
      # @param [Array] An array of pids to include in the query
      # @return [String]
      # @example
      #   Class SampleAFObjRelationshipQueryParam < ActiveFedora::Base
      #     #points to all parents linked via is_member_of
      #     has_relationship "parents", :is_member_of
      #     #returns only parents that have a level value set to "series"
      #     has_relationship "series_parents", :is_member_of, :query_params=>{:q=>{"level_t"=>"series"}}
      #   end
      #   s = SampleAFObjRelationshipQueryParam.new
      #   obj = ActiveFedora::Base.new
      #   s.series_parents_append(obj)
      #   s.series_parents_query 
      #   #=> "(id:changeme\\:13020 AND level_t:series)" 
      #   SampleAFObjRelationshipQueryParam.outbound_relationship_query("series_parents",["id:changeme:13020"])
      #   #=> "(id:changeme\\:13020 AND level_t:series)" 
      def outbound_relationship_query(relationship_name,outbound_pids)
        query = ActiveFedora::SolrService.construct_query_for_pids(outbound_pids)
        subject = :self
        if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:query_params)
          query_params = format_query_params(relationships_desc[subject][relationship_name][:query_params])
          if query_params[:q]
            unless query.empty?
              #substitute in the filter query for each pid so that it is applied to each in the query
              query_parts = query.split(/OR/)
              query = ""
              query_parts.each_with_index do |query_part,index|
                query_part.strip!
                query << " OR " if index > 0
                query << "(#{query_part} AND #{query_params[:q]})"
              end
              #query.sub!(/OR /,"AND #{query_params[:q]}) OR (")
              #add opening parenthesis for first case
              #query = "(" + query 
              #add AND filter case for last element as well since no 'OR' following it
              #query << " AND #{query_params[:q]})"
            else
              query = query_params[:q]
            end
          end
        end
        query
      end

      # Returns a solr query for retrieving objects specified in an inbound relationship.
      # This method is mostly used by internal method calls.
      # It enables the use of query_params defined within a relationship to attach a query filter
      # on top of just the predicate being used.  Because it is static it 
      # needs the pid of the object that has the inbound relationships passed in.
      # If you are calling this method directly to get the query you should use the 
      # ActiveFedora::SemanticNode.relationship_query instead or use the helper method
      # [relationship_name]_query, i.e. method "parts_query" for relationship "parts".  This
      # method would only be called directly if you were working only with Solr and already
      # had the pid for the object in something like a solr document.
      # @param [String] The pid for the object that has these inbound relationships
      # @param [String] The name of the relationship defined in the model
      # @return [String]
      # @example
      #   Class SampleAFObjRelationshipQueryParam < ActiveFedora::Base
      #     #returns all parts
      #     has_relationship "parts", :is_part_of, :inbound=>true
      #     #returns only parts that have level to "series"
      #     has_relationship "series_parts", :is_part_of, :inbound=>true, :query_params=>{:q=>{"level_t"=>"series"}}
      #   end
      #   s = SampleAFObjRelationshipQueryParam.new
      #   s.pid 
      #   #=> id:changeme:13020
      #   s.series_parts_query
      #   #=> "is_part_of_s:info\\:fedora/changeme\\:13021 AND level_t:series"
      #   SampleAFObjRelationshipQueryParam.inbound_relationship_query(s.pid,"series_parts")
      #   #=> "is_part_of_s:info\\:fedora/changeme\\:13021 AND level_t:series"
      def inbound_relationship_query(pid,relationship_name)
        query = ""
        subject = :inbound
        if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name)
          predicate = relationships_desc[subject][relationship_name][:predicate]
          internal_uri = "info:fedora/#{pid}"
          escaped_uri = internal_uri.gsub(/(:)/, '\\:')
          query = "#{predicate}_s:#{escaped_uri}" 
          if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:query_params)
            query_params = format_query_params(relationships_desc[subject][relationship_name][:query_params])
            if query_params[:q]
              query << " AND " unless query.empty?
              query << query_params[:q]
            end
          end
        end
        query
      end

      # Returns a solr query for retrieving objects specified in a bidirectional relationship.
      # This method is mostly used by internal method calls.
      # It enables the use of query_params defined within a relationship to attach a query filter
      # on top of just the predicate being used.  Because it is static it 
      # needs the pids defined within RELS-EXT for the outbound relationship as well as the pid of the
      # object for the inbound portion of the relationship.
      # If you are calling this method directly to get the query you should use the 
      # ActiveFedora::SemanticNode.relationship_query instead or use the helper method
      # [relationship_name]_query, i.e. method "bi_parts_query" for relationship "bi_parts".  This
      # method would only be called directly if you had something like an array of outbound pids
      # already in something like a solr document for object that has these relationships.
      # @param [String] The pid for the object that has these inbound relationships
      # @param [String] The name of the relationship defined in the model
      # @param [Array] An array of pids to include in the query
      # @return [String]
      # @example
      #   Class SampleAFObjRelationshipQueryParam < ActiveFedora::Base
      #     has_bidirectional_relationship "bi_series_parts", :has_part, :is_part_of, :query_params=>{:q=>{"level_t"=>"series"}}
      #   end
      #   s = SampleAFObjRelationshipQueryParam.new
      #   obj = ActiveFedora::Base.new
      #   s.bi_series_parts_append(obj)
      #   s.pid
      #   #=> "changeme:13025" 
      #   obj.pid
      #   #=> id:changeme:13026
      #   s.bi_series_parts_query 
      #   #=> "(id:changeme\\:13026 AND level_t:series) OR (is_part_of_s:info\\:fedora/changeme\\:13025 AND level_t:series)" 
      #   SampleAFObjRelationshipQueryParam.bidirectional_relationship_query(s.pid,"series_parents",["id:changeme:13026"])
      #   #=> "(id:changeme\\:13026 AND level_t:series) OR (is_part_of_s:info\\:fedora/changeme\\:13025 AND level_t:series)" 
      def bidirectional_relationship_query(pid,relationship_name,outbound_pids)
        outbound_query = outbound_relationship_query("#{relationship_name}_outbound",outbound_pids) 
        inbound_query = inbound_relationship_query(pid,"#{relationship_name}_inbound")
        query = outbound_query # use outbound_query by default
        if !inbound_query.empty?
          query << " OR (" + inbound_relationship_query(pid,"#{relationship_name}_inbound") + ")"
        end
        return query      
      end

      # This will transform and encode any query_params defined in a relationship method to properly escape special characters
      # and format strings such as query string properly for a solr query
      # @param [Hash] The has of expected query params (including at least :q)
      # @return [String]
      def format_query_params(query_params)
        if query_params && query_params[:q]
          add_query = ""
          if query_params[:q].is_a? Hash
            query_params[:q].keys.each_with_index do |key,index|
              add_query << " AND " if index > 0
              add_query << "#{key}:#{query_params[:q][key].gsub(/:/, '\\\\:')}"
            end
          elsif !query_params[:q].empty?
            add_query = "#{query_params[:q]}"
          end
          query_params[:q] = add_query unless add_query.empty?
          query_params
        end
      end

      # Check if a relationship has any solr query filters defined by has_relationship call
      # @param [Symbol] subject to use such as :self or :inbound
      # @param [String] relationship name
      # @return [Boolean] true if the relationship has a query filter defined
      def relationship_has_query_params?(subject, relationship_name)
        relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:query_params)
      end

      # ** EXPERIMENTAL **
      # 
      # Check to make sure a subject,name, and predicate triple does not already exist
      # with the same subject but different name.
      # This method is used to ensure conflicting has_relationship calls are not made because
      # predicates cannot be reused across relationship names.  Otherwise, the mapping of relationship name
      # to predicate in RELS-EXT would be broken.
      # @param [Symbol] subject to check (:self or :inbound)
      # @param [String] relationship name
      # @param [Symbol] symbol for Fedora relationship ontology predicate
      def predicate_exists_with_different_relationship_name?(subject,name,predicate)
        if relationships_desc.has_key?(subject)
          relationships_desc[subject].each_pair do |existing_name, args|
            return true if !args[:predicate].nil? && args[:predicate] == predicate && existing_name != name 
          end
        end
        return false
      end

      ## Deprecated class method checks for HYDRA-541 methods renamed
      # 
      # Old Name                                                      New Name
      # named_relationships_desc                                      relationships_desc
      # register_named_subject                                        register_relationship_desc_subject
      # register_named_relationship                                   register_relationship_desc
      # create_named_relationship_method                              create_relationship_name_methods
      # create_bidirectional_named_relationship_methods               create_bidirectional_relationship_name_methods
      # outbound_named_relationship_query                             outbound_relationship_query
      # inbound_named_relationship_query                              inbound_relationship_query
      # bidirectional_named_relationship_query                        bidirectional_relationship_query
      # named_predicate_exists_with_different_name?                   predicate_exists_with_different_relationship_name?
      # @deprecated Please use {#relationship_desc} instead.
      def named_relationships_desc
        logger.warn("Deprecation: named_relationships_desc has been deprecated.  Please call relationships_desc instead.")
        relationships_desc
      end

      # @deprecated Please use {#register_relationship_desc_subject} instead.
      def register_named_subject(subject)
        logger.warn("Deprecation: register_named_subject has been deprecated.  Please call register_relationship_desc_subject instead.")
        register_relationship_desc_subject(subject)
      end

      # @deprecated Please use {#register_relationship_desc} instead.
      def register_named_relationship(subject, name, predicate, opts)
        logger.warn("Deprecation: register_named_relationship has been deprecated.  Please call register_relationship_desc instead.")
        register_relationship_desc(subject, name, predicate, opts)
      end

      # @deprecated Please use {#create_relationship_name_methods} instead.
      def create_named_relationship_methods(name)
        logger.warn("Deprecation: create_named_relationship_methods has been deprecated.  Please call create_relationship_name_methods instead.")
        create_relationship_name_methods(name)
      end

      # @deprecated Please use {#create_bidirecational_relationship_name_methods} instead.
      def create_bidirectional_named_relationship_methods(name,outbound_name)
        logger.warn("Deprecation: create_bidirectional_named_relationship_methods has been deprecated.  Please call create_bidirectional_relationship_name_methods instead.")
        create_bidirectional_relationship_name_methods(name,outbound_name)
      end

      # @deprecated Please use {#outbound_relationship_query} instead.
      def outbound_named_relationship_query(relationship_name,outbound_pids)
        logger.warn("Deprecation: outbound_named_relationship_query has been deprecated.  Please call outbound_relationship_query instead.")
        outbound_relationship_query(relationship_name,outbound_pids)
      end

      # @deprecated Please use {#inbound_relationship_query} instead.
      def inbound_named_relationship_query(pid,relationship_name)
        logger.warn("Deprecation: inbound_named_relationship_query has been deprecated.  Please call inbound_relationship_query instead.")
        inbound_relationship_query(pid,relationship_name)
      end

      # @deprecated Please use {#bidirectional_relationship_query} instead.
      def bidirectional_named_relationship_query(pid,relationship_name,outbound_pids)
        logger.warn("Deprecation: bidirectional_named_relationship_query has been deprecated.  Please call bidirectional_relationship_query instead.")
        bidirectional_relationship_query(pid,relationship_name,outbound_pids)
      end

      # @deprecated Please use {#predicate_exists_with_different_relationship_name?} instead.
      def named_predicate_exists_with_different_name?(subject,name,predicate)
        logger.warn("Deprecation: named_predicate_exists_with_different_name? has been deprecated.  Please call predicate_exists_with_different_relationship_name? instead.")
        predicate_exists_with_different_relationship_name?(subject,name,predicate)
      end
    end
  end
end
