require 'spec_helper'

describe ActiveFedora::AssociationHash do
  subject(:association_hash) { described_class.new(model, reflections) }

  let(:model) { double(association: nil) }
  let(:reflections) { double(keys: [:foo]) }
  let(:reader) { double("reader") }
  let(:writer) { double("writer") }
  let(:association) { double(reader: reader, writer: writer) }

  describe "key reader" do
    describe "when the association exists" do
      before do
        allow(association_hash).to receive(:association).with("foo") { association }
      end
      it "calls the association reader" do
        expect(association_hash["foo"]).to eq(reader)
      end
    end
    describe "when the association does not exist" do
      before do
        allow(association_hash).to receive(:association).with("foo") { nil }
      end
      it "returns nil" do
        expect(association_hash["foo"]).to be_nil
      end
    end
  end

  describe "key setter" do
    let(:obj) { double }
    before do
      allow(association).to receive(:writer).with(obj) { writer }
    end
    describe "when the association exists" do
      before do
        allow(association_hash).to receive(:association).with("foo") { association }
      end
      it "calls the association writer" do
        expect(association).to receive(:writer).with(obj)
        association_hash["foo"] = obj
      end
    end
    describe "when the association does not exist" do
      before do
        allow(association_hash).to receive(:association).with("foo") { nil }
      end
      it "doesn't call the association writer" do
        expect(association).not_to receive(:writer).with(obj)
        association_hash["foo"] = obj
      end
    end
  end

  describe "#association" do
    before do
      allow(model).to receive(:association).with(:foo) { association }
    end
    it "works with a string key" do
      expect(association_hash.association("foo")).to eq(association)
    end
    it "works with a symbol key" do
      expect(association_hash.association(:foo)).to eq(association)
    end
  end

  describe "#key?" do
    it "works with a string" do
      expect(association_hash.key?("foo")).to be true
      expect(association_hash.key?("bar")).to be false
    end
    it "works with a symbol" do
      expect(association_hash.key?(:foo)).to be true
      expect(association_hash.key?(:bar)).to be false
    end
  end
end
