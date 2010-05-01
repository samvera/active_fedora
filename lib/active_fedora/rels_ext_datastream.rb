
module ActiveFedora
  class RelsExtDatastream < Datastream
    
    include ActiveFedora::SemanticNode
    include ActiveFedora::SolrMapper
    
    
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
          puts "adding #{r.inspect} to template"
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
  end
end
