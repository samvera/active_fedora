#this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
module ActiveFedora::MetadataDatastreamHelper 
  
  attr_accessor :fields
  
  module ClassMethods
    
    attr_accessor :xml_model
    
    #get the Class's field list
    def fields
      @@classFields
    end
    
    # @tmpl ActiveFedora::MetadataDatastream
    # @node Nokogiri::XML::Node
    def from_xml(tmpl, node) # :nodoc:
      node.xpath("./foxml:datastreamVersion[last()]/foxml:xmlContent/fields/node()").each do |f|
          tmpl.send("#{f.name}_append", f.text) unless f.class == Nokogiri::XML::Text
      end
      tmpl.send(:dirty=, false)
      tmpl
    end
    
  end
  
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.send(:include, ActiveFedora::SolrMapper)
  end
  
  #constructor, calls up to ActiveFedora::Datastream's constructor
  def initialize(attrs=nil)
    super
    @fields={}
  end
  
  # sets the blob, which in this case is the xml version of self, then calls ActiveFedora::Datastream.save
  def save
    self.set_blob_for_save
    super
  end
  
  def set_blob_for_save # :nodoc:
    self.blob = self.to_xml
  end

  def to_solr(solr_doc = Solr::Document.new) # :nodoc:
    fields.each do |field_key, field_info|
      if field_info.has_key?(:values) && !field_info[:values].nil?
        field_symbol = generate_solr_symbol(field_key, field_info[:type])
        field_info[:values].each do |val|             
          solr_doc << Solr::Field.new(field_symbol => val)
        end
      end
    end

    return solr_doc
  end
  
  def to_xml(xml = Nokogiri::XML::Document.new("<fields />")) #:nodoc:
    fields.each_pair do |field,field_info|
      el = REXML::Element.new("#{field.to_s}")
        if field_info[:element_attrs]
          field_info[:element_attrs].each{|k,v| el.add_attribute(k.to_s, v.to_s)}
        end
      field_info[:values].each do |val|
        el = el.clone
        el.text = val.to_s
        if xml.class == REXML::Document
          xml.root.elements.add(el)
        else
          xml.add(el)
        end
      end
    end
    return xml.to_s
  end
  

  protected

  def generate_solr_symbol(field_name, field_type) # :nodoc:
    solr_name(field_name, field_type)
  end

end