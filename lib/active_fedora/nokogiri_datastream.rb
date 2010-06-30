require "nokogiri"
require  "om"
#this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
class ActiveFedora::NokogiriDatastream < ActiveFedora::Datastream
    
  include ActiveFedora::MetadataDatastreamHelper
  include OM::XML
  extend(OM::XML::Container::ClassMethods)
  
  attr_accessor :ng_xml
  
  #constructor, calls up to ActiveFedora::Datastream's constructor
  def initialize(attrs=nil)
    super
    @fields={}
    self.class.from_xml(blob, self)
  end
  
  
  def to_xml(xml = self.ng_xml)
    ng_xml = self.ng_xml
    if ng_xml.root.nil? && self.class.respond_to?(:root_property_ref) && !self.class.root_property_ref.nil?
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
  
  def to_solr(solr_doc = Solr::Document.new) # :nodoc:
    
    unless self.class.accessors.nil?
      self.class.accessors.each_pair do |accessor_name,accessor_info|
        solrize_accessor(accessor_name, accessor_info, :solr_doc=>solr_doc)
      end
    end

    return solr_doc
  end
  
  def solrize_accessor(accessor_name, accessor_info, opts={})
    solr_doc = opts.fetch(:solr_doc, Solr::Document.new)
    parents = opts.fetch(:parents, [])
    
    accessor_pointer = parents+[accessor_name]
  
    if accessor_info.nil?
      accessor_info = self.class.accessor_info(accessor_pointer)
      if accessor_info.nil?
        raise "No accessor is defined for #{accessor_info.select}"
      end
    end
  
    # prep children hash
    child_accessors = accessor_info.fetch(:children, {})
    xpath = self.class.accessor_xpath(*accessor_pointer)
    nodeset = lookup(xpath)
    
    nodeset.each do |node|
      # create solr fields
      solrize_node(node, accessor_pointer, solr_doc)
      child_accessors.each_pair do |child_accessor_name, child_accessor_info|
        solrize_accessor(child_accessor_name, child_accessor_info, opts={:solr_doc=>solr_doc, :parents=>parents+[{accessor_name=>nodeset.index(node)}] })
      end
    end
    
  end
  
  def solrize_node(node, accessor_pointer, solr_doc = Solr::Document.new)
    generic_field_name_base = self.class.accessor_generic_name(*accessor_pointer)
    generic_field_name = generate_solr_symbol(generic_field_name_base, :text)
    
    solr_doc << Solr::Field.new(generic_field_name => node.text)
    
    if accessor_pointer.length > 1
      hierarchical_field_name_base = self.class.accessor_hierarchical_name(*accessor_pointer)
      hierarchical_field_name = generate_solr_symbol(hierarchical_field_name_base, :text)
      solr_doc << Solr::Field.new(hierarchical_field_name => node.text)
    end
  end
  
  def update_indexed_attributes(params={}, opts={})    
    # remove any fields from params that this datastream doesn't recognize    
    params.delete_if do |field_key,new_values| 
      if field_key.kind_of?(String)
        true
      else
        self.class.accessor_xpath(*OM.destringify(field_key) ).nil?
      end
    end
    result = update_properties( params )
    return result
  end
  
  def get_values(field_key,default=[])
    property_values(*field_key)
  end

end