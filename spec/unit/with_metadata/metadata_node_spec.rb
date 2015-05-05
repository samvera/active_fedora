require 'spec_helper'

describe ActiveFedora::WithMetadata::MetadataNode do
  let(:generated_schema) { Class.new(described_class) }

  let(:file) { ActiveFedora::File.new }
  let(:node) { generated_schema.new(file) }
  let(:book) { RDF::URI.new('http://example.com/ns/Book') }

  describe "#changed_attributes" do
    subject { node.changed_attributes }

    context "when type is not set" do
      it { is_expected.to eq({}) }
    end

    context "when type is set" do
      before do
        generated_schema.configure type: book
      end

      it { is_expected.to eq('type' => true) }
    end
  end

  describe "changes_for_update" do
    subject { node.send(:changes_for_update) }

    context "when type is not set" do
      it { is_expected.to eq({}) }
    end

    context "when type is set" do
      before do
        generated_schema.configure type: book
      end

      it "is expected to have the rdf type statement" do
        expect(subject[::RDF.type]).to be_kind_of RDF::Queryable::Enumerator
      end
    end
  end


end
