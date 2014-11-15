module ActiveFedora
  #This class represents a Qualified Dublin Core Datastream. A special case of ActiveFedora::OmDatastream
  #The implementation of this class defines the terms from the Qualified Dublin Core specification.
  #This implementation features customized xml generators and deserialization routines to handle the
  #Fedora Dublin Core XML datastreams structure.
  #
  #Fields can still be overridden if more specificity is desired (see ActiveFedora::File#fields method).
  class QualifiedDublinCoreDatastream < OmDatastream

    attr_accessor :fields
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
               :abstract,
               :accessRights,
               :accrualMethod,
               :accrualPeriodicity,
               :accrualPolicy,
               :alternative,
               :audience,
               :available,
               :bibliographicCitation,
               :conformsTo,
               :contributor,
               :coverage,
               :created,
               :creator,
               :date,
               :dateAccepted,
               :dateCopyrighted,
               :dateSubmitted,
               :description,
               :educationLevel,
               :extent,
               :hasFormat,
               :hasPart,
               :hasVersion,
               :identifier,
               :instructionalMethod,
               :isFormatOf,
               :isPartOf,
               :isReferencedBy,
               :isReplacedBy,
               :isRequiredBy,
               :isVersionOf,
               :issued,
               :language,
               :license,
               :mediator,
               :medium,
               :modified,
               :provenance,
               :publisher,
               :references,
               :relation,
               :replaces,
               :requires,
               :rights,
               :rightsHolder,
               :source,
               :spatial,
               :subject,
               :tableOfContents,
               :temporal,
               :title,
               :type,
               :valid
              ] # removed :format
    DCTERMS.freeze

    #Constructor. this class will call self.field for each DCTERM. In short, all DCTERMS fields will already exist
    #when this method returns. Each term is marked as a multivalue string.
    def initialize(digital_object=nil, dsid=nil, options={})
      super
      self.fields={}
      DCTERMS.each do |el|
        field el, :string, :multiple=>true
      end
    end

    # This method generates the various accessor and mutator methods on self for the datastream metadata attributes.
    # each field will have the 2 magic methods:
    #   name=(arg) 
    #   name 
    #
    #
    # Calling any of the generated methods marks self as dirty.
    #
    # 'tupe' is a datatype, currently :string, :text and :date are supported.
    #
    # opts is an options hash, which  will affect the generation of the xml representation of this datastream.
    #
    # Currently supported modifiers: 
    # For +QualifiedDublinCorDatastreams+:
    #   :element_attrs =>{:foo=>:bar} -  hash of xml element attributes
    #   :xml_node => :nodename  - The xml node to be used to represent this object (in dcterms namespace)
    #   :encoding=>foo, or encodings_scheme  - causes an xsi:type attribute to be set to 'foo'
    #   :multiple=>true -  mark this field as a multivalue field (on by default)
    #
    #
    #There is quite a good example of this class in use in spec/examples/oral_history.rb
    #
    #!! Careful: If you declare two fields that correspond to the same xml node without any qualifiers to differentiate them,
    #you will end up replicating the values in the underlying datastream, resulting in mysterious dubling, quadrupling, etc.
    #whenever you edit the field's values.
    def field(name, tupe=nil, opts={})
      fields ||= {}
      @fields[name.to_s.to_sym]={:type=>tupe, :values=>[]}.merge(opts)
      # add term to template
      self.class.class_fields << name.to_s
      # add term to terminology
      unless self.class.terminology.has_term?(name.to_sym)
        om_term_opts = {:xmlns=>"http://purl.org/dc/terms/", :namespace_prefix => "dcterms", :path => opts[:path]}
        term = OM::XML::Term.new(name.to_sym, om_term_opts, self.class.terminology)
        self.class.terminology.add_term(term)
        term.generate_xpath_queries!
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


    def self.xml_template
       Nokogiri::XML::Document.parse("<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'/>")
    end

    def to_solr(solr_doc = Hash.new, opts = {}) # :nodoc:
      @fields.each do |field_key, field_info|
        things = send(field_key)
        if things
          field_symbol = ActiveFedora::SolrQueryBuilder.solr_name(field_key, type: field_info[:type])
          things.val.each do |val|
            ::Solrizer::Extractor.insert_solr_field_value(solr_doc, field_symbol, val )
          end
        end
      end
      return solr_doc
    end

  end
end
