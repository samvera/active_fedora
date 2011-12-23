module ActiveFedora
  module Relationships
    extend ActiveSupport::Concern

    included do
      class_attribute  :class_relationships_desc
    end

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

    # Return array of relationship names for all inbound relationships (coming from other objects' RELS-EXT and Solr)
    # @return [Array] of inbound relationship names for relationships declared via has_relationship in the class
    def inbound_relationship_names
        relationships_desc.has_key?(:inbound) ? relationships_desc[:inbound].keys : []
    end

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
    

    # Call this method to return the query used against solr to retrieve any
    # objects linked via the relationship name given.
    #
    # Instead of this method you can also use the helper method
    # [relationship_name]_query, i.e. method "parts_query" for relationship "parts" to return the same value
    # @param [String] The name of the relationship defined in the model
    # @return [String] The query used when querying solr for objects for this relationship
    # @example
    #   Class SampleAFObjRelationshipFilterQuery < ActiveFedora::Base
    #     #points to all parents linked via is_member_of
    #     has_relationship "parents", :is_member_of
    #     #returns only parents that have a level value set to "series"
    #     has_relationship "series_parents", :is_member_of, :solr_fq=>level_t:series"
    #   end
    #   s = SampleAFObjRelationshipFilterQuery.new
    #   obj = ActiveFedora::Base.new
    #   s.parents_append(obj)
    #   s.series_parents_query 
    #   #=> "(id:changeme\\:13020 AND level_t:series)" 
    #   SampleAFObjRelationshipFilterQuery.relationship_query("series_parents")
    #   #=> "(id:changeme\\:13020 AND level_t:series)" 
    def relationship_query(relationship_name)
      query = ""
      if self.class.is_bidirectional_relationship?(relationship_name)
        predicate = outbound_relationship_predicates["#{relationship_name}_outbound"]
        id_array = ids_for_outbound(predicate)
        query = self.class.bidirectional_relationship_query(pid,relationship_name,id_array)
      elsif outbound_relationship_names.include?(relationship_name)
        predicate = outbound_relationship_predicates[relationship_name]
        id_array = ids_for_outbound(predicate)
        query = self.class.outbound_relationship_query(relationship_name,id_array)
      elsif inbound_relationship_names.include?(relationship_name)
        query = self.class.inbound_relationship_query(pid,relationship_name)
      end
      query
    end


    # Gets the relationships hash with subject mapped to relationship
    # names instead of relationship predicates (unlike the "relationships" method in SemanticNode)
    # It has an optional parameter of outbound_only that defaults true.
    # If false it will include inbound relationships in the results.
    # Also, it will only reload outbound relationships if the relationships hash has changed
    # since the last time this method was called.
    # @param [Boolean] if false it will include inbound relationships (defaults to true)
    # @return [Hash] Returns a hash of subject name (:self or :inbound) mapped to nested hashs of each relationship name mapped to an Array of objects linked via the relationship
    def relationships_by_name(outbound_only=true)
      @relationships_by_name = relationships_by_name_from_class()
      outbound_only ? @relationships_by_name : @relationships_by_name.merge(:inbound=>inbound_relationships_by_name)      
    end

    # Gets relationships by name from the class using the current relationships hash
    # and relationship name,predicate pairs.
    # @return [Hash] returns the outbound relationships with :self mapped to nested hashs of each relationship name mapped to an Array of objects linked via the relationship
    def relationships_by_name_from_class()
      rels = {}
      relationship_predicates.each_pair do |subj, names|
        case subj
        when :self
          rels[:self] = {}
          names.each_pair do |name, predicate|
            set = []
            res = relationships.query(:predicate => Predicates.find_graph_predicate(predicate))
            res.each_object do |o|
              set << o.to_s
            end
            rels[:self][name] = set
          end
        when :inbound
          #nop
        end
      end
      return rels
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


    # Throws an assertion error if conforms_to? returns false for object and model_class
    # @param [String] Name of object (just label for output)
    # @param [ActiveFedora::Base] Expects to be an object that has ActiveFedora::Base as an ancestor of its class
    # @param [Class] The model class used in conforms_to? check on object
    def assert_conforms_to(name, object, model_class)
      raise "Assertion failure: #{name}: #{object.pid} does not have model #{model_class}, it has model #{relationships[:self][:has_model]}" unless object.conforms_to?(model_class)
    end
    
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
        mod = relationships.first(:predicate=>Predicates.find_graph_predicate(:has_model))
        if mod
          expected = ActiveFedora::ContentModel.pid_from_ruby_class(self.class)
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

    # Returns a Class symbol for the given string for the class name
    # @param [String] the class name as a string
    # @return [Class] the class as a Class object
    def class_from_name(name)
      klass = name.to_s.split('::').inject(Kernel) {|scope, const_name| 
      scope.const_get(const_name)}
      (!klass.nil? && klass.is_a?(::Class)) ? klass : nil
    end

    # Return array of relationship names for all outbound relationships (coming from this object's RELS-EXT)
    # @return [Array] of outbound relationship names for relationships declared via has_relationship in the class
    def outbound_relationship_names
        relationships_desc.has_key?(:self) ? relationships_desc[:self].keys : []
    end
  
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
    

    def load_inbound_relationship(name, predicate, opts={})
      opts = {:rows=>25}.merge(opts)
      query = self.class.inbound_relationship_query(self.pid,"#{name}")
      return [] if query.empty?
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



    def load_bidirectional(name, inbound_method_name, outbound_method_name, opts) 
        opts = {:rows=>25}.merge(opts)
        if opts[:response_format] == :solr || opts[:response_format] == :load_from_solr
          predicate = outbound_relationship_predicates["#{name}_outbound"]
          outbound_id_array = ids_for_outbound(predicate)
          query = self.class.bidirectional_relationship_query(self.pid,"#{name}",outbound_id_array)
          solr_result = SolrService.instance.conn.query(query, :rows=>opts[:rows])
          
          if opts[:response_format] == :solr
            return solr_result
          elsif opts[:response_format] == :load_from_solr || self.load_from_solr
            return ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
          else
            return ActiveFedora::SolrService.reify_solr_results(solr_result)
          end
        else
          ary = send(inbound_method_name,opts) + send(outbound_method_name, opts)
          return ary.uniq
        end
    end

    def load_outbound_relationship(name, predicate, opts={})
      id_array = ids_for_outbound(predicate)
      if opts[:response_format] == :id_array  && !self.relationship_has_solr_filter_query?(:self,"#{name}")
        return id_array
      else
        query = self.class.outbound_relationship_query(name,id_array)
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

    # Check if a relationship has any solr query filters defined by has_relationship call
    # @param [Symbol] subject to use such as :self or :inbound
    # @param [String] relationship name
    # @return [Boolean] true if the relationship has a query filter defined
    def relationship_has_solr_filter_query?(subject, relationship_name)
      relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:solr_fq)
    end


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
        add_relationship(outbound_relationship_predicates[name],object)
      else
        false
      end
    end
    
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


    module ClassMethods
      # Tests if the relationship name passed is in bidirectional
      # @param [String] relationship name to test
      # @return [Boolean]
      def is_bidirectional_relationship?(relationship_name)
        (relationships_desc.has_key?(:self)&&relationships_desc.has_key?(:inbound)&&relationships_desc[:self].has_key?("#{relationship_name}_outbound") && relationships_desc[:inbound].has_key?("#{relationship_name}_inbound")) 
      end


      # Returns a solr query for retrieving objects specified in an outbound relationship.
      # This method is mostly used by internal method calls.
      # It utilizes any solr_fq value defined within a relationship to attach a query filter when
      # querying solr on top of just the predicate being used.
      # Because it is static it 
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
      #   Class SampleAFObjRelationshipFilterQuery < ActiveFedora::Base
      #     #points to all parents linked via is_member_of
      #     has_relationship "parents", :is_member_of
      #     #returns only parents that have a level value set to "series"
      #     has_relationship "series_parents", :is_member_of, :solr_fq=>"level_t:series"
      #   end
      #   s = SampleAFObjRelationshipFilterQuery.new
      #   obj = ActiveFedora::Base.new
      #   s.series_parents_append(obj)
      #   s.series_parents_query 
      #   #=> "(id:changeme\\:13020 AND level_t:series)" 
      #   SampleAFObjRelationshipFilterQuery.outbound_relationship_query("series_parents",["id:changeme:13020"])
      #   #=> "(id:changeme\\:13020 AND level_t:series)" 
      def outbound_relationship_query(relationship_name,outbound_pids)
        query = ActiveFedora::SolrService.construct_query_for_pids(outbound_pids)
        subject = :self
        if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:solr_fq)
          solr_fq = relationships_desc[subject][relationship_name][:solr_fq]
          unless query.empty?
            #substitute in the filter query for each pid so that it is applied to each in the query
            query_parts = query.split(/OR/)
            query = ""
            query_parts.each_with_index do |query_part,index|
              query_part.strip!
              query << " OR " if index > 0
              query << "(#{query_part} AND #{solr_fq})"
            end
          else
            query = solr_fq
          end
        end
        query
      end


      # Returns a solr query for retrieving objects specified in an inbound relationship.
      # This method is mostly used by internal method calls.
      # It utilizes any solr_fq value defined within a relationship to attach a query filter
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
      #   Class SampleAFObjRelationshipFilterQuery < ActiveFedora::Base
      #     #returns all parts
      #     has_relationship "parts", :is_part_of, :inbound=>true
      #     #returns only parts that have level to "series"
      #     has_relationship "series_parts", :is_part_of, :inbound=>true, :solr_fq=>"level_t:series"
      #   end
      #   s = SampleAFObjRelationshipFilterQuery.new
      #   s.pid 
      #   #=> id:changeme:13020
      #   s.series_parts_query
      #   #=> "is_part_of_s:info\\:fedora/changeme\\:13021 AND level_t:series"
      #   SampleAFObjRelationshipFilterQuery.inbound_relationship_query(s.pid,"series_parts")
      #   #=> "is_part_of_s:info\\:fedora/changeme\\:13021 AND level_t:series"
      def inbound_relationship_query(pid,relationship_name)
        query = ""
        subject = :inbound
        if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name)
          predicate = relationships_desc[subject][relationship_name][:predicate]
          internal_uri = "info:fedora/#{pid}"
          escaped_uri = internal_uri.gsub(/(:)/, '\\:')
          query = "#{predicate}_s:#{escaped_uri}" 
          if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:solr_fq)
            solr_fq = relationships_desc[subject][relationship_name][:solr_fq]
            query << " AND " unless query.empty?
            query << solr_fq
          end
        end
        query
      end

      # Returns a solr query for retrieving objects specified in a bidirectional relationship.
      # This method is mostly used by internal method calls.
      # It usea of solr_fq value defined within a relationship to attach a query filter
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
      #   Class SampleAFObjRelationshipFilterQuery < ActiveFedora::Base
      #     has_bidirectional_relationship "bi_series_parts", :has_part, :is_part_of, :solr_fq=>"level_t:series"
      #   end
      #   s = SampleAFObjRelationshipFilterQuery.new
      #   obj = ActiveFedora::Base.new
      #   s.bi_series_parts_append(obj)
      #   s.pid
      #   #=> "changeme:13025" 
      #   obj.pid
      #   #=> id:changeme:13026
      #   s.bi_series_parts_query 
      #   #=> "(id:changeme\\:13026 AND level_t:series) OR (is_part_of_s:info\\:fedora/changeme\\:13025 AND level_t:series)" 
      #   SampleAFObjRelationshipFilterQuery.bidirectional_relationship_query(s.pid,"series_parents",["id:changeme:13026"])
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

      # Internal method that ensures a relationship subject such as :self and :inbound
      # exist within the relationships_desc hash tracking relationships metadata. 
      # @param [Symbol] Subject name to register (will probably be something like :self or :inbound)
      def register_relationship_desc_subject(subject)
        unless relationships_desc.has_key?(subject) 
          relationships_desc[subject] = {} 
        end
      end
  
      # Internal method that adds relationship name and predicate pair to either an outbound (:self)
      # or inbound (:inbound) relationship types. Refer to ActiveFedora::SemanticNode.has_relationship for information on what metadata will be persisted.
      # @param [Symbol] Subject name to register
      # @param [String] Name of relationship being registered
      # @param [Symbol] Fedora ontology predicate to use
      # @param [Hash] Any options passed to has_relationship such as :type, :solr_fq, etc.
      def register_relationship_desc(subject, name, predicate, opts={})
        register_relationship_desc_subject(subject)
        opts.merge!({:predicate=>predicate})
        relationships_desc[subject][name] = opts
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

      # Allows for a relationship to be treated like any other attribute of a model class. You define
      # relationships in your model class using this method.  You then have access to several
      # helper methods to list, append, and remove objects from the list of relationships. 
      # ====Examples to define two relationships 
      #  class AudioRecord < ActiveFedora::Base
      #
      #   has_relationship "oral_history", :has_part, :inbound=>true, :type=>OralHistory
      #   # returns all similar audio
      #   has_relationship "similar_audio", :has_part, :type=>AudioRecord
      #   #returns only similar audio with format wav
      #   has_relationship "similar_audio_wav", :has_part, :solr_fq=>"format_t:wav"
      #
      # The first two parameters are required:
      #   name: relationship name
      #   predicate: predicate for the relationship
      #   opts:
      #     possible parameters  
      #       :inbound => if true loads an external relationship via Solr (defaults to false)
      #       :type => The type of model to use when instantiated an object from the pid in this relationship (defaults to ActiveFedora::Base)
      #       :solr_fq => Define a solr query here if you want to filter out some objects in your relationship (must be a properly formatted solr query)
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
          register_relationship_desc(:inbound, name, predicate, opts)
          register_predicate(:inbound, predicate)
          create_inbound_relationship_finders(name, predicate, opts)
        else
          #raise "Duplicate use of predicate for named outbound relationship \"#{predicate.inspect}\" not allowed" if named_predicate_exists_with_different_name?(:self,name,predicate)
          register_relationship_desc(:self, name, predicate, opts)
          register_predicate(:self, predicate)
          create_relationship_name_methods(name)
          create_outbound_relationship_finders(name, predicate, opts)
        end
      end

      # Used in has_relationship call to create dynamic helper methods to 
      # append and remove objects to and from a relationship
      # @param [String] relationship name to create helper methods for
      # @example
      #   For the following relationship
      #
      #   has_relationship "audio_records", :has_part, :type=>AudioRecord
      #
      #   Methods audio_records_append and audio_records_remove are created.
      #   Boths methods take an object that is kind_of? ActiveFedora::Base as a parameter
      def create_relationship_name_methods(name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_relationship_by_name(name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_relationship_by_name(name,object)}
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
      
      def create_inbound_relationship_finders(name, predicate, opts = {})
        class_eval <<-END, __FILE__, __LINE__
        def #{name}(opts={})
          load_inbound_relationship('#{name}', '#{predicate}', opts)
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
        end
        def #{name}_from_solr
          #{name}(:response_format => :load_from_solr)
        end
        def #{name}_query
          relationship_query("#{name}")
        end
        END
      end
    
      def create_outbound_relationship_finders(name, predicate, opts = {})
        class_eval <<-END, __FILE__, __LINE__
        def #{name}(opts={})
          load_outbound_relationship(#{name.inspect}, #{predicate.inspect}, opts)
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
        end
        def #{name}_from_solr
          #{name}(:response_format => :load_from_solr)
        end
        def #{name}_query
          relationship_query("#{name}")
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
        create_bidirectional_relationship_name_methods(name,outbound_method_name)

        class_eval <<-END, __FILE__, __LINE__
        def #{name}(opts={})
          load_bidirectional("#{name}", :#{inbound_method_name}, :#{outbound_method_name}, opts)
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
        end
        def #{name}_from_solr
          #{name}(:response_format => :load_from_solr)
        end
        def #{name}_query
          relationship_query("#{name}")
        end
        END
      end

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

    end
  end
end
