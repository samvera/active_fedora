require 'spec_helper'

describe ActiveFedora::QueryResultBuilder do
  describe "#reify_solr_results" do
    before do
      class FooObject < ActiveFedora::Base
        def self.id_namespace
          "foo"
        end
      end
    end

    let(:test_object) { ActiveFedora::Base.create }
    let(:foo_object) { FooObject.create }

    after do
      Object.send(:remove_const, :FooObject)
    end

    it "returns an array of objects that are of the class stored in active_fedora_model_s" do
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([test_object.id, foo_object.id])
      solr_result = ActiveFedora::SolrService.query(query, rows: 10)
      result = described_class.reify_solr_results(solr_result)
      expect(result.length).to eq 2
      result.each do |r|
        expect((r.class == ActiveFedora::Base || r.class == FooObject)).to be true
      end
    end

    it '#reifies a lightweight object as a new instance' do
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([foo_object.id])
      solr_result = ActiveFedora::SolrService.query(query, rows: 10)
      result = described_class.reify_solr_results(solr_result, load_from_solr: true)
      expect(result.first).to be_instance_of FooObject
    end
  end
end
