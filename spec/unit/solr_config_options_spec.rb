require 'spec_helper'


#include ActiveFedora

describe ActiveFedora do
  
  before(:all) do
    module SolrSpecModel
      class Basic
        include ActiveFedora::Model
        def init_with(inner_obj)
        end
      end
    end
  end
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end
  
  
  describe "field name mappings" do
    after(:all) do
      # Revert to default mappings after running tests
      ActiveFedora::SolrService.load_mappings
    end
    it "should default to using the mappings for the current schema" do
      from_default_yml = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings.yml")))
      ActiveFedora::SolrService.mappings[:searchable].data_types[:date].opts[:suffix].should == from_default_yml["searchable"]["date"]    
    end
    it "should allow you to provide your own mappings file" do
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      ActiveFedora::SolrService.mappings[:searchable].data_types[:date].opts[:suffix].should == "_date"      
      ActiveFedora::SolrService.mappings[:searchable].data_types[:default].opts[:suffix].should == "_field"
    end
  end
  
  describe "SOLR_DOCUMENT_ID" do
    before(:all) do
      SOLR_DOCUMENT_ID = "MY_SAMPLE_ID"
    end
    after(:all) do
      SOLR_DOCUMENT_ID = "id"
    end
    it "should be used by ActiveFedora::Base.to_solr" do
      SOLR_DOCUMENT_ID = "MY_SAMPLE_ID"
      @test_object.to_solr[SOLR_DOCUMENT_ID.to_sym].should_not be_nil
      @test_object.to_solr[:id].should be_nil
    end

    it "should be used by ActiveFedora::Base#find_with_conditions" do
      mock_response = mock("SolrResponse")
      ActiveFedora::SolrService.expects(:query).with("has_model_s:info\\:fedora/afmodel\\:SolrSpecModel_Basic AND " + SOLR_DOCUMENT_ID + ':"changeme\\:30"', {:sort => ['system_create_dt asc']}).returns(mock_response)
  
      SolrSpecModel::Basic.find_with_conditions(:id=>"changeme:30").should equal(mock_response)
    end
  end
  
  describe "ENABLE_SOLR_UPDATES" do
    
    before(:all) do
      ENABLE_SOLR_UPDATES = false
    end
    after(:all) do
      ENABLE_SOLR_UPDATES = true
    end
    
    it "should prevent Base.save from calling update_index if false" do
      dirty_ds = ActiveFedora::SimpleDatastream.new(@test_object.inner_object, 'ds1')
      @test_object.datastreams['ds1'] = dirty_ds
      @test_object.stubs(:datastreams).returns({:ds1 => dirty_ds})
      @test_object.expects(:update_index).never
      @test_object.expects(:refresh)
      @test_object.save
    end
    it "should prevent Base.delete from deleting the corresponding Solr document if false" do
      ActiveFedora::SolrService.instance.conn.expects(:delete).with(@test_object.pid).never 
      @test_object.inner_object.expects(:delete)
      @test_object.delete
    end
  end
end

