require 'solrizer/field_name_mapper'
require 'uri'

module ActiveFedora
  class RelsExtDatastream < Datastream
    
    include ActiveFedora::SemanticNode
    include Solrizer::FieldNameMapper
    
    
    def initialize(attrs=nil)
      super
      self.dsid = "RELS-EXT"
    end
    
    def save
      if @dirty == true
        self.content = to_rels_ext(self.pid)
      end
      super
    end
      
    def pid=(pid)
      super
      self.blob = <<-EOL
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="info:fedora/#{pid}">
        </rdf:Description>
      </rdf:RDF>
      EOL
    end
    
    # Populate a RelsExtDatastream object based on the "datastream" node from a FOXML file
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [Nokogiri::XML::Node] node the "foxml:datastream" node from a FOXML file
    def self.from_xml(tmpl, node) 
      # node.xpath("./foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/*").each do |f|
      node.xpath("./foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/*", {"rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "foxml"=>"info:fedora/fedora-system:def/foxml#"}).each do |f|
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
      tmpl.send(:dirty=, false)
      tmpl
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
