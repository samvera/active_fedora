require 'active-fedora'

class AudioRecord
  
    include ActiveFedora::Model
      
    # This seems a bit strange, since this Class might be used outside of Oral Histories.  
    # From this perspective, it makes more sense to put triples on the containing object, not on the children...
    
    relationship "parents", :is_part_of, [nil, :oral_history]
    #has n, :parents, {:predicate => :is_part_of, :likely_types => [nil, :oral_history]}
    # OR
    # is_part_of [:oral_history]
    
    property "date_recorded",   :date
    property "file_name", :string
    property "duration",  :string
    property "notes", :text

    # This doesn't make sense when you have both compressed and uncompressed in the same object!
    # Probably better to rely on the file size in datastreamVersion "SIZE" attribute from Fedora anyway    
    #property "file_size", :integer

    #property "restriction", :text
    
    datastream "compressed", ["audio/mpeg"], :multiple => true
    datastream "uncompressed", ["audio/wav", "audio/aiff"], :multiple => true
      
end