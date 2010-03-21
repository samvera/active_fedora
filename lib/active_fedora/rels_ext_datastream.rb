
module ActiveFedora
  class RelsExtDatastream < Datastream
    
    include ActiveFedora::SemanticNode
    
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
    
    # Expects a RelsExtDatastream and a REXML Element as inputs.
    def self.from_xml(tmpl, el) 
      #puts el.elements["./foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/"]
      el.elements.each("./foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/*") do |f|
          #puts "Element" + f.inspect
          r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>ActiveFedora::SemanticNode::PREDICATE_MAPPINGS.invert[f.name], :object=>f.attributes["rdf:resource"])
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
              solr_doc << Solr::Field.new("#{predicate}_s" => val)
            end
          end
        end
      end
      return solr_doc
    end
  end
end
