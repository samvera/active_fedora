require "active_fedora"
class OralHistorySampleModel < ActiveFedora::Base

    has_relationship "parts", :is_part_of, :inbound => true
    
    has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
      m.field "narrator",  :string
      m.field "interviewer", :string
      m.field "transcript_editor", :text
      m.field "bio", :string
      m.field "notes", :text
      m.field "hard_copy_availability", :text
      m.field "hard_copy_location", :text
      m.field "other_contributor", :string
      m.field "restrictions", :text
      m.field "series", :string
      m.field "location", :string
    end
    
    has_metadata :name => "dublin_core", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
      m.field "creation_date", :date, :xml_node => "date"
      m.field "abstract", :text, :xml_node => "abstract"
      m.field "rights", :text, :xml_node => "rights"
      m.field "subject_heading", :string, :xml_node => "subject", :encoding => "LCSH" 
      m.field "spatial_coverage", :string, :xml_node => "spatial", :encoding => "TGN"
      m.field "temporal_coverage", :string, :xml_node => "temporal", :encoding => "Period"
      m.field "type", :string, :xml_node => "type", :encoding => "DCMITYPE"
      m.field "alt_title", :string, :xml_node => "alternative"
    end
    
    has_metadata :name => "significant_passages", :type => ActiveFedora::MetadataDatastream do |m|
      m.field "significant_passage", :text
    end
    
    has_metadata :name => "sensitive_passages", :type => ActiveFedora::MetadataDatastream do |m|
      m.field "sensitive_passage", :text
    end

end
