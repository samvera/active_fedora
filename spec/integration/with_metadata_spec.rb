require 'spec_helper'

describe ActiveFedora::WithMetadata do
  before do
    class AdditionalSchema < ActiveTriples::Schema
      property :new_property, predicate: ::RDF::URI("http://my.new.property/")
    end

    ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas << AdditionalSchema

    class SampleFile < ActiveFedora::File
      include ActiveFedora::WithMetadata

      metadata do
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end
  end

  after do
    Object.send(:remove_const, :SampleFile)
    Object.send(:remove_const, :AdditionalSchema)
    ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas = [ActiveFedora::WithMetadata::DefaultSchema]
  end

  let(:file) { SampleFile.new }

  describe "properties" do
    before do
      file.title = ['one', 'two']
    end
    it "sets and retrieve properties" do
      expect(file.title).to contain_exactly 'one', 'two'
    end

    it "tracks changes" do
      expect(file.title_changed?).to be true
    end

    context "with defaults" do
      subject { file }
      it { is_expected.to respond_to(:label) }
      it { is_expected.to respond_to(:file_name) }
      it { is_expected.to respond_to(:file_size) }
      it { is_expected.to respond_to(:date_created) }
      it { is_expected.to respond_to(:mime_type) }
      it { is_expected.to respond_to(:date_modified) }
      it { is_expected.to respond_to(:byte_order) }
      it { is_expected.to respond_to(:file_hash) }
    end
  end

  describe "#save" do
    before do
      file.title = ["foo"]
    end

    context "if the object saves (because it has content)" do
      before do
        file.content = "Hey"
        file.save
      end

      let(:reloaded) { SampleFile.new(file.uri) }

      it "saves the metadata too" do
        expect(reloaded.title).to eq ['foo']
      end
    end

    context "if the object is a new_record (didn't save)" do
      it "doesn't save the metadata" do
        expect(file.metadata_node).not_to receive(:save)
        file.save
      end
    end
  end

  context "when RDF.type is set" do
    let(:book) { RDF::URI.new("http://example.com/ns/Book") }

    before do
      class SampleBook < ActiveFedora::File
        include ActiveFedora::WithMetadata

        metadata do
          configure type: RDF::URI.new("http://example.com/ns/Book")
        end
      end

      file.content = 'foo'
      file.save
    end

    after do
      Object.send(:remove_const, :SampleBook)
    end

    let(:file) { SampleBook.new }
    let(:reloaded_file) { SampleBook.new(file.uri) }

    it "persists the configured type" do
      expect(reloaded_file.metadata_node.query(predicate: ::RDF.type).map(&:object)).to include book
    end
  end

  context "when using additional schema" do
    subject { SampleFile.new }
    it { is_expected.to respond_to(:new_property) }
  end
end
