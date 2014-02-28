require "active-fedora"
module Marpa

  # This is an example of a OmDatastream that defines a terminology for Dublin Core xml
  #
  # Some things to observe about this Class:
  # * Defines a couple of custom terms, tibetan_title and english_title, that map to dc:title with varying @language attributes
  # * Indicates which terms should be indexed as facets using :index_as=>[:facetable]
  # * Defines an xml template that is an empty dublin core xml document with three namespaces set
  # * Sets the namespace using :xmlns argument on the root term
  # * Does not override or extend to_solr, so the default solrization approach will be used (Solrizer::XML::TerminologyBasedSolrizer)
  #
  class DcDatastream < ActiveFedora::OmDatastream
  
    set_terminology do |t|
      t.root(:path=>"dc", :xmlns=>'http://purl.org/dc/terms/')
      t.tibetan_title(:path=>"title", :attributes=>{:language=>"tibetan"})
      t.english_title(:path=>"title", :attributes=>{:language=>:none})
      t.contributor(:index_as=>[:facetable])
      t.coverage
      t.creator
      t.description
      t.format
      t.identifier
      t.language(:index_as=>[:facetable])
      t.publisher
      t.relation
      t.source
      t.title
      t.abstract
      t.accessRights
      t.accrualMethod
      t.accrualPeriodicity
      t.accrualPolicy
      t.alternative
      t.audience
      t.available
      t.bibliographicCitation
      t.conformsTo
      t.contributor
      t.coverage
      t.created
      t.creator
      t.date(:index_as=>[:facetable])
      t.dateAccepted
      t.dateCopyrighted
      t.dateSubmitted
      t.description
      t.educationLevel
      t.extent
      t.format
      t.hasFormat
      t.hasPart
      t.hasVersion
      t.identifier
      t.instructionalMethod
      t.isFormatOf
      t.isPartOf
      t.isReferencedBy
      t.isReplacedBy
      t.isRequiredBy
      t.issued
      t.isVersionOf
      t.language(:index_as=>[:facetable])
      t.license
      t.mediator
      t.medium
      t.modified
      t.provenance
      t.publisher
      t.references
      t.relation
      t.replaces
      t.requires
      t.rights
      t.rightsHolder
      t.source
      t.spatial(:index_as=>[:facetable])
      t.subject(:index_as=>[:facetable])
      t.tableOfContents
      t.temporal
      t.type
      t.valid
    end
  
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.dc("xmlns"=>'http://purl.org/dc/terms/',
          "xmlns:dcterms"=>'http://purl.org/dc/terms/', 
          "xmlns:xsi"=>'http://www.w3.org/2001/XMLSchema-instance') {
        }
      end
      return builder.doc
    end

    def prefix
      "#{dsid.underscore}__"
    end

  
  end
end
