require 'spec_helper'


#include ActiveFedora

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
      SOLR_DOCUMENT_ID = "MY_SAMPLE_ID"
      expect(@test_object.to_solr[SOLR_DOCUMENT_ID.to_sym]).not_to be_nil
      expect(@test_object.to_solr[:id]).to be_nil
    end

    it "should be used by ActiveFedora::Base#find_with_conditions" do
      mock_response = double("SolrResponse")
      expect(ActiveFedora::SolrService).to receive(:query).with("#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}:info\\:fedora\\/afmodel\\:SolrSpecModel_Basic AND " + SOLR_DOCUMENT_ID + ':"changeme\\:30"', {:sort => ["#{ActiveFedora::SolrService.solr_name("system_create", :date)} asc"]}).and_return(mock_response)

      expect(SolrSpecModel::Basic.find_with_conditions(:id=>"changeme:30")).to equal(mock_response)
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
      allow(@test_object).to receive(:datastreams).and_return({:ds1 => dirty_ds})
      expect(@test_object).to receive(:update_index).never
      expect(@test_object).to receive(:refresh)
      @test_object.save
    end
    it "should prevent Base.delete from deleting the corresponding Solr document if false" do
      expect(ActiveFedora::SolrService.instance.conn).to receive(:delete).with(@test_object.pid).never
      expect(@test_object.inner_object).to receive(:delete)
      @test_object.delete
    end
  end
end

