require 'spec_helper'

describe ActiveFedora do
  
  before(:all) do
    module SolrSpecModel
      class Basic < ActiveFedora::Base
        def init_with(inner_obj)
        end
      end
    end
  end
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end
  
  
  describe "SOLR_DOCUMENT_ID" do
    before(:all) do
      SOLR_DOCUMENT_ID = "MY_SAMPLE_ID"
    end
    after(:all) do
      SOLR_DOCUMENT_ID = "id"
    end
    it "should be used by ActiveFedora::Base.to_solr" do
      @test_object.stub(pid: 'changeme:123')
      SOLR_DOCUMENT_ID = "MY_SAMPLE_ID"
      @test_object.to_solr[SOLR_DOCUMENT_ID.to_sym].should == 'changeme:123'
      @test_object.to_solr[:id].should be_nil
    end

    it "should be used by ActiveFedora::Base#find_with_conditions" do
      mock_response = double("SolrResponse")
      ActiveFedora::SolrService.should_receive(:query).with("_query_:\"{!raw f=#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}}info:fedora/afmodel:SolrSpecModel_Basic\" AND " + SOLR_DOCUMENT_ID + ':changeme\\:30', {:sort => ["#{ActiveFedora::SolrService.solr_name("system_create", :stored_sortable, type: :date)} asc"]}).and_return(mock_response)
  
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
      @test_object.stub(:datastreams).and_return({:ds1 => dirty_ds})
      @test_object.should_receive(:update_index).never
      @test_object.should_receive(:refresh)
      @test_object.save
    end
    it "should prevent Base.delete from deleting the corresponding Solr document if false" do
      ActiveFedora::SolrService.instance.conn.should_receive(:delete).with(@test_object.pid).never 
      @test_object.inner_object.should_receive(:delete)
      @test_object.delete
    end
  end
end

