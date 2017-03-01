require 'spec_helper'

describe ActiveFedora::ModelClassifier do
  module ParentClass
    class SiblingClass
    end
    class OtherSiblingClass
    end
    class SubclassClass < SiblingClass
    end
  end

  subject(:classifier) { described_class.new class_names }
  let(:class_names) { ["ParentClass::SiblingClass", "ParentClass::OtherSiblingClass", "ParentClass::SubclassClass", "ParentClass::NoSuchClass"] }

  describe ".class_from_string" do
    it "returns class constants based on strings" do
      expect(described_class.class_from_string("String")).to eq String
      expect(described_class.class_from_string("ActiveFedora::RDF::IndexingService")).to eq ActiveFedora::RDF::IndexingService
      expect(described_class.class_from_string("IndexingService", ActiveFedora::RDF)).to eq ActiveFedora::RDF::IndexingService
    end

    it "finds sibling classes" do
      expect(described_class.class_from_string("SiblingClass", ParentClass::OtherSiblingClass)).to eq ParentClass::SiblingClass
    end

    it "raises a NameError if the class isn't found" do
      expect {
        described_class.class_from_string("FooClass", ParentClass::OtherSiblingClass)
      }.to raise_error NameError, /uninitialized constant (Object::)?FooClass/
    end
  end

  describe '#models' do
    it 'converts class names to classes' do
      expect(classifier.models).to match_array [ParentClass::SiblingClass, ParentClass::OtherSiblingClass, ParentClass::SubclassClass]
    end
  end

  describe '#best_model' do
    it 'selects the most specific matching model' do
      expect(classifier.best_model(default: nil)).to eq ParentClass::SubclassClass
    end

    it 'filters models to subclasses of the default' do
      expect(classifier.best_model(default: ActiveFedora::Base)).to eq ActiveFedora::Base
    end
  end
end
