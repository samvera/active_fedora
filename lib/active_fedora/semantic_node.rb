module ActiveFedora
  module SemanticNode 
    include MediaShelfClassLevelInheritableAttributes
    ms_inheritable_attributes  :class_relationships, :internal_uri, :class_named_relationships_desc
    
    attr_accessor :internal_uri, :named_relationship_desc, :relationships_are_dirty, :load_from_solr
    
    PREDICATE_MAPPINGS = Hash[:is_member_of => "isMemberOf",
                          :has_member => "hasMember",
                          :is_part_of => "isPartOf",
                          :has_part => "hasPart",
                          :is_member_of_collection => "isMemberOfCollection",
                          :has_collection_member => "hasCollectionMember",
                          :is_constituent_of => "isConstituentOf",
                          :has_constituent => "hasConstituent",
                          :is_subset_of => "isSubsetOf",
                          :has_subset => "hasSubset",
                          :is_derivation_of => "isDerivationOf",
                          :has_derivation => "hasDerivation",
                          :is_dependent_of => "isDependentOf",
                          :has_dependent => "hasDependent",
                          :is_description_of => "isDescriptionOf",
                          :has_description => "hasDescription",
                          :is_metadata_for => "isMetadataFor",
                          :has_metadata => "hasMetadata",
                          :is_annotation_of => "isAnnotationOf",
                          :has_annotation => "hasAnnotation",
                          :has_equivalent => "hasEquivalent",
                          :conforms_to => "conformsTo",
                          :has_model => "hasModel"]
    PREDICATE_MAPPINGS.freeze
    
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
    
    def register_named_subject(subject)
      self.class.register_named_subject(subject)
    end
  
    def register_named_relationship(subject, name, predicate, opts)
      self.class.register_named_relationship(subject, name, predicate, opts)
    end
    
    def remove_relationship(relationship)
      @relationships_are_dirty = true
      unregister_triple(relationship.subject, relationship.predicate, relationship.object)
    end

    def unregister_triple(subject, predicate, object)
      if relationship_exists?(subject, predicate, object)
        relationships[subject][predicate].delete_if {|curObj| curObj == object}
        relationships[subject].delete(predicate) if relationships[subject][predicate].nil? || relationships[subject][predicate].empty? 
      else
        return false
      end     
    end
    
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
    
    def outbound_named_relationship_predicates
      named_relationship_predicates.has_key?(:self) ? named_relationship_predicates[:self] : {}
    end

    def inbound_named_relationship_predicates
      named_relationship_predicates.has_key?(:inbound) ? named_relationship_predicates[:inbound] : {}
    end
    
    def named_relationship_predicates
      @named_relationship_predicates ||= named_relationship_predicates_from_class
    end
    
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
    
    def relationship_names
      names = []
      named_relationships_desc.each_key do |subject|
            names = names.concat(named_relationships_desc[subject].keys)
        end
        names
    end

    def inbound_relationship_names
        named_relationships_desc.has_key?(:inbound) ? named_relationships_desc[:inbound].keys : []
    end

    def outbound_relationship_names
        named_relationships_desc.has_key?(:self) ? named_relationships_desc[:self].keys : []
    end
    
    def named_outbound_relationships
        named_relationships_desc.has_key?(:self) ? named_relationships[:self] : {}
    end
  
    def is_named_relationship?(name, outbound_only=true)
      if outbound_only
        outbound_relationship_names.include?(name)
      else
        (outbound_relationship_names.include?(name)||inbound_relationship_names.include?(name))
      end
    end
    
    def named_relationships_desc
      @named_relationships_desc ||= named_relationships_desc_from_class
    end
    
    def named_relationships_desc_from_class
      self.class.named_relationships_desc
    end
    
    def named_relationship_type(name)
      if is_named_relationship?(name,true)
        subject = outbound_relationship_names.include?(name)? :self : :inbound
        if named_relationships_desc[subject][name].has_key?(:type)
          return class_from_name(named_relationships_desc[subject][name][:type])
        end
      end
      return nil  
    end

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
    
    def remove_named_relationship(name, object)
      if is_named_relationship?(name,true)
        remove_relationship(outbound_named_relationship_predicates[name],object)
      else
        return false
      end
    end
    
    def assert_kind_of_model(name, object, model_class)
      raise "Assertion failure: #{name}: #{object.pid} does not have model #{model_class}, it has model #{relationships[:self][:has_model]}" unless object.kind_of_model?(model_class)
    end
    
    ############################################################################
    # Checks that this class is either of type passed in or a child of that type.
    # It also makes sure that this object was created as the same type by
    # checking that hasmodel and the class match.  This would not match
    # if someone called load_instance on a Fedora Object that was created
    # via a different model class than the one that was recreated from Fedora.
    # This is a side-effect of ActiveFedora's behavior that will try to create
    # the object type specified with the pid given whether it is actually that
    # object type or not.
    #
    # If hasmodel does not match than this will return false indicated it does not
    # have the correct model.
    ############################################################################
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
    # @pid
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
          else
            xmlns="info:fedora/fedora-system:def/relations-external#"
          end
          # puts ". #{predicate} #{target} #{xmlns}"
          xml.root.elements["rdf:Description"].add_element(self.class.predicate_lookup(predicate), {"xmlns" => "#{xmlns}", "rdf:resource"=>target})
        end
      end
      xml.to_s
    end
    
    module ClassMethods
      
    # Anticipates usage of a relationship in classes that include this module
    # Creates a key in the @relationships array for the predicate provided.  Assumes
    # :self as the subject of the relationship unless :inbound => true, in which case the 
    # predicate is registered under @relationships[:inbound][#{predicate}]
    #
    # TODO:
    # Custom Methods:
    # A custom finder method will be appended based on the relationship name.
    # ie. 
    # class Foo
    #   relationship "container", :is_member_of  
    # end
    # foo = Foo.new
    # foo.parts
    #
    # Special Predicate Short Hand:
    # These symbols map to the uris of corresponding Fedora RDF predicates
    # :is_member_of, :has_member, :is_part_of, :has_part  
      def has_relationship(name, predicate, opts = {})
        opts = {:singular => nil, :inbound => false}.merge(opts)
        if opts[:inbound] == true
          raise "Duplicate use of predicate for named inbound relationship not allowed" if named_predicate_exists_with_different_name?(:inbound,name,predicate)
          register_named_relationship(:inbound, name, predicate, opts)
          register_predicate(:inbound, predicate)
          create_inbound_relationship_finders(name, predicate, opts)
        else
          raise "Duplicate use of predicate for named outbound relationship not allowed" if named_predicate_exists_with_different_name?(:self,name,predicate)
          register_named_relationship(:self, name, predicate, opts)
          register_predicate(:self, predicate)
          create_named_relationship_methods(name)
          create_outbound_relationship_finders(name, predicate, opts)
        end
      end
      
      #allow duplicate has_relationship calls with same name and predicate
      def named_predicate_exists_with_different_name?(subject,name,predicate)
        if named_relationships_desc.has_key?(subject)
          named_relationships_desc[subject].each_pair do |existing_name, args|
            return true if !args[:predicate].nil? && args[:predicate] == predicate && existing_name != name 
          end
        end
        return false
      end
        
      # named relationships desc are tracked as a hash of structure {name => args}}
      def named_relationships_desc
        @class_named_relationships_desc ||= Hash[:self => {}]
      end
        
      def register_named_subject(subject)
        unless named_relationships_desc.has_key?(subject) 
          named_relationships_desc[subject] = {} 
        end
      end
  
      def register_named_relationship(subject, name, predicate, opts)
        register_named_subject(subject)
        opts.merge!({:predicate=>predicate})
        named_relationships_desc[subject][name] = opts
      end
        
      def create_named_relationship_methods(name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_named_relationship(name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_named_relationship(name,object)}
      end 
    
      def create_inbound_relationship_finders(name, predicate, opts = {})
        class_eval <<-END
        def #{name}(opts={})
          escaped_uri = self.internal_uri.gsub(/(:)/, '\\:')
          solr_result = SolrService.instance.conn.query("#{predicate}_s:\#{escaped_uri}")
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
        END
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
          if opts[:response_format] == :id_array
            return id_array
          else
            query = ActiveFedora::SolrService.construct_query_for_pids(id_array)
            solr_result = SolrService.instance.conn.query(query)
            if opts[:response_format] == :solr
              return solr_result
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
        END
      end
    
      # relationships are tracked as a hash of structure {subject => {predicate => [object]}}
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
      # @pid
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
    
      # If predicate is a symbol, looks up the predicate in the PREDICATE_MAPPINGS
      # If predicate is not a Symbol, returns the predicate untouched
      # @throws UnregisteredPredicateError if the predicate is a symbol but is not found in the PREDICATE_MAPPINGS
      def predicate_lookup(predicate)
        if predicate.class == Symbol 
          if PREDICATE_MAPPINGS.has_key?(predicate)
            return PREDICATE_MAPPINGS[predicate]
          else
            throw UnregisteredPredicateError
          end
        end
        return predicate
      end
    end
  end
end
