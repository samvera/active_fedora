module ActiveFedora
  module NamedRelationshipHelper
    attr_accessor :named_relationship_desc

    def self.included(klass)
      klass.extend(ClassMethods)
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
      def register_named_relationship(subject, name, predicate, opts={})
        register_named_subject(subject)
        opts.merge!({:predicate=>predicate})
        named_relationships_desc[subject][name] = opts
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

      def relationship_has_query_params?(subject, relationship_name)
        named_relationships_desc.has_key?(subject) && named_relationships_desc[subject].has_key?(relationship_name) && named_relationships_desc[subject][relationship_name].has_key?(:query_params)
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
    end
  end
end
