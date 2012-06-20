require "active_fedora"
class OralHistorySampleModel < ActiveFedora::Base

    #has_relationship "parts", :is_part_of, :inbound => true
    
    has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
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
    
    has_metadata :name => "dublin_core", :type => ActiveFedora::QualifiedDublinCoreDatastream

    has_metadata :name => "significant_passages", :type => ActiveFedora::SimpleDatastream do |m|
      m.field "significant_passage", :text
    end
    
    has_metadata :name => "sensitive_passages", :type => ActiveFedora::SimpleDatastream do |m|
      m.field "sensitive_passage", :text
    end

end
