require 'spec_helper'
require "solrizer"

describe ActiveFedora::NokogiriDatastream do
  
  before(:all) do
    class HydrangeaArticle2 < ActiveFedora::Base

      #has_relationship "parts", :is_part_of, :inbound => true

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

  describe '.term_values' do
    before do
      @pid = "hydrangea:fixture_mods_article1"
      @test_solr_object = HydrangeaArticle2.load_instance_from_solr(@pid)
      @test_object = HydrangeaArticle2.find(@pid)
    end

    it "should return the same values whether getting from solr or Fedora" do
      @test_solr_object.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
      ar = @test_solr_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
      ar.length.should == 4
      ar.include?("Creator").should == true
      ar.include?("Contributor").should == true
      ar.include?("Funder").should == true
      ar.include?("Host").should == true

      @test_object.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
      @test_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
      @test_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
      @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
      @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
      @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
      ar = @test_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
      ar.length.should == 4
      ar.include?("Creator").should == true
      ar.include?("Contributor").should == true
      ar.include?("Funder").should == true
      ar.include?("Host").should == true
    end
  end
  
end
