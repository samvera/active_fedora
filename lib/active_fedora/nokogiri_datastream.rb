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

end