require "nokogiri"
require  "om"
require "solrizer/xml"

#this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
class ActiveFedora::NokogiriDatastream < ActiveFedora::Datastream
    
  include ActiveFedora::MetadataDatastreamHelper
  include OM::XML::Document
  include Solrizer::XML::TerminologyBasedSolrizer # this adds support for calling .to_solr
  
  # extend(OM::XML::Container::ClassMethods)
  
  attr_accessor :ng_xml
  
  #constructor, calls up to ActiveFedora::Datastream's constructor
  def initialize(attrs=nil)
    super
    @fields={}
    self.class.from_xml(blob, self)
  end

  # @xml String, File or Nokogiri::XML::Node
  # @tmpl ActiveFedora::MetadataDatastream
  # Careful! If you call this from a constructor, be sure to provide something 'ie. self' as the @tmpl. Otherwise, you will get an infinite loop!
  def self.from_xml(xml, tmpl=self.new) # :nodoc:
    if xml.nil?
      tmpl.ng_xml = self.xml_template
    elsif xml.kind_of? Nokogiri::XML::Node || xml.kind_of?(Nokogiri::XML::Document)
      tmpl.ng_xml = xml
    else
      tmpl.ng_xml = Nokogiri::XML::Document.parse(xml)
    end    
    tmpl.send(:dirty=, false)
    return tmpl
  end
  
  def self.xml_template
    Nokogiri::XML::Document.parse("<xml/>")
  end
  
  # class << self
  #   from_xml_original = self.instance_method(:from_xml)
  #   
  #   define_method(:from_xml, xml, tmpl=self.new) do
  #     from_xml_original.bind(self).call(xml, tmpl)
  #     tmpl.send(:dirty=, false)
  #   end
  #   
  #   # def from_xml_custom(xml, tmpl=self.new)
  #   #   from_xml_original(xml, tmpl)
  #   #   tmpl.send(:dirty=, false)
  #   # end
  #   # 
  #   # alias_method :from_xml_original, :from_xml 
  #   # alias_method :from_xml, :from_xml_custom
  # end
  
  
  def to_xml(xml = self.ng_xml)
    ng_xml = self.ng_xml
    if ng_xml.respond_to?(:root) && ng_xml.root.nil? && self.class.respond_to?(:root_property_ref) && !self.class.root_property_ref.nil?
      ng_xml = self.class.generate(self.class.root_property_ref, "")
      if xml.root.nil?
        xml = ng_xml
      end
    end

    unless xml == ng_xml || ng_xml.root.nil?
      if xml.kind_of?(Nokogiri::XML::Document)
          xml.root.add_child(ng_xml.root)
      elsif xml.kind_of?(Nokogiri::XML::Node)
          xml.add_child(ng_xml.root)
      else
          raise "You can only pass instances of Nokogiri::XML::Node into this method.  You passed in #{xml}"
      end
    end
    
    return xml.to_xml {|config| config.no_declaration}
  end
  
  def update_indexed_attributes(params={}, opts={})    
    if self.class.terminology.nil?
      raise "No terminology is set for this NokogiriDatastream class.  Cannot perform update_indexed_attributes"
    end
    # remove any fields from params that this datastream doesn't recognize    
    params.delete_if do |term_pointer,new_values| 
      if term_pointer.kind_of?(String)
        true
      else
        !self.class.terminology.has_term?(*OM.destringify(term_pointer))
        # self.class.accessor_xpath(*OM.destringify(field_key) ).nil?
      end
    end
    result = {}
    unless params.empty?
      result = update_values( params )
      self.dirty = true
    end
    return result
  end
  
  def get_values(field_key,default=[])
    term_values(*field_key)
  end

end