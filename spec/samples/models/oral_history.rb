require 'active-fedora'

class OralHistory < ActiveFedora::Base
    # Imitating DataMapper ...
    
    has_many :parts, :property=>:is_part_of
    
    # These are all the properties that don't quite fit into Qualified DC
    # Put them on the object itself (in the properties datastream) for now.
    has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
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
        
    has_metadata :name => "dublin_core", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
      # Default :multiple => true
      #
      # on retrieval, these will be pluralized and returned as arrays
      # ie. subject_entries = my_oral_history.dublin_core.subjects
      #
      # aimint to use method-missing to support calling methods like
      # my_oral_history.subjects  OR   my_oral_history.titles  OR EVEN my_oral_history.title whenever possible
      
      #field :name => "subject_heading", :string, {:xml_node => "subject", :encoding => "LCSH"}
    end

  
end
