require 'spec_helper'

describe ActiveFedora do
  before(:all) do
    module SolrSpecModel
      class Basic < ActiveFedora::Base
      end
    end
  end

  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  describe ".id_field" do
    let(:field) { "MY_SAMPLE_ID".freeze }
    before do
      allow(described_class).to receive(:id_field).and_return(field)
    end

    it "is used by ActiveFedora::Base.to_solr" do
      allow(@test_object).to receive(:id).and_return('changeme:123')
      expect(@test_object.to_solr[field.to_sym]).to eq 'changeme:123'
      expect(@test_object.to_solr[:id]).to be_nil
    end

    it "is used by ActiveFedora::Base#find_with_conditions" do
      mock_response = double("SolrResponse")
      expect(ActiveFedora::SolrService).to receive(:query)
        .with("_query_:\"{!raw f=has_model_ssim}SolrSpecModel::Basic\" AND " \
              "_query_:\"{!raw f=#{field}}changeme:30\"",
              sort: ["#{ActiveFedora::SolrQueryBuilder.solr_name('system_create', :stored_sortable, type: :date)} asc"])
        .and_return(mock_response)

      expect(SolrSpecModel::Basic.find_with_conditions(id: "changeme:30")).to equal(mock_response)
    end
  end

  describe ".enable_solr_updates?" do
    context 'with .enable_solr_updates? disabled' do
      before do
        allow(described_class).to receive(:enable_solr_updates?).and_return(false)
      end

      it "prevents Base.save from calling update_index if false" do
        dirty_ds = ActiveFedora::SimpleDatastream.new
        @test_object.attached_files['ds1'] = dirty_ds
        allow(@test_object).to receive(:datastreams).and_return(ds1: dirty_ds)
        expect(@test_object).to receive(:update_index).never
        expect(@test_object).to receive(:refresh)
        @test_object.save
      end
      it "prevents Base.delete from deleting the corresponding Solr document if false" do
        expect(ActiveFedora::SolrService.instance.conn).to receive(:delete).with(@test_object.id).never
        expect(@test_object).to receive(:delete)
        @test_object.delete
      end
    end
  end
end
