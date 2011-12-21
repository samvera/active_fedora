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


    def ids_for_outbound(predicate)
      (object_relations[predicate] || []).map do |o|
        o = o.to_s if o.kind_of? RDF::Literal
        o.kind_of?(String) ? o.gsub("info:fedora/", "") : o.pid
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
    
    module ClassMethods
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

      
    end
  end


end
