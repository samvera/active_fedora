require "nokogiri"
#this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
class ActiveFedora::NokogiriDatastream < ActiveFedora::Datastream
  
  include ActiveFedora::MetadataDatastreamHelper
  
  self.xml_model = Nokogiri::XML::Document
  
  attr_accessor :ng_xml
  
  #constructor, calls up to ActiveFedora::Datastream's constructor
  def initialize(attrs=nil)
    super
    @fields={}
    @ng_xml = self.class.xml_model.new()
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
  
  def to_xml(xml = REXML::Document.new("<fields />")) #:nodoc:
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
  
  # @tmpl ActiveFedora::MetadataDatastream
  # @node Nokogiri::XML::Node
  def self.from_xml(tmpl, node) # :nodoc:
    node.xpath("./foxml:datastreamVersion[last()]/foxml:xmlContent/fields/node()").each do |f|
        tmpl.send("#{f.name}_append", f.text) unless f.class == Nokogiri::XML::Text
    end
    tmpl.send(:dirty=, false)
    tmpl
  end

end