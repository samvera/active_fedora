module ActiveFedora
  module SemanticNode 
    include MediaShelfClassLevelInheritableAttributes
    ms_inheritable_attributes  :class_relationships, :internal_uri
    
    attr_accessor :internal_uri, :relationships
    
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
    
    def outbound_relationships()
      if !internal_uri.nil? && !relationships[internal_uri].nil?
        return relationships[:self].merge(relationships[internal_uri]) 
      else
        return relationships[:self]
      end
    end
    
    def relationships
      @relationships ||= relationships_from_class
    end
    
    def relationships_from_class
      rels = {}
      self.class.relationships.each_pair do |subj, pred|
        rels[subj] = {}
        pred.each_key do |pred_key|
          rels[subj][pred_key] = []
        end
      end
      #puts "rels from class: #{rels.inspect}"
      return rels
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
          # puts ". #{predicate} #{target}"
          xml.root.elements["rdf:Description"].add_element(self.class.predicate_lookup(predicate), {"xmlns" => "info:fedora/fedora-system:def/relations-external#", "rdf:resource"=>target})
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
        opts[:inbound] == true ? register_predicate(:inbound, predicate) : register_predicate(:self, predicate) 
      
        if opts[:inbound] == true
          create_inbound_relationship_finders(name, predicate, opts)
        else        
          create_outbound_relationship_finders(name, predicate, opts)
        end
      
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
            else
              return ActiveFedora::SolrService.reify_solr_results(solr_result)
            end
          end
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
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
            else
              return ActiveFedora::SolrService.reify_solr_results(solr_result)
            end
          end
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
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
