require 'spec_helper'

RSpec.describe ActiveFedora::Indexers::GlobalIndexer do
  let(:global_indexer) { described_class.new(index_types) }
  let(:index_types) {}

  describe "#new" do
    # The global indexer acts as both an indexer factory and an indexer, since
    # the property doesn't matter.
    it "returns itself" do
      expect(global_indexer.new("bla")).to eq global_indexer
    end
  end
  describe "#index" do
    let(:index_obj) { instance_double(ActiveFedora::Indexing::Map::IndexObject, as: nil) }
    context "with one index type" do
      let(:index_types) { :symbol }
      it "passes that to index_obj" do
        global_indexer.index(index_obj)

        expect(index_obj).to have_received(:as).with(:symbol)
      end
    end
    context "with multiple index types" do
      let(:index_types) { [:symbol, :stored_searchable] }
      it "passes that to index_obj" do
        global_indexer.index(index_obj)

        expect(index_obj).to have_received(:as).with(:symbol, :stored_searchable)
      end
    end
    context "with no index types" do
      let(:global_indexer) { described_class.new }
      it "does not pass anything to index_obj" do
        global_indexer.index(index_obj)

        expect(index_obj).not_to have_received(:as)
      end
    end
  end
end
