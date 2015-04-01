require 'spec_helper'

describe ActiveFedora::QueryResultBuilder do
  describe "reify solr results" do
    before(:all) do
      class AudioRecord
        attr_accessor :id
        def self.connection_for_id(id)
        end
      end
      @sample_solr_hits = [{"id"=>"my:_ID1_", ActiveFedora::SolrQueryBuilder.solr_name("has_model", :symbol)=>["AudioRecord"]},
                           {"id"=>"my:_ID2_", ActiveFedora::SolrQueryBuilder.solr_name("has_model", :symbol)=>["AudioRecord"]},
                           {"id"=>"my:_ID3_", ActiveFedora::SolrQueryBuilder.solr_name("has_model", :symbol)=>["AudioRecord"]}]
    end
    describe ".reify_solr_result" do
      it "should use .find to instantiate objects" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        ActiveFedora::QueryResultBuilder.reify_solr_result(@sample_solr_hits.first)
      end
    end
    describe ".reify_solr_results" do
      it "should use AudioRecord.find to instantiate objects" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID2_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID3_", cast: true)
        ActiveFedora::QueryResultBuilder.reify_solr_results(@sample_solr_hits)
      end
    end
    describe ".lazy_reify_solr_results" do
      it "should lazily reify solr results" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID2_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID3_", cast: true)
        ActiveFedora::QueryResultBuilder.lazy_reify_solr_results(@sample_solr_hits).each {|r| r}
      end
    end
  end

end
