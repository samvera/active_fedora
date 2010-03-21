require 'active-fedora'

class SeminarAudioFile
  
    include ActiveFedora::Model
  
    # Imitating DataMapper ...
    
    relationship "parent", :is_part_of, :seminar
    #has n, :parents, {:predicate => :is_part_of, :likely_types => [:seminar]}
    # OR
    # is_part_of :seminar
    
    property "date_recorded",   :date
    property "file_name", :string
    property "duration",  :string
    property "uri", :string
    property "notes", :text

    # TODO: Figure out how to declare access restrictions
    #property "restriction", :text
    set_restrictions ["public", "private"]
        
    # A file_size property doesn't make sense when you have both compressed and uncompressed in the same object!
    # Probably better to rely on the file size in datastreamVersion "SIZE" attribute from Fedora anyway    
    #property "file_size", :integer

    datastream "compressed", ["audio/mpeg"], :multiple => true
    datastream "uncompressed", ["audio/wav", "audio/aiff"], :multiple => true
    
    #has_metadata "dublin_core", :type => ActiveFedora::MetadataDatastream::QualifiedDublinCore

  
end