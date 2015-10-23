require 'spec_helper'

describe ActiveFedora::Base do
  describe '.attach_file' do
    let(:test_object) { described_class.new }
    let(:ds) { ActiveFedora::File.new(@test_object, 'ds_to_add') }

    it "does not call File.save" do
      expect(ds).to receive(:save).never
      test_object.attach_file(ds, 'ds1')
    end

    it "adds the datastream to the datastreams_in_memory array" do
      expect(test_object.attached_files).to_not have_key(:ds_to_add)
      test_object.attach_file(ds, 'ds_to_add')
      expect(test_object.attached_files).to have_key(:ds_to_add)
    end
  end
end
