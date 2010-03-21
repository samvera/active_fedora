require 'active-fedora'

class Seminar 
  
    include ActiveFedora::Model
    
    # Imitating DataMapper ...
    
    relationship "parts", :is_part_of, [:seminar_audio_file], :inbound => true 
    #has n, :parts, {:predicate => :is_part_of, :likely_types => [:seminar_audio_file], :inbound => true}  
    # OR
    # has_parts [:seminar_audio_file] 
    
    property "title_wylie",          :text  # Note: reserving title_tibetan for actual UTF-8 tibetan text
    property "title_english",         :text
    property "original_media_format",      :text
    property "original_media_number_of_units",      :integer
    property "author_name_wylie",  :text
    property "author_name_english",     :text
    property "location",    :string
    property "date_recorded",   :date
    property "file_name", :string
    property "duration",      :string
    property "file_size",    :integer
    property "restriction",   :text
    property "uri",   :string
    property "notes", :text
  
end