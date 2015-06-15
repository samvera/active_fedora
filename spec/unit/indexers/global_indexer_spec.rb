require 'spec_helper'

RSpec.describe ActiveFedora::Indexers::GlobalIndexer do
  subject { described_class.new(index_types) }
  let(:index_types) {}

  describe "#new" do
    # The global indexer acts as both an indexer factory and an indexer, since
    # the property doesn't matter.
    it "should return itself" do
      expect(subject.new("bla")).to eq subject
    end
  end
  describe "#index" do
    let(:index_obj) { instance_double(ActiveFedora::Indexing::Map::IndexObject, as: nil) }
    context "with one index type" do
      let(:index_types) { :symbol }
      it "should pass that to index_obj" do
        subject.index(index_obj)

        expect(index_obj).to have_received(:as).with(:symbol)
      end
    end
    context "with multiple index types" do
      let(:index_types) { [:symbol, :stored_searchable] }
      it "should pass that to index_obj" do
        subject.index(index_obj)

        expect(index_obj).to have_received(:as).with(:symbol, :stored_searchable)
      end
    end
    context "with no index types" do
      subject { described_class.new }
      it "should not pass anything to index_obj" do
        subject.index(index_obj)

        expect(index_obj).not_to have_received(:as)
      end
    end
  end
end
