module ActiveFedora
  #This class represents a Qualified Dublin Core Datastream. A special case of ActiveFedora::MetdataDatastream
  #The implementation of this class defines the terms from the Qualified Dublin Core specification.
  #This implementation features customized xml generators and deserialization routines to handle the 
  #Fedora Dublin Core XML datastreams structure.
  #
  #Fields can still be overridden if more specificity is desired (see ActiveFedora::Datastream#fields method).
  class QualifiedDublinCoreDatastream < NokogiriDatastream

    class_attribute :class_fields
    self.class_fields = []
    
    
     set_terminology do |t|
       t.root(:path=>"dc", :xmlns=>"http://purl.org/dc/terms/")
     end

    define_template :creator do |xml,name|
      xml.creator() do
        xml.text(name)
      end
    end
    
    #A frozen array of Dublincore Terms.
    DCTERMS = [
      :contributor, :coverage, :creator,  :description, :identifier, :language, :publisher, :relation,  :source, :title, :abstract, :accessRights, :accrualMethod, :accrualPeriodicity, :accrualPolicy, :alternative, :audience, :available, :bibliographicCitation, :conformsTo, :contributor, :coverage, :created, :creator, :date, :dateAccepted, :dateCopyrighted, :dateSubmitted, :description, :educationLevel, :extent, :hasFormat, :hasPart, :hasVersion, :identifier, :instructionalMethod, :isFormatOf, :isPartOf, :isReferencedBy, :isReplacedBy, :isRequiredBy, :issued, :isVersionOf, :language, :license, :mediator, :medium, :modified, :provenance, :publisher, :references, :relation, :replaces, :requires, :rights, :rightsHolder, :source, :spatial, :subject, :tableOfContents, :temporal,  :valid
    ] # removed :type, :format
    DCTERMS.freeze

    #Constructor. this class will call self.field for each DCTERM. In short, all DCTERMS fields will already exist
    #when this method returns. Each term is marked as a multivalue string.
    def initialize(digital_object=nil, dsid=nil, options={})
      super
      DCTERMS.each do |el|
        field el, :string, :multiple=>true
      end
    end

    def update_indexed_attributes(params={}, opts={})
      # if the params are just keys, not an array, make then into an array.
      new_params = {}
      params.each do |key, val|
        if key.is_a? Array
          new_params[key] = val
        else
          new_params[[key.to_sym]] = val
        end
      end
      super(new_params, opts)
    end
    def om_term_options(datatype)
      {:xmlns=>"http://purl.org/dc/terms/", :namespace_prefix => "dcterms"}
    end
    protected :om_term_options

    def self.xml_template
       Nokogiri::XML::Document.parse("<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'/>")
    end

    def to_solr(solr_doc = Hash.new) # :nodoc:
      @fields.each do |field_key, field_info|
        things = send(field_key)
        if things 
          field_symbol = ActiveFedora::SolrService.solr_name(field_key, field_info[:type])
          things.val.each do |val|    
            ::Solrizer::Extractor.insert_solr_field_value(solr_doc, field_symbol, val )         
          end
        end
      end
      return solr_doc
    end

  end
end
