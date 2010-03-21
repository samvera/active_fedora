require 'active-fedora'

include ActiveFedora
include SemanticNode

class OralHistory < ActiveFedora::Base
    include Model

  
    # Imitating DataMapper ...
    
    has_relationship "parts", :is_part_of, :inbound => true
    
    # These are all the properties that don't quite fit into Qualified DC
    # Put them on the object itself (in the properties datastream) for now.
    has_metadata :name => "properties", :type => MetadataDatastream do |m|
      field "alt_title", :string
      field "narrator",  :string
      field "interviewer", :integer
      field "transcript_editor", :text
      field "bio", :string
      field "notes", :text
      field "hard_copy_availability", :text
      field "hard_copy_location", :text
      field "other_contributors", :string
      field "restrictions", :text
    end
        
    has_metadata :name => "dublin_core", :type => QualifiedDublinCoreDatastream do |m|
      # Default :multiple => true
      #
      # on retrieval, these will be pluralized and returned as arrays
      # ie. subject_entries = my_oral_history.dublin_core.subjects
      #
      # aimint to use method-missing to support calling methods like
      # my_oral_history.subjects  OR   my_oral_history.titles  OR EVEN my_oral_history.title whenever possible
      
      #field :name => "subject_heading", :string, {:xml_node => "subject", :encoding => "LCSH"}
    end
    
    has_metadata :name => "significant_passages" do |m|
      field "significant_passage", :text
    end
    
    has_metadata :name => "sensitive_passages" do |m|
      field "sensitive_passage", :text
    end

  
end