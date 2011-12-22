module ActiveFedora
  module Relationships
    extend ActiveSupport::Concern

    included do
      class_attribute  :class_relationships_desc
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
      if opts[:response_format] == :id_array  && !self.class.relationship_has_solr_filter_query?(:self,"#{name}")
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
          #raise "Duplicate use of predicate for inbound relationship name not allowed" if predicate_exists_with_different_relationship_name?(:inbound,name,predicate)
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
