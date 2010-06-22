class OpinionatedModsDocument < Nokogiri::XML::Document
  
  include OM::XML      
     
  self.schema_url = "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
  
  # Could add support for multiple root declarations.  
  #  For now, assume that any modsCollections have already been broken up and fed in as individual mods documents
  # root :mods_collection, :path=>"modsCollection", 
  #           :attributes=>[],
  #           :subelements => :mods
  root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"]          
            
end