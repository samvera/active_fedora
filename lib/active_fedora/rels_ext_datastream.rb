require 'active_support/core_ext/class/inheritable_attributes'
require 'solrizer/field_name_mapper'
require 'uri'
require 'rdf/rdfxml'
require 'rdf'

module ActiveFedora
  class RelsExtDatastream < Datastream
    
    include ActiveFedora::SemanticNode
    include Solrizer::FieldNameMapper
    
    
    # def initialize(digital_object, dsid, exists_in_fedora=nil)
    #   super(digital_object, 'RELS-EXT')
    # end

    def changed?
      relationships_are_dirty || super
    end

    def serialize!
      self.content = to_rels_ext(self.pid) if relationships_are_dirty
      relationships_are_dirty = false
    end
    

    def to_xml(fields_xml) 
      to_rels_ext(self.pid) 
    end
      
    # # Populate a RelsExtDatastream object based on the "datastream" content 
    # # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # # @param [String] the "rdf" node 
    # def self.from_xml(xml, tmpl) 
    #   if (xml.nil?)
    #     ### maybe put the template here?
    #   else
    #     node = Nokogiri::XML::Document.parse(xml)
    #     node.xpath("rdf:RDF/rdf:Description/*", {"rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#"}).each do |f|
    #         if f.namespace
    #           ns_mapping = self.predicate_mappings[f.namespace.href]
    #           predicate = ns_mapping ?  ns_mapping.invert[f.name] : nil
    #           predicate = "#{f.namespace.prefix}_#{f.name}" if predicate.nil?
    #         else
    #           logger.warn "You have a predicate without a namespace #{f.name}. Verify your rels-ext is correct."
    #           predicate = "#{f.name}"
    #         end
    #         is_obj = f["resource"]
    #         object = is_obj ? f["resource"] : f.inner_text
    #         r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>object, :is_literal=>!is_obj)
    #         tmpl.add_relationship(r)
    #     end
    #     tmpl.relationships_are_dirty = false
    #     #tmpl.send(:dirty=, false)
    #     tmpl
    #   end
    # end

    # Populate a RelsExtDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def self.from_xml(xml, tmpl) 
      if (xml.nil?)
        ### maybe put the template here?
      else
        RDF::RDFXML::Reader.new(xml) do |reader|
          reader.each_statement do |statement|
            literal = statement.object.kind_of?(RDF::Literal)
            predicate = statement.predicate.to_str.gsub(/^[^#]+#/, '').underscore.to_sym
            r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>literal ? statement.object.value : statement.object.to_str, :is_literal=>literal)
            tmpl.add_relationship(r)
          end
        end
        tmpl.relationships_are_dirty = false
        tmpl
      end
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

      vocabularies = {"info:fedora/fedora-system:def/relations-external#" =>  RDF::Vocabulary.new("info:fedora/fedora-system:def/relations-external#"),
        "info:fedora/fedora-system:def/model#" =>  RDF::Vocabulary.new("info:fedora/fedora-system:def/model#")}
                  
      graph = RDF::Graph.new
      subject =  RDF::URI.new("info:fedora/#{pid}")
      # Iterate through the hash of predicates, adding an element to the RELS-EXT for each "object" in the predicate's corresponding array.
      # puts ""
      # puts "Iterating through a(n) #{self.class}"
      # puts "=> whose relationships are #{self.relationships.inspect}"
      # puts "=> and whose outbound relationships are #{self.outbound_relationships.inspect}"
      self.outbound_relationships.each do |predicate, targets_array|
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
        graph_predicate = vocabularies[xmlns][rel_predicate] 
        targets_array.each do |target|
          literal = URI.parse(target).scheme.nil?
          object = literal ? RDF::Literal.new(target) : RDF::URI.new(target)
          stm = RDF::Statement.new(subject, graph_predicate, object)
          graph.insert stm
        end
      end

      xml = RDF::RDFXML::Writer.buffer do |writer|
        graph.each_statement do |statement|
          writer << statement
        end
      end

      xml

    end

    
    # Serialize the datastream's RDF relationships to solr
    # @param [Hash] solr_doc @deafult an empty Hash
    def to_solr(solr_doc = Hash.new)
      self.relationships.each_pair do |subject, predicates|
        if subject == :self || subject == "info:fedora/#{self.pid}"
          predicates.each_pair do |predicate, values|
            values.each do |val|
              ::Solrizer::Extractor.insert_solr_field_value(solr_doc, solr_name(predicate, :symbol), val )
            end
          end
        end
      end
      return solr_doc
    end
    
    # ** EXPERIMENTAL **
    # 
    # This is utilized by ActiveFedora::Base.load_instance_from_solr to load 
    # the relationships hash using the Solr document passed in instead of from the RELS-EXT datastream
    # in Fedora.  Utilizes solr_name method (provided by Solrizer::FieldNameMapper) to map solr key to
    # relationship predicate. 
    #
    # ====Warning
    #  Solr must be synchronized with RELS-EXT data in Fedora.
    def from_solr(solr_doc)
      #cycle through all possible predicates
      self.class.predicate_mappings[self.class.default_predicate_namespace].keys.each do |predicate|
        predicate_symbol = ActiveFedora::SolrService.solr_name(predicate, :symbol)
        value = (solr_doc[predicate_symbol].nil? ? solr_doc[predicate_symbol.to_s]: solr_doc[predicate_symbol]) 
        unless value.nil? 
          if value.is_a? Array
            value.each do |obj|
              o_uri = URI.parse(obj)
              literal = o_uri.scheme.nil?
              r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>obj, :is_literal=>literal)
              add_relationship(r)
            end
          else
            o_uri = URI.parse(value)
            literal = o_uri.scheme.nil?
            r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>value, :is_literal=>literal)
            add_relationship(r)
          end
        end
      end
      @load_from_solr = true
    end
  end
end
