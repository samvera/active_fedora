require "hydra"
module Hydra
class Hydra::SampleModsDatastream < ActiveFedora::NokogiriDatastream       

    # have to call this in order to set namespace & schema
    root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          

    property :title_info, :path=>"titleInfo", 
                :convenience_methods => {
                  :main_title => {:path=>"title"},
                  :language => {:path=>{:attribute=>"lang"}},                    
                }
    property :abstract, :path=>"abstract"
    property :topic_tag, :path=>'subject',:default_content_path => "topic"

    property :name_, :path=>"name", 
                :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "enumerated", "corporate"]} ],
                :subelements=>["namePart", "displayForm", "affiliation", :role, "description"],
                :default_content_path => "namePart",
                :convenience_methods => {
                  :date => {:path=>"namePart", :attributes=>{:type=>"date"}},
                  :family_name => {:path=>"namePart", :attributes=>{:type=>"family"}},
                  :first_name => {:path=>"namePart", :attributes=>{:type=>"given"}},
                  :terms_of_address => {:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}}
                }

    property :person, :variant_of=>:name_, :attributes=>{:type=>"personal"}
    property :organizaton, :variant_of=>:name_, :attributes=>{:type=>"institutional"}
    property :conference, :variant_of=>:name_, :attributes=>{:type=>"conference"}

    property :role, :path=>"role",
                :parents=>[:name_],
                :convenience_methods => {
                  :text => {:path=>"roleTerm", :attributes=>{:type=>"text"}},
                  :code => {:path=>"roleTerm", :attributes=>{:type=>"code"}},                    
                }

    property :journal, :path=>'relatedItem', :attributes=>{:type=>"host"},
                :subelements=>[:title_info, :origin_info, :issue],
                :convenience_methods => {
                  :issn => {:path=>"identifier", :attributes=>{:type=>"issn"}},
                }

    property :origin_info, :path=>'originInfo',
                :subelements=>["publisher","dateIssued"]

    property :issue, :path=>'part',
                :subelements=>[:start_page, :end_page],
                :convenience_methods => {
                  :volume => {:path=>"detail", :attributes=>{:type=>"volume"}},
                  :level => {:path=>"detail", :attributes=>{:type=>"level"}},
                  :publication_date => {:path=>"date"}
                }
    property :start_page, :path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "start"
    property :end_page, :path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "end"

    generate_accessors_from_properties    
    # accessor :title_info, :relative_xpath=>'oxns:titleInfo', :children=>[
    #   {:main_title=>{:relative_xpath=>'oxns:title'}},         
    #   {:language =>{:relative_xpath=>{:attribute=>"lang"} }}
    #   ] 
    # accessor :abstract
    # accessor :topic_tag, :relative_xpath=>'oxns:subject/oxns:topic'
    # accessor :person, :relative_xpath=>'oxns:name[@type="personal"]',  :children=>[
    #   {:last_name=>{:relative_xpath=>'oxns:namePart[@type="family"]'}}, 
    #   {:first_name=>{:relative_xpath=>'oxns:namePart[@type="given"]'}}, 
    #   {:institution=>{:relative_xpath=>'oxns:affiliation'}}, 
    #   {:role=>{:children=>[
    #     {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
    #     {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
    #   ]}}
    # ]
    # accessor :organization, :relative_xpath=>'oxns:name[@type="institutional"]', :children=>[
    #   {:role=>{:children=>[
    #     {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
    #     {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
    #   ]}}
    # ]
    # accessor :conference, :relative_xpath=>'oxns:name[@type="conference"]', :children=>[
    #   {:role=>{:children=>[
    #     {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
    #     {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
    #   ]}}
    # ]
    # accessor :journal, :relative_xpath=>'oxns:relatedItem[@type="host"]', :children=>[
    #     {:title=>{:relative_xpath=>'oxns:titleInfo/oxns:title'}}, 
    #     {:publisher=>{:relative_xpath=>'oxns:originInfo/oxns:publisher'}},
    #     {:issn=>{:relative_xpath=>'oxns:identifier[@type="issn"]'}}, 
    #     {:date_issued=>{:relative_xpath=>'oxns:originInfo/oxns:dateIssued'}},
    #     {:issue => {:relative_xpath=>"oxns:part", :children=>[          
    #       {:volume=>{:relative_xpath=>'oxns:detail[@type="volume"]'}},
    #       {:level=>{:relative_xpath=>'oxns:detail[@type="level"]'}},
    #       {:start_page=>{:relative_xpath=>'oxns:extent[@unit="pages"]/oxns:start'}},
    #       {:end_page=>{:relative_xpath=>'oxns:extent[@unit="pages"]/oxns:end'}},
    #       {:publication_date=>{:relative_xpath=>'oxns:date'}}
    #     ]}}
    # ]    

end
end