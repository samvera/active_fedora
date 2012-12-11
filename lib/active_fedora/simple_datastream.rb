module ActiveFedora
  #This class represents a simple xml datastream. 
  class SimpleDatastream < NokogiriDatastream

    class_attribute :class_fields
    self.class_fields = []
    
    
     set_terminology do |t|
       t.root(:path=>"fields", :xmlns=>nil)
     end

    define_template :creator do |xml,name|
      xml.creator() do
        xml.text(name)
      end
    end
    

    def om_term_options(datatype)
      {:type=>datatype}
    end
    protected :om_term_options

    def self.xml_template
       Nokogiri::XML::Document.parse("<fields/>")
    end

    def to_solr(solr_doc = Hash.new) # :nodoc:
      @fields.each do |field_key, field_info|
        next if field_key == :location ## FIXME HYDRA-825
        things = send(field_key)
        if things 
          field_symbol = ActiveFedora::SolrService.solr_name(field_key, field_info[:type])
          things.val.each do |val|    
            ::Solrizer::Extractor.insert_solr_field_value(solr_doc, field_symbol, val.to_s )         
          end
        end
      end
      return solr_doc
    end

  end
end
