require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class PageImage < ActiveFedora::Base
      directly_contains :files, has_member_relation: ::RDF::URI.new("http://example.com/hasFiles"), class_name: "FileWithMetadata"
      directly_contains_one :primary_file, through: :files, type: ::RDF::URI.new("http://example.com/primaryFile"), class_name: "FileWithMetadata"
      directly_contains_one :alternative_file, through: :files, type: ::RDF::URI.new("http://example.com/featuredFile"), class_name: 'AlternativeFileWithMetadata'
    end

    class FileWithMetadata < ActiveFedora::File
      include ActiveFedora::WithMetadata
    end
    class AlternativeFileWithMetadata < ActiveFedora::File
      include ActiveFedora::WithMetadata
    end
  end

  after do
    Object.send(:remove_const, :PageImage)
    Object.send(:remove_const, :FileWithMetadata)
    Object.send(:remove_const, :AlternativeFileWithMetadata)
  end

  let(:page_image)              { PageImage.create }
  let(:reloaded_page_image)     { PageImage.find(page_image.id) }

  let(:a_file)                  { page_image.files.build }
  let(:primary_file)            { page_image.build_primary_file }
  let(:alternative_file)        { page_image.build_alternative_file }
  let(:primary_sub_image)       { page_image.build_primary_sub_image }

  context "#build" do
    context "when container element is a type of ActiveFedora::File" do
      before do
        primary_file.content = "I'm in a container all alone!"
        page_image.save!
      end
      subject(:reloaded_file) { reloaded_page_image.primary_file }
      it "initializes an object within the container" do
        expect(reloaded_file.content).to eq("I'm in a container all alone!")
        expect(reloaded_file.metadata_node.type).to include(::RDF::URI.new("http://example.com/primaryFile"))
      end
      it "relies on info from the :through association, including class_name" do
        expect(page_image.files).to include(primary_file)
        expect(primary_file.uri.to_s).to include("/files/")
        expect(reloaded_file.class).to eq FileWithMetadata
      end
    end
  end

  context "finder" do
    subject { reloaded_page_image.primary_file }
    context "when no matching child is set" do
      before { page_image.files.build }
      it { is_expected.to be_nil }
    end
    context "when a matching object is directly contained" do
      before do
        a_file.content = "I'm a file"
        primary_file.content = "I am too"
        page_image.save!
      end
      it { is_expected.to eq primary_file }
    end
    context "if class_name is set" do
      before do
        a_file.content = "I'm a file"
        alternative_file.content = "I am too"
        page_image.save!
      end
      subject(:reloaded_file) { reloaded_page_image.alternative_file }
      it "uses the specified class to load objects" do
        expect(reloaded_file).to eq alternative_file
        expect(reloaded_file).to be_instance_of AlternativeFileWithMetadata
      end
    end
  end

  describe "setter" do
    before do
      a_file.content = "I'm a file"
      primary_file.content = "I am too"
      page_image.save!
    end
    subject(:reloaded_file) { reloaded_page_image.files }
    it "replaces existing record without disturbing the other contents of the container" do
      replacement_file = page_image.primary_file = FileWithMetadata.new
      replacement_file.content = "I'm a replacement"
      page_image.save
      expect(reloaded_file).to_not include(primary_file)
      expect(reloaded_file).to contain_exactly(a_file, replacement_file)
      expect(reloaded_page_image.primary_file).to eq(replacement_file)
    end
  end
end
