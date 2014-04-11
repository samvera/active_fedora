require "spec_helper"
describe ActiveFedora::Rdf::Properties do
  before do
    class DummyProperties
      extend ActiveFedora::Rdf::Properties
    end
  end

  after do
    Object.send(:remove_const, "DummyProperties")
  end

  describe '#map_predicates' do
    before do
      DummyProperties.map_predicates do |map|
        map.title(:in => RDF::DC, :class_name => RDF::Literal) do |index|
          index.as :facetable, :searchable
        end
      end
    end

    it 'should set a property' do
      expect(DummyProperties.properties).to include :title
    end

    it "should set index behaviors" do
      expect(DummyProperties.properties[:title][:behaviors]).to eq [:facetable, :searchable]
    end

    it "should set a class name" do
      expect(DummyProperties.properties[:title][:class_name]).to eq RDF::Literal
    end
  end

  describe '#property' do
    it 'should set a property' do
      DummyProperties.property :title, :predicate => RDF::DC.title
      expect(DummyProperties.properties).to include :title
    end

    it 'should set index behaviors' do
      DummyProperties.property :title, :predicate => RDF::DC.title do |index|
        index.as :facetable, :searchable
      end
      expect(DummyProperties.properties[:title][:behaviors]).to eq [:facetable, :searchable]
    end

    it 'should set class name' do
      DummyProperties.property :title, :predicate => RDF::DC.title, :class_name => RDF::Literal
      expect(DummyProperties.properties[:title][:class_name]).to eq RDF::Literal
    end

    it "should constantize string class names" do
      DummyProperties.property :title, :predicate => RDF::DC.title, :class_name => "RDF::Literal"
      expect(DummyProperties.properties[:title][:class_name]).to eq RDF::Literal
    end

    it "should keep strings which it can't constantize as strings" do
      DummyProperties.property :title, :predicate => RDF::DC.title, :class_name => "FakeClassName"
      expect(DummyProperties.properties[:title][:class_name]).to eq "FakeClassName"
    end

  end

  context "when using a subclass" do
    before do
      DummyProperties.property :title, :predicate => RDF::DC.title
      class DummySubClass < DummyProperties
        property :source, :predicate => RDF::DC11[:source]
      end
    end

    after do
      Object.send(:remove_const, "DummySubClass")
    end

    it 'should carry properties from superclass' do
      expect(DummySubClass.properties.keys).to eq ["title", "source"]
    end
  end
end
