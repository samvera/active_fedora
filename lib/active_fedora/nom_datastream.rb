require  "nom"

module ActiveFedora
  class NomDatastream < File

    include Datastreams::NokogiriDatastreams

    def self.set_terminology(options = {}, &block)
      @terminology_options = options || {}
      @terminology = block
    end

    def self.terminology_options
      @terminology_options
    end

    def self.terminology
      @terminology
    end

    def self.decorate_ng_xml(xml)
      xml.set_terminology terminology_options, &terminology
      xml.nom!
      xml
    end

    def serialize!
       self.content = @ng_xml.to_s if @ng_xml
    end

    def to_solr
      solr_doc = {}

      ng_xml.terminology.flatten.select { |x| x.options[:index] }.each do |term|
        term.values.each do |v|
          Array(term.options[:index]).each do |index_as|
            solr_doc[index_as] ||= []
            if v.is_a? Nokogiri::XML::Node
              solr_doc[index_as] << v.text
            else
              solr_doc[index_as] << v
            end
          end
        end
      end

      solr_doc
    end

    def method_missing method, *args, &block
      if ng_xml.respond_to? method
        ng_xml.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to? *args
      super || self.class.terminology.respond_to?(*args)
    end

    protected

    def default_mime_type
      'text/xml'
    end
  end
end

