require 'spec_helper'

describe ActiveFedora::Associations::FilterAssociation do
  before do
    class Image < ActiveFedora::Base
      ordered_aggregation :members, through: :list_source, class_name: 'ActiveFedora::Base'

      filters_association :members, as: :child_objects, condition: :pcdm_object?
      filters_association :members, as: :child_collections, condition: :pcdm_collection?
    end

    class TestObject < ActiveFedora::Base
      def pcdm_object?
        true
      end

      def pcdm_collection?
        false
      end
    end

    class TestCollection < ActiveFedora::Base
      def pcdm_object?
        false
      end

      def pcdm_collection?
        true
      end
    end
  end

  after do
    Object.send(:remove_const, :Image)
    Object.send(:remove_const, :TestObject)
    Object.send(:remove_const, :TestCollection)
  end

  let(:image) { Image.new }
  let(:test_object) { TestObject.new }
  let(:test_collection) { TestCollection.new }

  describe "setting" do
    context "when an incorrect object type is sent" do
      it "raises an error" do
        image.child_collections
        expect { image.child_collections = [test_object] }.to raise_error ArgumentError
      end
    end

    context "when the parent is already loaded" do
      let(:another_collection) { TestCollection.new }
      before do
        image.members = [test_object, test_collection]
        image.child_collections = [another_collection]
      end
      it "overwrites existing matches" do
        expect(image.members).to contain_exactly test_object, another_collection
      end
    end
  end

  describe "appending" do
    context "when an incorrect object type is sent" do
      it "raises an error" do
        expect { image.child_collections << test_object }.to raise_error ArgumentError
      end
    end

    context "when the parent is already loaded" do
      let(:another_collection) { TestCollection.new }
      before do
        image.members = [test_object, test_collection]
        image.child_collections << [another_collection]
      end

      it "updates the parent" do
        expect(image.members).to contain_exactly test_object, test_collection, another_collection
      end
    end
  end

  describe "#size" do
    it "returns the size" do
      # Need to persist so that count_records will be called.
      image.save
      test_object.save
      image.members = [test_object]

      expect(image.reload.child_objects.size).to eq 1
    end
  end

  describe "reading" do
    before do
      image.members = [test_object, test_collection]
    end

    it "returns the objects of the correct type" do
      expect(image.child_objects).to eq [test_object]
    end

    describe "when the parent association is changed" do
      before do
        image.child_objects = [test_object]
        image.child_objects.to_a # this would cause the @target of the association to be populated
        image.members = [test_collection]
      end

      it "updates the filtered relation" do
        expect(image.child_objects).to eq []
      end
    end

    describe "#_ids" do
      it "returns just the ids" do
        expect(image.child_object_ids).to eq [test_object.id]
      end
    end
  end

  describe "#delete" do
    subject { image.members }

    let(:another_object) { TestObject.new }
    before do
      image.members = [test_object, test_collection, another_object]
      image.child_objects.delete(test_object)
    end

    it { is_expected.to contain_exactly test_collection, another_object }
  end
end
