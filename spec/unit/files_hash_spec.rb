require 'spec_helper'

describe ActiveFedora::FilesHash do
  before do
    class FilesContainer; end
    allow(FilesContainer).to receive(:child_resource_reflections).and_return(file: reflection)
    allow(container).to receive(:association).with(:file).and_return(association)
    allow(container).to receive(:undeclared_files).and_return([])
  end

  after { Object.send(:remove_const, :FilesContainer) }

  subject(:file_hash) { described_class.new(container) }
  let(:reflection) { instance_double(ActiveFedora::Reflection::MacroReflection) }
  let(:association) { instance_double(ActiveFedora::Associations::SingularAssociation, reader: object) }
  let(:object) { double('object') }
  let(:container) { FilesContainer.new }

  describe "#key?" do
    context 'when the key is present' do
      it "is true" do
        expect(file_hash.key?(:file)).to be true
      end
      it "returns true if a string is passed" do
        expect(file_hash.key?('file')).to be true
      end
    end

    context 'when the key is not present' do
      it "is false" do
        expect(file_hash.key?(:foo)).to be false
      end
    end
  end

  describe "#[]" do
    context 'when the key is present' do
      it "returns the object" do
        expect(file_hash[:file]).to eq object
      end
      it "returns the object if a string is passed" do
        expect(file_hash['file']).to eq object
      end
    end

    context 'when the key is not present' do
      it "is nil" do
        expect(file_hash[:foo]).to be_nil
      end
    end
  end
end
