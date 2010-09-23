require "hydra"
module Hydra
class Hydra::SampleModsDatastream < ActiveFedora::NokogiriDatastream       
    
    set_terminology do |t|
      t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

      t.title_info(:path=>"titleInfo") {
        t.main_title(:path=>"title", :label=>"title")
        t.language(:path=>{:attribute=>"lang"})
      } 
      t.abstract     
      t.topic_tag(:path=>"subject", :default_content_path=>"topic")           
      # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
      t.name_ {
        # this is a namepart
        t.namePart(:index_as=>[:searchable, :displayable, :facetable, :sortable], :required=>:true, :type=>:string, :label=>"generic name")
        # affiliations are great
        t.affiliation
        t.displayForm
        t.role(:ref=>[:role])
        t.description
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
        t.last_name(:path=>"namePart", :attributes=>{:type=>"family"})
        t.first_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
        t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
      }
      # lookup :person, :first_name        
      t.person(:ref=>:name, :attributes=>{:type=>"personal"})
      t.organizaton(:ref=>:name, :attributes=>{:type=>"institutional"})
      t.conference(:ref=>:name, :attributes=>{:type=>"conference"})

      t.role {
        t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
        t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
      }
      t.journal(:path=>'relatedItem', :attributes=>{:type=>"host"}) {
        t.title_info
        t.origin_info(:path=>"originInfo") {
          t.publisher
          t.date_issued(:path=>"dateIssued")
        }
        t.issn(:path=>"identifier", :attributes=>{:type=>"issn"})
        t.issue(:path=>"part") {
          t.volume(:path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
          t.level(:path=>"detail", :attributes=>{:type=>"number"}, :default_content_path=>"number")
          t.extent
          t.pages(:path=>"extent", :attributes=>{:type=>"pages"}) {
            t.start
            t.end
          }
          t.publication_date(:path=>"date")
        }
      }
      
    end
    
    # Changes from OM::Properties implementation
    # renamed family_name => last_name
    # start_page & end_page now accessible as [:journal, :issue, :pages, :start] (etc.)

end
end