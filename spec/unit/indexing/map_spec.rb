require 'spec_helper'

RSpec.describe ActiveFedora::Indexing::Map do
  describe ".merge" do
    subject(:merged) { first_map.merge(extra) }
    let(:index_object1) { instance_double(described_class::IndexObject) }
    let(:index_object2) { instance_double(described_class::IndexObject) }
    let(:index_object3) { instance_double(described_class::IndexObject) }
    let(:first_map) { described_class.new(one: index_object1, two: index_object2) }

    context "with a hash" do
      let(:extra) { { three: index_object3 } }
      it "merges with a hash" do
        expect(merged).to be_instance_of described_class
        expect(merged.keys).to match_array [:one, :two, :three]
      end
    end

    context "with another Indexing::Map" do
      let(:extra) { described_class.new(three: index_object3) }
      it "merges with the other map" do
        expect(merged).to be_instance_of described_class
        expect(merged.keys).to match_array [:one, :two, :three]
      end
    end
  end
end
