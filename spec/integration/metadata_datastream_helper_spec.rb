require 'spec_helper'

require 'active-fedora'
require "rexml/document"

class MockMetaHelperSolr < ActiveFedora::Base
  has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
    m.field "holding_id", :string
  end
  
  has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
    m.field "created", :date, :xml_node => "created"
    m.field "language", :string, :xml_node => "language"
    m.field "creator", :string, :xml_node => "creator"
    # Created remaining fields
    m.field "geography", :string, :xml_node => "geography"
    m.field "title", :string, :xml_node => "title"
  end

end

describe ActiveFedora::MetadataDatastreamHelper do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_object.save
  end
  
  after(:each) do
    begin
    @test_object.delete
    rescue
    end
    begin
    @test_object2.delete
    rescue
    end
    begin
    @test_object3.delete
    rescue
    end
  end
  
  describe '#from_solr' do
    it 'should return an object with the appropriate metadata fields filled in' do
      @test_object = MockMetaHelperSolr.new
      attributes = {"holding_id"=>{0=>"Holding 1"},
                    "language" =>{0=>"Italian"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Italy"},
                    "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
      @test_object.update_indexed_attributes(attributes)
      @test_object.save
      
      @test_object2 = MockMetaHelperSolr.new
      attributes = {"holding_id"=>{0=>"Holding 2"},
                    "language"=>{0=>"Spanish;Latin"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Spain"},
                    "title"=>{0=>"A study of the evolution of Spanish from Latin"}}
      @test_object2.update_indexed_attributes(attributes)
      @test_object2.save      

      @test_object3 = MockMetaHelperSolr.new
      attributes = {"holding_id"=>{0=>"Holding 3"},
                    "language"=>{0=>"Spanish;Latin"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Spain"},
                    "title"=>{0=>"An obscure look into early nomadic tribes of Spain"}}
      @test_object3.update_indexed_attributes(attributes)
      @test_object3.save
      
      #from_solr gets called indirectly
      test_from_solr_object = MockMetaHelperSolr.load_instance_from_solr(@test_object.pid)
      test_from_solr_object2 = MockMetaHelperSolr.load_instance_from_solr(@test_object2.pid)
      test_from_solr_object3 = MockMetaHelperSolr.load_instance_from_solr(@test_object3.pid)
      
      test_from_solr_object.descMetadata.language.should == ["Italian"]
      test_from_solr_object.descMetadata.creator.should == ["Linguist, A."]
      test_from_solr_object.descMetadata.geography.should == ["Italy"]
      test_from_solr_object.descMetadata.title.should == ["Italian and Spanish: A Comparison of Common Phrases"]
      #test_from_solr_object.fields[:holding_id][:values].should == ["Holding 1"]
      
      test_from_solr_object2.descMetadata.language.should == ["Spanish;Latin"]
      test_from_solr_object2.descMetadata.creator.should == ["Linguist, A."]
      test_from_solr_object2.descMetadata.geography.should == ["Spain"]
      test_from_solr_object2.descMetadata.title.should == ["A study of the evolution of Spanish from Latin"]
      #test_from_solr_object2.fields[:holding_id][:values].should == ["Holding 2"]
      
      test_from_solr_object3.descMetadata.language.should == ["Spanish;Latin"]
      test_from_solr_object3.descMetadata.creator.should == ["Linguist, A."]
      test_from_solr_object3.descMetadata.geography.should == ["Spain"]
      test_from_solr_object3.descMetadata.title.should == ["An obscure look into early nomadic tribes of Spain"]
      #test_from_solr_object3.properties.holding_id.should == ["Holding 3"]
      
      
    end
  end
  
end
