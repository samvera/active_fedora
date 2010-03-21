require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora/solr_service'

include ActiveFedora

describe ActiveFedora do
  
  before(:all) do
    module SpecModel
      class Basic
        include ActiveFedora::Model
      end
    end
  end
  
  before(:each) do
    Fedora::Repository.instance.stubs(:nextid).returns("_nextid_")
    @test_object = ActiveFedora::Base.new
  end
  
  after(:all) do
    # Revert to default mappings after running tests
    ActiveFedora::SolrService.load_mappings
  end
  
  describe "field name mappings" do
    it "should default to using the mappings for the current schema" do
      from_default_yml = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings.yml")))
      ActiveFedora::SolrService.mappings.should == from_default_yml
      ActiveFedora::SolrService.mappings["date"].should == "_dt"      
    end
    it "should allow you to provide your own mappings file" do
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      ActiveFedora::SolrService.mappings["date"].should == "_date"      
      ActiveFedora::SolrService.mappings["symbol"].should == "_field"            
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
    it "should be used by ActiveFedora::Base#find" do
      mock_solr = mock("SolrConnection")
      mock_result = mock("MockResult")
      mock_result.expects(:hits).returns([{SOLR_DOCUMENT_ID => "changeme:30"}])
      mock_solr.expects(:query).with(SOLR_DOCUMENT_ID + ':changeme\:30').returns(mock_result)
      Fedora::Repository.instance.expects(:find_model).with("changeme:30", SpecModel::Basic).returns("fake object")

      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock_solr))
  
      res = SpecModel::Basic.find("changeme:30")
    end
    it "should be used by ActiveFedora::Base#find_by_solr" do
      mock_solr = mock("SolrConnection")
      mock_response = mock("SolrResponse")
      mock_solr.expects(:query).with(SOLR_DOCUMENT_ID + ':changeme\:30', {}).returns(mock_response)
      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock_solr))
  
      SpecModel::Basic.find_by_solr("changeme:30").should equal(mock_response)
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
      Fedora::Repository.instance.stubs(:save)
      mock1 = mock("ds1", :dirty? => true, :save => true, :kind_of? => ActiveFedora::MetadataDatastream)
      @test_object.instance_variable_set(:@metadata_is_dirty, true)
      @test_object.stubs(:datastreams_in_memory).returns({:ds1 => mock1})
      @test_object.expects(:update_index).never
      @test_object.expects(:refresh)
      @test_object.save
    end
    it "should prevent Base.delete from deleting the corresponding Solr document if false" do
      Fedora::Repository.instance.expects(:delete)
      ActiveFedora::SolrService.expects(:instance).never
      @test_object.delete
    end
  end
end

