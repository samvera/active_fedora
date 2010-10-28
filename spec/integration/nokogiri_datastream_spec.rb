require File.join( File.dirname(__FILE__), "../spec_helper" )
require "hydra"
require "solrizer"

describe ActiveFedora::NokogiriDatastream do
  
  before(:all) do
    class HydrangeaArticle2 < ActiveFedora::Base

      has_relationship "parts", :is_part_of, :inbound => true

      # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
      # has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 

      # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
      has_metadata :name => "descMetadata", :type => ActiveFedora::NokogiriDatastream 

      # A place to put extra metadata values
      has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
        m.field 'collection', :string
      end
    end

    @pid = "hydrangea:fixture_mods_article1"
    @test_solr_object = HydrangeaArticle2.load_instance_from_solr(@pid)
    @test_object = HydrangeaArticle2.load_instance(@pid)
  end

  describe '.term_values' do

    it "should return the same values whether getting from solr or Fedora" do
      mock_term = mock("OM::XML::Term")
      mock_term.stubs(:data_type).returns(:text)
      mock_terminology = mock("OM::XML::Terminology")
      mock_terminology.stubs(:retrieve_term).returns(mock_term)

      ActiveFedora::NokogiriDatastream.stubs(:terminology).returns(mock_terminology)
      puts "\r\n\r\n#{@test_solr_object.datastreams["descMetadata"].internal_solr_doc.inspect}\r\n\r\n"
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

      @test_object.class.stubs(:terminology).returns(mock_terminology)
      @test_object.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["creator","submitter","teacher"]
      ar = @mods_ds.term_values({:name=>0},:role,:text)
      ar.length.should == 2
      ar.include?("creator").should == true
      ar.include?("submitter").should == true
      @test_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["teacher"]
      @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["creator"]
      @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>1},:text).should == ["submitter"]
      @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>2},:text).should == []
      @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["teacher"]
      @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
      ar = @test_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
      ar.length.should == 2
      ar.include?("creator").should == true
      ar.include?("teacher").should == true
      @test_object.datastreams["descMetadata"].term_values(:name,{:role=>1},:text).should == ["submitter"]
    end
  end
  
end
