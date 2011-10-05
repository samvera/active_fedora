require 'active_support/core_ext/class/inheritable_attributes'
require 'solrizer/field_name_mapper'
require 'uri'

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
      
    # Populate a RelsExtDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def self.from_xml(xml, tmpl) 
      if (xml.nil?)
        ### maybe put the template here?
      else
        node = Nokogiri::XML::Document.parse(xml)
        node.xpath("rdf:RDF/rdf:Description/*", {"rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#"}).each do |f|
            if f.namespace
              ns_mapping = self.predicate_mappings[f.namespace.href]
              predicate = ns_mapping ?  ns_mapping.invert[f.name] : nil
              predicate = "#{f.namespace.prefix}_#{f.name}" if predicate.nil?
            else
              logger.warn "You have a predicate without a namespace #{f.name}. Verify your rels-ext is correct."
              predicate = "#{f.name}"
            end
            is_obj = f["resource"]
            object = is_obj ? f["resource"] : f.inner_text
            r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>object, :is_literal=>!is_obj)
            tmpl.add_relationship(r)
        end
        tmpl.relationships_are_dirty = false
        #tmpl.send(:dirty=, false)
        tmpl
      end
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
