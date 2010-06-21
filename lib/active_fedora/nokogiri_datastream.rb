require "nokogiri"
require  "om"
#this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
class ActiveFedora::NokogiriDatastream < ActiveFedora::Datastream
    
  include ActiveFedora::MetadataDatastreamHelper
  include OM::XML
    
  attr_accessor :ng_xml
  
  #constructor, calls up to ActiveFedora::Datastream's constructor
  def initialize(attrs=nil)
    super
    @fields={}
    self.class.from_xml(blob, self)
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

end