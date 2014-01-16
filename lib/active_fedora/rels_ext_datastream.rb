require 'uri'
require 'rdf/rdfxml'
require 'active_fedora/rdf_xml_writer'

module ActiveFedora
  class RelsExtDatastream < Datastream
    
    attr_accessor :model
    delegate :relationships, to: :model

    def self.default_attributes
      super.merge(:controlGroup => 'X', :mimeType => 'application/rdf+xml')
    end
    
    def changed?
      model.relationships_are_dirty? or super
    end

    def metadata?
      true
    end

    def serialize!
      self.content = to_rels_ext() if model.relationships_are_dirty?
      model.relationships_are_not_dirty!
    end
    
    # Populate a RelsExtDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [String] xml the "rdf" node 
    # @param [ActiveFedora::Datastream] tmpl the Datastream object that you are populating
    def self.from_xml(xml, tmpl) 
      if (xml.nil?)
        ### maybe put the template here?
      else
        ensure_predicates_exist!(xml)
        tmpl.model.relationships = xml
        tmpl
      end
    end

    # Creates a RELS-EXT datastream for insertion into a Fedora Object
    def to_rels_ext()
      xml = ActiveFedora::RDFXMLWriter.buffer do |writer|
        writer.prefixes.merge! ActiveFedora::Predicates.predicate_namespaces
        relationships.each_statement do |statement|
          writer << statement
        end
      end
      xml
    end

    def self.ensure_predicates_exist!(xml)
      statements = Nokogiri::XML(xml).xpath('//rdf:Description/*', 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
      predicates = statements.collect { |e| { :prefix => e.namespace.prefix, :uri => e.namespace.href, :predicate => e.name } }.uniq
      predicates.each do |pred|
        unless Predicates.predicate_mappings[pred[:uri]]
          Predicates.predicate_mappings[pred[:uri]] = {}
          if pred[:prefix] and not Predicates.predicate_namespaces.has_value?(pred[:uri])
            Predicates.predicate_namespaces[pred[:prefix].to_sym] = pred[:uri]
          end
        end
        ns = Predicates.predicate_mappings[pred[:uri]]
        unless ns.invert[pred[:predicate]]
          ns["#{pred[:prefix]}_#{pred[:predicate].underscore}".to_sym] = pred[:predicate]
        end
      end
    end

    # ** EXPERIMENTAL **
    # 
    # This is utilized by ActiveFedora::Base.load_instance_from_solr to load 
    # the relationships hash using the Solr document passed in instead of from the RELS-EXT datastream
    # in Fedora.  Utilizes solr_name method (provided by Solrizer::FieldMapper) to map solr key to
    # relationship predicate. 
    #
    # ====Warning
    #  Solr must be synchronized with RELS-EXT data in Fedora.
    def from_solr(solr_doc)
      #cycle through all possible predicates
      model.relationships_loaded = true
      Predicates.predicate_mappings.each_pair do |namespace,predicates|
        predicates.keys.each do |predicate|
          predicate_symbol = ActiveFedora::SolrService.solr_name(predicate, :symbol)
          value = (solr_doc[predicate_symbol].nil? ? solr_doc[predicate_symbol.to_s]: solr_doc[predicate_symbol]) 
          unless value.nil? 
            if value.is_a? Array
              value.each do |obj|
                model.add_relationship(predicate, obj)
              end
            else
              model.add_relationship(predicate, value)
            end
          end
        end
      end
      @load_from_solr = true
    end
  end
end
