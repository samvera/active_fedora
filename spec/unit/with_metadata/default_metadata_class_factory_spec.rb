require 'spec_helper'

describe ActiveFedora::WithMetadata::DefaultMetadataClassFactory do
  let(:parent) { double("Parent") }

  describe "default class attributes" do
    its(:metadata_base_class)    { is_expected.to eq(ActiveFedora::WithMetadata::MetadataNode) }
    its(:file_metadata_schemas)  { is_expected.to eq([ActiveFedora::WithMetadata::DefaultSchema]) }
    its(:file_metadata_strategy) { is_expected.to eq(ActiveFedora::WithMetadata::DefaultStrategy) }
  end

  describe "::build" do
    it "sets MetadataNode to the default schema using the default strategy" do
      expect(parent).to receive(:const_set)
      expect(parent).to receive(:delegate).at_least(8).times
      subject.class.build(parent)
    end
  end
end
