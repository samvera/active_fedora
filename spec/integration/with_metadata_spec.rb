require 'spec_helper'

describe ActiveFedora::WithMetadata do
  before do
    class SampleFile < ActiveFedora::File
      include ActiveFedora::WithMetadata

      metadata do
        property :title, predicate: ::RDF::DC.title
      end
    end
  end

  after do
    Object.send(:remove_const, :SampleFile)
  end

  let(:file) { SampleFile.new }

  describe "properties" do
    before do
      file.title = ['one', 'two']
    end
    it "should set and retrieve properties" do
      expect(file.title).to eq ['one', 'two']
    end

    it "should track changes" do
      expect(file.title_changed?).to be true
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

      it "should save the metadata too" do
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

end
