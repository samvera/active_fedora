require 'spec_helper'

describe ActiveFedora::WithMetadata::DefaultMetadataClassFactory do
  let(:parent) { class_double(ActiveFedora::File) }
  let(:object) { described_class.new }

  describe "default class attributes" do
    its(:metadata_base_class)    { is_expected.to eq(ActiveFedora::WithMetadata::MetadataNode) }
    its(:file_metadata_schemas)  { is_expected.to eq([ActiveFedora::WithMetadata::DefaultSchema]) }
    its(:file_metadata_strategy) { is_expected.to eq(ActiveFedora::WithMetadata::DefaultStrategy) }
  end

  describe "::build" do
    it "sets MetadataNode to the default schema using the default strategy" do
      expect(parent).to receive(:const_set)
      expect(parent).to receive(:delegate).with(:label, :label=, :label_changed?, to: :metadata_node)
      expect(parent).to receive(:delegate).with(:file_name, :file_name=, :file_name_changed?, to: :metadata_node)
      expect(parent).to receive(:delegate).with(:file_size, :file_size=, :file_size_changed?, to: :metadata_node)
      expect(parent).to receive(:delegate).with(:date_created, :date_created=, :date_created_changed?, to: :metadata_node)
      expect(parent).to receive(:delegate).with(:date_modified,
                                                :date_modified=,
                                                :date_modified_changed?,
                                                to: :metadata_node)
      expect(parent).to receive(:delegate).with(:byte_order, :byte_order=, :byte_order_changed?, to: :metadata_node)
      expect(parent).to receive(:delegate).with(:file_hash, :file_hash=, :file_hash_changed?, to: :metadata_node)
      object.class.build(parent)
    end
  end
end
