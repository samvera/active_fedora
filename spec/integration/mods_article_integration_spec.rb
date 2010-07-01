require File.join( File.dirname(__FILE__), "../spec_helper" )

require "hydra"
    
describe ActiveFedora::Base do

  before(:all) do
    class HydrangeaArticle < ActiveFedora::Base

      has_relationship "parts", :is_part_of, :inbound => true

      # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
      # has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 

      # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
      has_metadata :name => "descMetadata", :type => Hydra::ModsArticle 

      # A place to put extra metadata values
      has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
        m.field 'collection', :string
      end
    end
  end
  
  before(:each) do
    @test_article = HydrangeaArticle.load_instance("hydrangea:fixture_mods_article1")
  end
  
end