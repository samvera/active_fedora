require File.join( File.dirname(__FILE__), "../spec_helper" )
# require File.join( File.dirname(__FILE__), "..", "samples", "models", "mods_article" )
require "af_samples"
describe ActiveFedora::Base do

  before(:all) do
    class HydrangeaArticle < ActiveFedora::Base

      has_relationship "parts", :is_part_of, :inbound => true

      # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
      # has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 

      # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
      has_metadata :name => "descMetadata", :type => Hydra::ModsArticleDatastream 

      # A place to put extra metadata values
      has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
        m.field 'collection', :string
      end
    end
  end
  
  before(:each) do
    @test_article = HydrangeaArticle.load_instance("hydrangea:fixture_mods_article1")
  end
  
  describe ".update_indexed_attributes" do
    before(:each) do
      @test_article.update_indexed_attributes({[{:person=>0}, :first_name] => "GIVEN NAMES"}, :datastreams=>"descMetadata")
    end
    after(:each) do
      @test_article.update_indexed_attributes({[{:person=>0}, :first_name] => "GIVEN NAMES"}, :datastreams=>"descMetadata")
    end
    it "should update the xml in the specified datatsream and save those changes to Fedora" do
      @test_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name]).should == ["GIVEN NAMES"]
      test_args = {:params=>{[{:person=>0}, :first_name]=>{"0"=>"Replacement FirstName"}}, :opts=>{:datastreams=>"descMetadata"}}
      @test_article.update_indexed_attributes(test_args[:params], test_args[:opts])
      @test_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name]).should == ["Replacement FirstName"]
      @test_article.save
      retrieved_article = HydrangeaArticle.load_instance("hydrangea:fixture_mods_article1")
      retrieved_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name]).should == ["Replacement FirstName"]
    end
  end
end