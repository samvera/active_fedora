require 'spec_helper'

describe ActiveFedora::QueryResultBuilder do
  describe "reify solr results" do
    before(:all) do
      class AudioRecord < ActiveFedora::Base
        attr_accessor :id
        def self.connection_for_id(_id); end
      end
      @sample_solr_hits = [{ "id" => "my:_ID1_", ActiveFedora.index_field_mapper.solr_name("has_model", :symbol) => ["AudioRecord"] },
                           { "id" => "my:_ID2_", ActiveFedora.index_field_mapper.solr_name("has_model", :symbol) => ["AudioRecord"] },
                           { "id" => "my:_ID3_", ActiveFedora.index_field_mapper.solr_name("has_model", :symbol) => ["AudioRecord"] }]
    end
    describe ".reify_solr_results" do
      it "uses AudioRecord.find to instantiate objects" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID2_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID3_", cast: true)
        described_class.reify_solr_results(@sample_solr_hits)
      end
    end
    describe ".lazy_reify_solr_results" do
      it "lazilies reify solr results" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID2_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID3_", cast: true)
        described_class.lazy_reify_solr_results(@sample_solr_hits).each { |r| r }
      end
    end
  end
end
