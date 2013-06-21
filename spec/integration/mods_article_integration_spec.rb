require 'spec_helper'

describe ActiveFedora::Base do
  describe ".update_indexed_attributes" do
    before(:each) do
      @test_article = ModsArticle.find("test:fixture_mods_article1")
      @test_article.descMetadata.update_indexed_attributes({[{:person=>0}, :first_name] => "GIVEN NAMES"})
    end
    after(:each) do
      @test_article.descMetadata.update_indexed_attributes({[{:person=>0}, :first_name] => "GIVEN NAMES"})
    end
    it "should update the xml in the specified datatsream and save those changes to Fedora" do
      @test_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name]).should == ["GIVEN NAMES"]
      test_args = {[{:person=>0}, :first_name]=>{"0"=>"Replacement FirstName"}}
      @test_article.descMetadata.update_indexed_attributes(test_args)
      @test_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name]).should == ["Replacement FirstName"]
      @test_article.save
      retrieved_article = ModsArticle.find("test:fixture_mods_article1")
      retrieved_article.get_values_from_datastream("descMetadata", [{:person=>0}, :first_name]).should == ["Replacement FirstName"]
    end
  end
end
