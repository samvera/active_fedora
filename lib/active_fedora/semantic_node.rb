module ActiveFedora
  module SemanticNode 
    include MediaShelfClassLevelInheritableAttributes
    ms_inheritable_attributes  :class_relationships, :internal_uri
    
    attr_accessor :internal_uri, :named_relationship_desc, :relationships_are_dirty, :load_from_solr
    

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def assert_kind_of(n, o,t)
      raise "Assertion failure: #{n}: #{o} is not of type #{t}" unless o.kind_of?(t)
    end
    
    def add_relationship(relationship)
      # Only accept ActiveFedora::Relationships as input arguments
      assert_kind_of 'relationship',  relationship, ActiveFedora::Relationship
      self.relationships_are_dirty = true
      register_triple(relationship.subject, relationship.predicate, relationship.object)
    end
    
    def register_triple(subject, predicate, object)
      register_subject(subject)
      register_predicate(subject, predicate)
      relationships[subject][predicate] << object
    end
    
    def register_subject(subject)
      if !relationships.has_key?(subject) 
          relationships[subject] = {} 
      end
    end
  
    def register_predicate(subject, predicate)
      register_subject(subject)
      if !relationships[subject].has_key?(predicate) 
        relationships[subject][predicate] = []
      end
    end
    
    # ** EXPERIMENTAL **
    # 
    # Internal method that ensures a relationship subject such as :self and :inbound
    # exist within the named_relationships_desc hash tracking named relationships metadata. 
    # This method just calls the class method counterpart of this method.
    def register_named_subject(subject)
      self.class.register_named_subject(subject)
    end
  
    # ** EXPERIMENTAL **
    # 
    # Internal method that adds relationship name and predicate pair to either an outbound (:self)
    # or inbound (:inbound) relationship types.  This method just calls the class method counterpart of this method.
    def register_named_relationship(subject, name, predicate, opts)
      self.class.register_named_relationship(subject, name, predicate, opts)
    end

    # ** EXPERIMENTAL **
    # 
    # Remove the given ActiveFedora::Relationship from this object
    def remove_relationship(relationship)
      @relationships_are_dirty = true
      unregister_triple(relationship.subject, relationship.predicate, relationship.object)
    end

    # ** EXPERIMENTAL **
    # 
    # Remove the subject, predicate, and object triple from the relationships hash
    def unregister_triple(subject, predicate, object)
      if relationship_exists?(subject, predicate, object)
        relationships[subject][predicate].delete_if {|curObj| curObj == object}
        relationships[subject].delete(predicate) if relationships[subject][predicate].nil? || relationships[subject][predicate].empty? 
      else
        return false
      end     
    end
    
    # ** EXPERIMENTAL **
    # 
    # Returns true if a relationship exists for the given subject, predicate, and object triple
    def relationship_exists?(subject, predicate, object)
      outbound_only = (subject != :inbound)
      #cache the call in case it is retrieving inbound as well, don't want to hit solr too many times
      cached_relationships = relationships(outbound_only)
      cached_relationships.has_key?(subject)&&cached_relationships[subject].has_key?(predicate)&&cached_relationships[subject][predicate].include?(object)
    end

    def inbound_relationships(response_format=:uri)
      rel_values = {}
      inbound_named_relationship_predicates.each_pair do |name,predicate|
        objects = self.send("#{name}",{:response_format=>response_format})
        items = []
        objects.each do |object|
          if (response_format == :uri)    
            #create a Relationship object so that it generates the appropriate uri
            r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>object)
            items.push(r.object)
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
      if !internal_uri.nil? && !relationships[internal_uri].nil?
        return relationships[:self].merge(relationships[internal_uri]) 
      else
        return relationships[:self]
      end
    end
    
    # If outbound_only is false, inbound relationships will be included.
    def relationships(outbound_only=true)
      @relationships ||= relationships_from_class
      outbound_only ? @relationships : @relationships.merge(:inbound=>inbound_relationships)
    end
    
    def relationships_from_class
      rels = {}
      self.class.relationships.each_pair do |subj, pred|
        rels[subj] = {}
        pred.each_key do |pred_key|
          rels[subj][pred_key] = []
        end
      end
      return rels
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return array of objects for a given relationship name
    def named_relationship(name)
      rels = nil
      if inbound_relationship_names.include?(name)
        rels = named_relationships(false)[:inbound][name]
      elsif outbound_relationship_names.include?(name)
        rels = named_relationships[:self][name]
      end
      rels = [] if rels.nil?
      return rels
    end
    
    # ** EXPERIMENTAL **
    # 
    # Gets the named relationships hash of subject=>name=>object_array
    # It has an optional parameter of outbound_only that defaults true.
    # If false it will include inbound relationships in the results.
    # Also, it will only reload outbound relationships if the relationships hash has changed
    # since the last time this method was called.
    def named_relationships(outbound_only=true)
      #make sure to update if relationships have been updated
      if @relationships_are_dirty == true
        @named_relationships = named_relationships_from_class()
        @relationships_are_dirty = false
      end
      
      #this will get called normally on first fetch if relationships are not dirty
      @named_relationships ||= named_relationships_from_class()
      outbound_only ? @named_relationships : @named_relationships.merge(:inbound=>named_inbound_relationships)      
    end
    
    # ** EXPERIMENTAL **
    # 
    # Gets named relationships from the class using the current relationships hash
    # and relationship name,predicate pairs.
    def named_relationships_from_class()
      rels = {}
      named_relationship_predicates.each_pair do |subj, names|
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
    # Return hash of named_relationships defined within other objects' RELS-EXT
    # It returns a hash of relationship name to arrays of objects.  It requeries
    # solr each time this method is called.
    def named_inbound_relationships
      rels = {}
      if named_relationships_desc.has_key?(:inbound)&&!named_relationships_desc[:inbound].empty?()
        inbound_rels = inbound_relationships
      
        if named_relationship_predicates.has_key?(:inbound)
          named_relationship_predicates[:inbound].each do |name, predicate|
            rels[name] = inbound_rels.has_key?(predicate) ? inbound_rels[predicate] : []
          end
        end
      end
      return rels
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of outbound relationship names and predicate pairs
    def outbound_named_relationship_predicates
      named_relationship_predicates.has_key?(:self) ? named_relationship_predicates[:self] : {}
    end

    # ** EXPERIMENTAL **
    # 
    # Return hash of inbound relationship names and predicate pairs
    def inbound_named_relationship_predicates
      named_relationship_predicates.has_key?(:inbound) ? named_relationship_predicates[:inbound] : {}
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of relationship names and predicate pairs
    def named_relationship_predicates
      @named_relationship_predicates ||= named_relationship_predicates_from_class
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of relationship names and predicate pairs from class
    def named_relationship_predicates_from_class
      rels = {}
      named_relationships_desc.each_pair do |subj, names|
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
    def relationship_names
      names = []
      named_relationships_desc.each_key do |subject|
            names = names.concat(named_relationships_desc[subject].keys)
        end
        names
    end

    # ** EXPERIMENTAL **
    # 
    # Return array of relationship names for all named inbound relationships (coming from other objects' RELS-EXT and Solr)
    def inbound_relationship_names
        named_relationships_desc.has_key?(:inbound) ? named_relationships_desc[:inbound].keys : []
    end

    # ** EXPERIMENTAL **
    # 
    # Return array of relationship names for all named outbound relationships (coming from this object's RELS-EXT)
    def outbound_relationship_names
        named_relationships_desc.has_key?(:self) ? named_relationships_desc[:self].keys : []
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash of named_relationships defined within this object's RELS-EXT
    # It returns a hash of relationship name to arrays of objects
    def named_outbound_relationships
        named_relationships_desc.has_key?(:self) ? named_relationships[:self] : {}
    end
  
    # ** EXPERIMENTAL **
    # 
    # Returns true if the given relationship name is a named relationship
    # ====Parameters
    #  name: Name of relationship
    #  outbound_only:  If false checks inbound relationships as well (defaults to true)
    def is_named_relationship?(name, outbound_only=true)
      if outbound_only
        outbound_relationship_names.include?(name)
      else
        (outbound_relationship_names.include?(name)||inbound_relationship_names.include?(name))
      end
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return hash that stores named relationship metadata defined by has_relationship calls
    # ====Example
    # For the following relationship
    #
    #  has_relationship "audio_records", :has_part, :type=>AudioRecord
    # Results in the following returned by named_relationships_desc
    #  {:self=>{"audio_records"=>{:type=>AudioRecord, :singular=>nil, :predicate=>:has_part, :inbound=>false}}}
    def named_relationships_desc
      @named_relationships_desc ||= named_relationships_desc_from_class
    end
    
    # ** EXPERIMENTAL **
    # 
    # Get class instance variable named_relationships_desc that holds has_relationship metadata
    def named_relationships_desc_from_class
      self.class.named_relationships_desc
    end
    
    # ** EXPERIMENTAL **
    # 
    # Return the value of :type for the relationship for name passed in.
    # It defaults to ActiveFedora::Base.
    def named_relationship_type(name)
      if is_named_relationship?(name,true)
        subject = outbound_relationship_names.include?(name)? :self : :inbound
        if named_relationships_desc[subject][name].has_key?(:type)
          return class_from_name(named_relationships_desc[subject][name][:type])
        end
      end
      return nil  
    end

    # ** EXPERIMENTAL **
    # 
    # Add an outbound relationship for given named relationship
    # See ActiveFedora::SemanticNode::ClassMethods.has_relationship
    def add_named_relationship(name, object)
      if is_named_relationship?(name,true)
        if named_relationships_desc[:self][name].has_key?(:type)
          klass = class_from_name(named_relationships_desc[:self][name][:type])
          unless klass.nil?
            (assert_kind_of_model 'object', object, klass)
          end
        end
        #r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>outbound_named_relationship_predicates[name],:object=>object})
        #add_relationship(r)
        add_relationship(outbound_named_relationship_predicates[name],object)
      else
        false
      end
    end
    
    # ** EXPERIMENTAL **
    # 
    # Remove an object from the named relationship
    def remove_named_relationship(name, object)
      if is_named_relationship?(name,true)
        remove_relationship(outbound_named_relationship_predicates[name],object)
      else
        return false
      end
    end
    
    # ** EXPERIMENTAL **
    # 
    # Throws an assertion error if kind_of_model? returns false for object and model_class
    # ====Parameters
    #  name: Name of object (just label for output)
    #  object: The object to test
    #  model_class: The model class used to in kind_of_model? check on object
    def assert_kind_of_model(name, object, model_class)
      raise "Assertion failure: #{name}: #{object.pid} does not have model #{model_class}, it has model #{relationships[:self][:has_model]}" unless object.kind_of_model?(model_class)
    end
    
    # ** EXPERIMENTAL **
    # 
    # Checks that this object is matches the model class passed in.
    # It requires two steps to pass to return true
    #   1. It has a hasModel relationship of the same model
    #   2. kind_of? returns true for the model passed in
    # This method can most often be used to detect if an object from Fedora that was created
    # with a different model was then used to populate this object.
    def kind_of_model?(model_class)
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
    
    def class_from_name(name)
      klass = name.to_s.split('::').inject(Kernel) {|scope, const_name| 
      scope.const_get(const_name)}
      (!klass.nil? && klass.is_a?(::Class)) ? klass : nil
    end
    
    # Creates a RELS-EXT datastream for insertion into a Fedora Object
    # @param [String] pid
    # @param [Hash] relationships (optional) @default self.relationships
    # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
    def to_rels_ext(pid, relationships=self.relationships)
      starter_xml = <<-EOL
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="info:fedora/#{pid}">
        </rdf:Description>
      </rdf:RDF>
      EOL
      xml = REXML::Document.new(starter_xml)
    
      # Iterate through the hash of predicates, adding an element to the RELS-EXT for each "object" in the predicate's corresponding array.
      # puts ""
      # puts "Iterating through a(n) #{self.class}"
      # puts "=> whose relationships are #{self.relationships.inspect}"
      # puts "=> and whose outbound relationships are #{self.outbound_relationships.inspect}"
      self.outbound_relationships.each do |predicate, targets_array|
        targets_array.each do |target|
          xmlns=String.new
          case predicate
          when :has_model, "hasModel", :hasModel
            xmlns="info:fedora/fedora-system:def/model#"
            begin
              rel_predicate = self.class.predicate_lookup(predicate,xmlns)
            rescue UnregisteredPredicateError
              xmlns = nil
              rel_predicate = nil
            end
          else
            xmlns="info:fedora/fedora-system:def/relations-external#"
            begin
              rel_predicate = self.class.predicate_lookup(predicate,xmlns)
            rescue UnregisteredPredicateError
              xmlns = nil
              rel_predicate = nil
            end
          end
          
          unless xmlns && rel_predicate
            rel_predicate, xmlns = self.class.find_predicate(predicate)
          end
          # puts ". #{predicate} #{target} #{xmlns}"
          xml.root.elements["rdf:Description"].add_element(rel_predicate, {"xmlns" => "#{xmlns}", "rdf:resource"=>target})
        end
      end
      xml.to_s
    end

    # Returns a solr query for retrieving objects specified in a relationship.
    # It enables the use of query_params defined within a relationship to attach a query filter
    # on top of just the predicate being used.
    # Instead of this method you can also use the helper method
    # [relationship_name]_query, i.e. method "parts_query" for relationship "parts".
    # @param [String] The name of the relationship defined in the model
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
    #   s.parents_append(obj)
    #   s.series_parents_query 
    #   #=> "(id:changeme\\:13020 AND level_t:series)" 
    #   SampleAFObjRelationshipQueryParam.named_relationship_query("series_parents")
    #   #=> "(id:changeme\\:13020 AND level_t:series)" 
    def named_relationship_query(relationship_name)
      query = ""
      if self.class.is_bidirectional_relationship?(relationship_name)
        id_array = []
        predicate = outbound_named_relationship_predicates["#{relationship_name}_outbound"]
        if !outbound_relationships[predicate].nil? 
          outbound_relationships[predicate].each do |rel|
            id_array << rel.gsub("info:fedora/", "")
          end
        end
        query = self.class.bidirectional_named_relationship_query(pid,relationship_name,id_array)
      elsif outbound_relationship_names.include?(relationship_name)
        id_array = []
        predicate = outbound_named_relationship_predicates[relationship_name]
        if !outbound_relationships[predicate].nil? 
          outbound_relationships[predicate].each do |rel|
            id_array << rel.gsub("info:fedora/", "")
          end
        end
        query = self.class.outbound_named_relationship_query(relationship_name,id_array)
      elsif inbound_relationship_names.include?(relationship_name)
        query = self.class.inbound_named_relationship_query(pid,relationship_name)
      end
      query
    end

    module ClassMethods
    
      # Allows for a relationship to be treated like any other attribute of a model class. You define
      # named relationships in your model class using this method.  You then have access to several
      # helper methods to list, append, and remove objects from the list of relationships. 
      # ====Examples to define two relationships 
      #  class AudioRecord < ActiveFedora::Base
      #
      #   has_relationship "oral_history", :has_part, :inbound=>true, :type=>OralHistory
      #   # returns all similar audio
      #   has_relationship "similar_audio", :has_part, :type=>AudioRecord
      #   #returns only similar audio with format wav
      #   has_relationship "similar_audio_wav", :has_part, :query_params=>{:q=>"format_t"=>"wav"}
      #
      # The first two parameters are required:
      #   name: relationship name
      #   predicate: predicate for the relationship
      #   opts:
      #     possible parameters  
      #       :inbound => if true loads an external relationship via Solr (defaults to false)
      #       :type => The type of model to use when instantiated an object from the pid in this relationship (defaults to ActiveFedora::Base)
      #       :query_params => Additional filters to be attached via a solr query (currently only :q implemented)
      #
      # If inbound is true it expects the relationship to be defined by another object's RELS-EXT
      # and to load that relationship from Solr.  Otherwise, if inbound is true the relationship is stored in
      # this object's RELS-EXT datastream
      #
      # Word of caution - The same predicate may not be used twice for two inbound or two outbound relationships.  However, it may be used twice if one is inbound
      # and one is outbound as shown in the example above.  A full list of possible predicates are defined by predicate_mappings
      #
      # For the oral_history relationship in the example above the following helper methods are created:
      #  oral_history: returns array of OralHistory objects that have this AudioRecord with predicate :has_part 
      #  oral_history_ids: Return array of pids for OralHistory objects that have this AudioRecord with predicate :has_part
      #  oral_history_query: Return solr query that can be used to retrieve related objects as solr documents
      # 
      # For the outbound relationship "similar_audio" there are two additional methods to append and remove objects from that relationship
      # since it is managed internally:
      #  similar_audio: Return array of AudioRecord objects that have been added to similar_audio relationship
      #  similar_audio_ids:  Return array of AudioRecord object pids that have been added to similar_audio relationship
      #  similar_audio_query: Return solr query that can be used to retrieve related objects as solr documents
      #  similar_audio_append: Add an AudioRecord object to the similar_audio relationship
      #  similar_audio_remove: Remove an AudioRecord from the similar_audio relationship
      def has_relationship(name, predicate, opts = {})
        opts = {:singular => nil, :inbound => false}.merge(opts)
        if opts[:inbound] == true
          #raise "Duplicate use of predicate for named inbound relationship not allowed" if named_predicate_exists_with_different_name?(:inbound,name,predicate)
          register_named_relationship(:inbound, name, predicate, opts)
          register_predicate(:inbound, predicate)
          create_inbound_relationship_finders(name, predicate, opts)
        else
          #raise "Duplicate use of predicate for named outbound relationship not allowed" if named_predicate_exists_with_different_name?(:self,name,predicate)
          register_named_relationship(:self, name, predicate, opts)
          register_predicate(:self, predicate)
          create_named_relationship_methods(name)
          create_outbound_relationship_finders(name, predicate, opts)
        end
      end
      
      # Generates relationship finders for predicates that point in both directions
      #
      # @param [String] name of the relationship method(s) to create
      # @param [Symbol] outbound_predicate Predicate used in outbound relationships
      # @param [Symbol] inbound_predicate Predicate used in inbound relationships
      # @param [Hash] opts
      #
      # Example:
      #  has_bidirectional_relationship("parts", :has_part, :is_part_of)
      #
      # will create three instance methods: parts_outbound, and parts_inbound and parts
      # the inbound and outbound methods are the same that would result from calling 
      # create_inbound_relationship_finders and create_outbound_relationship_finders
      # The third method combines the results of both and handles generating appropriate 
      # solr queries where necessary.
      def has_bidirectional_relationship(name, outbound_predicate, inbound_predicate, opts={})
        create_bidirectional_relationship_finders(name, outbound_predicate, inbound_predicate, opts)
      end
      
      # ** EXPERIMENTAL **
      # 
      # Check to make sure a subject,name, and predicate triple does not already exist
      # with the same subject but different name.
      # This method is used to ensure conflicting has_relationship calls are not made because
      # predicates cannot be reused across relationship names.  Otherwise, the mapping of relationship name
      # to predicate in RELS-EXT would be broken.
      def named_predicate_exists_with_different_name?(subject,name,predicate)
        if named_relationships_desc.has_key?(subject)
          named_relationships_desc[subject].each_pair do |existing_name, args|
            return true if !args[:predicate].nil? && args[:predicate] == predicate && existing_name != name 
          end
        end
        return false
      end
      
      # ** EXPERIMENTAL **
      #  
      # Return hash that stores named relationship metadata defined by has_relationship calls
      # ====Example
      # For the following relationship
      #
      #  has_relationship "audio_records", :has_part, :type=>AudioRecord
      # Results in the following returned by named_relationships_desc
      #  {:self=>{"audio_records"=>{:type=>AudioRecord, :singular=>nil, :predicate=>:has_part, :inbound=>false}}}
      def named_relationships_desc
        @class_named_relationships_desc ||= Hash[:self => {}]
      end
      
      # ** EXPERIMENTAL **
      #   
      # Internal method that ensures a relationship subject such as :self and :inbound
      # exist within the named_relationships_desc hash tracking named relationships metadata. 
      def register_named_subject(subject)
        unless named_relationships_desc.has_key?(subject) 
          named_relationships_desc[subject] = {} 
        end
      end
  
      # ** EXPERIMENTAL **
      # 
      # Internal method that adds relationship name and predicate pair to either an outbound (:self)
      # or inbound (:inbound) relationship types.
      def register_named_relationship(subject, name, predicate, opts)
        register_named_subject(subject)
        opts.merge!({:predicate=>predicate})
        named_relationships_desc[subject][name] = opts
      end

      # Returns a solr query for retrieving objects specified in an outbound relationship.
      # This method is mostly used by internal method calls.
      # It enables the use of query_params defined within a relationship to attach a query filter
      # on top of just the predicate being used.  Because it is static it 
      # needs the pids defined within RELS-EXT for this relationship to be passed in.
      # If you are calling this method directly to get the query you should use the 
      # ActiveFedora::SemanticNode.named_relationship_query instead or use the helper method
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
      #   SampleAFObjRelationshipQueryParam.outbound_named_relationship_query("series_parents",["id:changeme:13020"])
      #   #=> "(id:changeme\\:13020 AND level_t:series)" 
      def outbound_named_relationship_query(relationship_name,outbound_pids)
        query = ActiveFedora::SolrService.construct_query_for_pids(outbound_pids)
        subject = :self
        if named_relationships_desc.has_key?(subject) && named_relationships_desc[subject].has_key?(relationship_name) && named_relationships_desc[subject][relationship_name].has_key?(:query_params)
          query_params = format_query_params(named_relationships_desc[subject][relationship_name][:query_params])
          if query_params[:q]
            unless query.empty?
              #substitute in the filter query for each pid so that it is applied to each in the query
              query.sub!(/OR /,"AND #{query_params[:q]}) OR (")
              #add opening parenthesis for first case
              query = "(" + query 
              #add AND filter case for last element as well since no 'OR' following it
              query << " AND #{query_params[:q]})"
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
      # ActiveFedora::SemanticNode.named_relationship_query instead or use the helper method
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
      #   SampleAFObjRelationshipQueryParam.inbound_named_relationship_query(s.pid,"series_parts")
      #   #=> "is_part_of_s:info\\:fedora/changeme\\:13021 AND level_t:series"
      def inbound_named_relationship_query(pid,relationship_name)
        query = ""
        subject = :inbound
        if named_relationships_desc.has_key?(subject) && named_relationships_desc[subject].has_key?(relationship_name)
          predicate = named_relationships_desc[subject][relationship_name][:predicate]
          internal_uri = "info:fedora/#{pid}"
          escaped_uri = internal_uri.gsub(/(:)/, '\\:')
          query = "#{predicate}_s:#{escaped_uri}" 
          if named_relationships_desc.has_key?(subject) && named_relationships_desc[subject].has_key?(relationship_name) && named_relationships_desc[subject][relationship_name].has_key?(:query_params)
            query_params = format_query_params(named_relationships_desc[subject][relationship_name][:query_params])
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
      # ActiveFedora::SemanticNode.named_relationship_query instead or use the helper method
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
      #   SampleAFObjRelationshipQueryParam.bidirectional_named_relationship_query(s.pid,"series_parents",["id:changeme:13026"])
      #   #=> "(id:changeme\\:13026 AND level_t:series) OR (is_part_of_s:info\\:fedora/changeme\\:13025 AND level_t:series)" 
      def bidirectional_named_relationship_query(pid,relationship_name,outbound_pids)
        outbound_query = outbound_named_relationship_query("#{relationship_name}_outbound",outbound_pids) 
        inbound_query = inbound_named_relationship_query(pid,"#{relationship_name}_inbound")
        query = outbound_query # use outbound_query by default
        if !inbound_query.empty?
          query << " OR (" + inbound_named_relationship_query(pid,"#{relationship_name}_inbound") + ")"
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

      #Tests if the relationship name passed is in bidirectional
      # @return [Boolean]
      def is_bidirectional_relationship?(relationship_name)
        named_relationships_desc[:self]["#{relationship_name}_outbound"] && named_relationships_desc[:inbound]["#{relationship_name}_inbound"] 
      end
      
      # ** EXPERIMENTAL **
      #   
      # Used in has_relationship call to create dynamic helper methods to 
      # append and remove objects to and from a named relationship
      # ====Example
      # For the following relationship
      #
      #  has_relationship "audio_records", :has_part, :type=>AudioRecord
      #
      # Methods audio_records_append and audio_records_remove are created.
      # Boths methods take an object that is kind_of? ActiveFedora::Base as a parameter
      def create_named_relationship_methods(name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_named_relationship(name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_named_relationship(name,object)}
      end 

      #  ** EXPERIMENTAL **
      #  Similar to +create_named_relationship_methods+ except we are merely creating an alias for outbound portion of bidirectional
      #
      #  ====Example
      #    has_bidirectional_relationship "members", :has_collection_member, :is_member_of_collection
      #    
      #    Method members_outbound_append and members_outbound_remove added
      #    This method will create members_append which does same thing as members_outbound_append
      #    and will create members_remove which does same thing as members_outbound_remove
      def create_bidirectional_named_relationship_methods(name,outbound_name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_named_relationship(outbound_name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_named_relationship(outbound_name,object)}
      end
    
      def create_inbound_relationship_finders(name, predicate, opts = {})
        class_eval <<-END
        def #{name}(opts={})
          opts = {:rows=>25}.merge(opts)
          query = self.class.inbound_named_relationship_query(self.pid,"#{name}")
          solr_result = SolrService.instance.conn.query(query, :rows=>opts[:rows])
          if opts[:response_format] == :solr
            return solr_result
          else
            if opts[:response_format] == :id_array
              id_array = []
              solr_result.hits.each do |hit|
                id_array << hit[SOLR_DOCUMENT_ID]
              end
              return id_array
            elsif opts[:response_format] == :load_from_solr || self.load_from_solr
              return ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
            else
              return ActiveFedora::SolrService.reify_solr_results(solr_result)
            end
          end
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
        end
        def #{name}_from_solr
          #{name}(:response_format => :load_from_solr)
        end
        def #{name}_solr_docs
          #{name}(:response_format => :solr)
        end
        def #{name}_query
          named_relationship_query("#{name}")
        end
        END
      end

      def relationship_has_query_params?(subject, relationship_name)
        named_relationships_desc.has_key?(subject) && named_relationships_desc[subject].has_key?(relationship_name) && named_relationships_desc[subject][relationship_name].has_key?(:query_params)
      end
    
      def create_outbound_relationship_finders(name, predicate, opts = {})
        class_eval <<-END
        def #{name}(opts={})
          id_array = []
          if !outbound_relationships[#{predicate.inspect}].nil? 
            outbound_relationships[#{predicate.inspect}].each do |rel|
              id_array << rel.gsub("info:fedora/", "")
            end
          end
          
          if opts[:response_format] == :id_array && !self.class.relationship_has_query_params?(:self,"#{name}")
            return id_array
          else
            query = self.class.outbound_named_relationship_query("#{name}",id_array)
            solr_result = SolrService.instance.conn.query(query)
            if opts[:response_format] == :solr
              return solr_result
            elsif opts[:response_format] == :id_array
              id_array = []
              solr_result.hits.each do |hit|
                id_array << hit[SOLR_DOCUMENT_ID]
              end
              return id_array
            elsif opts[:response_format] == :load_from_solr || self.load_from_solr
              return ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
            else
              return ActiveFedora::SolrService.reify_solr_results(solr_result)
            end
          end
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
        end
        def #{name}_from_solr
          #{name}(:response_format => :load_from_solr)
        end
        def #{name}_solr_docs
          #{name}(:response_format => :solr)
        end
        def #{name}_query
          named_relationship_query("#{name}")
        end
        END
      end

      # Generates relationship finders for predicates that point in both directions
      # and registers predicate relationships for each direction.
      #
      # @param [String] name Name of the relationship method(s) to create
      # @param [Symbol] outbound_predicate Predicate used in outbound relationships
      # @param [Symbol] inbound_predicate Predicate used in inbound relationships
      # @param [Hash] opts (optional)
      def create_bidirectional_relationship_finders(name, outbound_predicate, inbound_predicate, opts={})
        inbound_method_name = name.to_s+"_inbound"
        outbound_method_name = name.to_s+"_outbound"
        has_relationship(outbound_method_name, outbound_predicate, opts)
        has_relationship(inbound_method_name, inbound_predicate, opts.merge!(:inbound=>true))

        #create methods that mirror the outbound append and remove with our bidirectional name, assume just add and remove locally        
        create_bidirectional_named_relationship_methods(name,outbound_method_name)

        class_eval <<-END
        def #{name}(opts={})
          opts = {:rows=>25}.merge(opts)
          if opts[:response_format] == :solr || opts[:response_format] == :load_from_solr
            outbound_id_array = []
            predicate = outbound_named_relationship_predicates["#{name}_outbound"]
            if !outbound_relationships[predicate].nil? 
              outbound_relationships[predicate].each do |rel|
                outbound_id_array << rel.gsub("info:fedora/", "")
              end
            end
            #outbound_id_array = #{outbound_method_name}(:response_format=>:id_array)
            query = self.class.bidirectional_named_relationship_query(self.pid,"#{name}",outbound_id_array)
            solr_result = SolrService.instance.conn.query(query, :rows=>opts[:rows])
            
            if opts[:response_format] == :solr
              return solr_result
            elsif opts[:response_format] == :load_from_solr || self.load_from_solr
              return ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
            else
              return ActiveFedora::SolrService.reify_solr_results(solr_result)
            end
          else
            ary = #{inbound_method_name}(opts) + #{outbound_method_name}(opts)
            return ary.uniq
          end
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
        end
        def #{name}_from_solr
          #{name}(:response_format => :load_from_solr)
        end
        def #{name}_solr_docs
          #{name}(:response_format => :solr)
        end
        def #{name}_query
          named_relationship_query("#{name}")
        end
        END
      end
    
      # relationships are tracked as a hash of structure 
      # @example
      #   ds.relationships # => {:self=>{:has_model=>["afmodel:SimpleThing"],:has_part=>["demo:20"]},:inbound=>{:is_part_of=>["demo:6"]} 
      def relationships
        @class_relationships ||= Hash[:self => {}]
      end
    
    
      def register_subject(subject)
        if !relationships.has_key?(subject) 
            relationships[subject] = {} 
        end
      end
    
      def register_predicate(subject, predicate)
        register_subject(subject)
        if !relationships[subject].has_key?(predicate) 
          relationships[subject][predicate] = []
        end
      end
    
      #alias_method :register_target, :register_object
    
      # Creates a RELS-EXT datastream for insertion into a Fedora Object
      # @param [String] pid of the object that the RELS-EXT datastream belongs to
      # @param [Hash] relationships the relationships hash to transform into RELS-EXT RDF. @default the object's relationships hash
      # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
      def relationships_to_rels_ext(pid, relationships=self.relationships)
        starter_xml = <<-EOL
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="info:fedora/#{pid}">
          </rdf:Description>
        </rdf:RDF>
        EOL
        xml = REXML::Document.new(starter_xml)
      
        # Iterate through the hash of predicates, adding an element to the RELS-EXT for each "object" in the predicate's corresponding array.
        self.outbound_relationships.each do |predicate, targets_array|
          targets_array.each do |target|
            #puts ". #{predicate} #{target}"
            xml.root.elements["rdf:Description"].add_element(predicate_lookup(predicate), {"xmlns" => "info:fedora/fedora-system:def/relations-external#", "rdf:resource"=>target})
          end
        end
        xml.to_s
      end
    
      # If predicate is a symbol, looks up the predicate in the predicate_mappings
      # If predicate is not a Symbol, returns the predicate untouched
      # @raise UnregisteredPredicateError if the predicate is a symbol but is not found in the predicate_mappings
      def predicate_lookup(predicate,namespace="info:fedora/fedora-system:def/relations-external#")
        if predicate.class == Symbol 
          if predicate_mappings[namespace].has_key?(predicate)
            return predicate_mappings[namespace][predicate]
          else
            raise ActiveFedora::UnregisteredPredicateError
          end
        end
        return predicate
      end

      def predicate_config
        @@predicate_config ||= YAML::load(File.open(ActiveFedora.predicate_config)) if File.exist?(ActiveFedora.predicate_config)
      end

      def predicate_mappings
        predicate_config[:predicate_mapping]
      end

      def default_predicate_namespace
        predicate_config[:default_namespace]
      end

      def find_predicate(predicate)
        predicate_mappings.each do |namespace,predicates|
          if predicates.fetch(predicate,nil)
            return predicates[predicate], namespace
          end
        end
        debugger
        raise ActiveFedora::UnregisteredPredicateError
      end

      
    end
  end

  class UnregisteredPredicateError < RuntimeError; end

end
