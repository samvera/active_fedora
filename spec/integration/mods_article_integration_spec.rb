require 'spec_helper'

describe ActiveFedora::Base do
  describe ".update_indexed_attributes" do
    before(:each) do
      @test_article = HydrangeaArticle.find("hydrangea:fixture_mods_article1")
      @test_article.update_indexed_attributes({[{:person=>0}, :first_name] => "GIVEN NAMES"}, :datastreams=>"descMetadata")
    end
    after(:each) do
      @test_article.update_indexed_attributes({[{:person=>0}, :first_name] => "GIVEN NAMES"}, :datastreams=>"descMetadata")
    end
    it "should update the xml in the specified datatsream and save those changes to Fedora" do
      expect(@test_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name])).to eq(["GIVEN NAMES"])
      test_args = {:params=>{[{:person=>0}, :first_name]=>{"0"=>"Replacement FirstName"}}, :opts=>{:datastreams=>"descMetadata"}}
      @test_article.update_indexed_attributes(test_args[:params], test_args[:opts])
      expect(@test_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name])).to eq(["Replacement FirstName"])
      @test_article.save
      retrieved_article = HydrangeaArticle.find("hydrangea:fixture_mods_article1")
      expect(retrieved_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name])).to eq(["Replacement FirstName"])
    end
  end
end
