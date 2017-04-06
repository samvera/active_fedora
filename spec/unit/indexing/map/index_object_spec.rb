require 'spec_helper'

RSpec.describe ActiveFedora::Indexing::Map::IndexObject do
  describe "with a block" do
    subject(:instance) do
      described_class.new(:name) do |index|
        index.as :stored_searchable, :facetable
      end
    end

    it "can set behaviors" do
      expect(instance.behaviors).to eq [:stored_searchable, :facetable]
    end
  end

  describe "with an initializer parameters" do
    subject(:instance) do
      described_class.new(:name, behaviors: [:stored_searchable, :facetable])
    end

    it "can set behaviors" do
      expect(instance.behaviors).to eq [:stored_searchable, :facetable]
    end
  end
end
