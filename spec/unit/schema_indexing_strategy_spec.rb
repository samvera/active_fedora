require 'spec_helper'

RSpec.describe ActiveFedora::SchemaIndexingStrategy do
  subject(:index_strategy) { described_class.new(property_indexer_factory) }

  describe "#apply" do
    let(:property) do
      p = object_double(ActiveTriples::Property.new(name: nil))
      allow(p).to receive(:to_h).and_return(options)
      allow(p).to receive(:name).and_return(name)
      p
    end
    let(:name) { "Name" }
    let(:options) do
      {
        class_name: "Test"
      }
    end
    let(:object) do
      o = object_double(ActiveFedora::Base)
      allow(o).to receive(:property).and_yield(index_configuration)
      o
    end
    let(:index_configuration) do
      d = double("index configuration")
      allow(d).to receive(:as)
      d
    end
    let(:property_indexer) do
      p = double("property_indexer")
      allow(p).to receive(:index).with(anything) do |index|
        index.as(*Array.wrap(index_types))
      end
      p
    end
    let(:property_indexer_factory) do
      p = double("property indexer factory")
      allow(p).to receive(:new).with(anything).and_return(property_indexer)
      p
    end
    let(:index_types) {}
    context "with no index types" do
      subject(:index_strategy) { described_class.new }
      it "does not try to index it" do
        index_strategy.apply(object, property)

        expect(object).to have_received(:property).with(property.name, property.to_h)
        expect(index_configuration).not_to have_received(:as)
      end
    end
    context "with one index type" do
      let(:index_types) { :symbol }
      it "applies that one" do
        index_strategy.apply(object, property)

        expect(index_configuration).to have_received(:as).with(:symbol)
      end
    end
    context "with multiple index types" do
      let(:index_types) { [:symbol, :stored_searchable] }
      it "applies all of them" do
        index_strategy.apply(object, property)

        expect(index_configuration).to have_received(:as).with(:symbol, :stored_searchable)
      end
    end
  end
end
