require 'solrizer/field_name_mapper'

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
    
    # @tmpl ActiveFedora::MetadataDatastream
    # @node Nokogiri::XML::Node
    def self.from_xml(tmpl, node) 
      # node.xpath("./foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/*").each do |f|
      node.xpath("./foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/*", {"rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "foxml"=>"info:fedora/fedora-system:def/foxml#"}).each do |f|
          r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>ActiveFedora::SemanticNode::PREDICATE_MAPPINGS.invert[f.name], :object=>f["resource"])
          tmpl.add_relationship(r)
      end
      tmpl.send(:dirty=, false)
      tmpl
    end
    
    def to_solr(solr_doc = Solr::Document.new)
      self.relationships.each_pair do |subject, predicates|
        if subject == :self || subject == "info:fedora/#{self.pid}"
          predicates.each_pair do |predicate, values|
            values.each do |val|
              solr_doc << Solr::Field.new(solr_name(predicate, :symbol) => val)
            end
          end
        end
      end
      return solr_doc
    end
    
    def from_solr(solr_doc)
      #cycle through all possible predicates
      PREDICATE_MAPPINGS.keys.each do |predicate|
        predicate_symbol = Solrizer::FieldNameMapper.solr_name(predicate, :symbol)
        value = (solr_doc[predicate_symbol].nil? ? solr_doc[predicate_symbol.to_s]: solr_doc[predicate_symbol]) 
        unless value.nil? 
          if value.is_a? Array
            value.each do |obj|
              r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>obj)
              add_relationship(r)
            end
          else
            r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>value)
            add_relationship(r)
          end
        end
      end
      @load_from_solr = true
    end
  end
end
