require 'spec_helper'

describe ActiveFedora::WithMetadata do
  before do
    class Sample < ActiveFedora::Base
      contains :file, class_name: 'SampleFile'
    end

    class SampleFile < ActiveFedora::File
      include ActiveFedora::WithMetadata

      metadata do
        property :title, predicate: ::RDF::DC.title
      end
    end
  end

  after do
    Object.send(:remove_const, :SampleFile)
    Object.send(:remove_const, :Sample)
  end

  let(:base) { Sample.new }
  let(:file) { base.file }

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
      file.content = "Hey"
      file.title = ["foo"]
      base.save
      base.reload
    end

    it "should save the metadata too" do
      expect(base.file.title).to eq ['foo']
    end
  end

end
