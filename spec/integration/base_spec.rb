require 'spec_helper'

describe ActiveFedora::Base do
  describe '#reload' do
    before do
      class Foo < ActiveFedora::Base
        property :person, predicate: ::RDF::Vocab::DC.creator
      end
    end
    after do
      Object.send(:remove_const, :Foo)
    end
    context "when persisted" do
      let(:object) { Foo.create(person: ['bob']) }
      let(:object2) { Foo.find(object.id) }
      before do
        object2.update(person: ['dave'])
      end

      it 're-queries Fedora' do
        object.reload
        expect(object.person).to eq ['dave']
      end
    end

    context "when not persisted" do
      let(:object) { Foo.new }
      it 'raises an error' do
        expect { object.reload }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end

  describe "a saved object" do
    before do
      class Book < ActiveFedora::Base
        type [::RDF::URI("http://www.example.com/Book")]
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end

    after do
      Object.send(:remove_const, :Book)
    end
    let!(:obj) { Book.create }

    after { obj.destroy unless obj.destroyed? }

    describe "#errors" do
      subject { obj.errors }
      it { is_expected.to be_empty }
    end

    describe "#id" do
      subject { obj.id }
      it { is_expected.to_not be_nil }
    end

    context "when updated with changes after one second" do
      before do
        obj.title = ['sample']
        sleep 1
      end

      it 'updates the modification time field in solr' do
        expect { obj.save }.to change {
          ActiveFedora::SolrService.query("id:\"#{obj.id}\"").first['system_modified_dtsi']
        }
      end
    end

    describe "#create_date" do
      subject { obj.create_date }
      it { is_expected.to_not be_nil }
    end

    describe "#modified_date" do
      subject { obj.modified_date }
      it { is_expected.to_not be_nil }
    end

    describe "delete" do
      it "deletes the object from Fedora and Solr" do
        expect {
          obj.delete
        }.to change { described_class.exists?(obj.id) }.from(true).to(false)
      end
    end

    describe "#type" do
      subject { obj.type }
      it { is_expected.to include(::RDF::URI("http://www.example.com/Book")) }
      context "when adding additional types" do
        before do
          t = obj.get_values(:type)
          t << ::RDF::URI("http://www.example.com/Novel")
          obj.set_value(:type, t)
        end
        it { is_expected.to include(::RDF::URI("http://www.example.com/Novel")) }
      end
    end
  end

  describe "#apply_schema" do
    before do
      class ExampleSchema < ActiveTriples::Schema
        property :title, predicate: RDF::Vocab::DC.title
      end
      class ExampleBase < ActiveFedora::Base
        apply_schema ExampleSchema, ActiveFedora::SchemaIndexingStrategy.new(ActiveFedora::Indexers::GlobalIndexer.new(:symbol))
      end
    end
    after do
      Object.send(:remove_const, :ExampleSchema)
      Object.send(:remove_const, :ExampleBase)
    end
    let(:obj) { ExampleBase.new }
    it "configures properties and solrize them" do
      obj.title = ["Test"]
      expect(obj.to_solr[ActiveFedora.index_field_mapper.solr_name("title", :symbol)]).to eq ["Test"]
    end
  end

  describe "#exists?" do
    let(:obj) { described_class.create }
    it "returns true for objects that exist" do
      expect(described_class.exists?(obj)).to be true
    end
    it "returns true for ids that exist" do
      expect(described_class.exists?(obj.id)).to be true
    end
    it "returns false for ids that don't exist" do
      expect(described_class.exists?('test_missing_object')).to be false
    end
    it "returns false for nil" do
      expect(described_class.exists?(nil)).to be false
    end
    it "returns false for false" do
      expect(described_class.exists?(false)).to be false
    end
    it "returns false for empty" do
      expect(described_class.exists?('')).to be false
    end
    context "when passed a hash of conditions" do
      let(:conditions) { { foo: "bar" } }
      context "and at least one object matches the conditions" do
        it "returns true" do
          allow(ActiveFedora::SolrService).to receive(:query) { [instance_double(RSolr::HashWithResponse)] }
          expect(described_class.exists?(conditions)).to be true
        end
      end
      context "and no object matches the conditions" do
        it "returns false" do
          allow(ActiveFedora::SolrService).to receive(:query) { [] }
          expect(described_class.exists?(conditions)).to be false
        end
      end
    end
  end

  describe "overriding resource_class_factory" do
    subject(:test_base) { TestBase.new }
    before do
      class TestResource < ActiveTriples::Resource
      end
      class TestBase < ActiveFedora::Base
        def self.resource_class_factory
          TestResource
        end
      end
    end
    after do
      Object.send(:remove_const, :TestResource)
      Object.send(:remove_const, :TestBase)
    end
    it "uses that factory for #resource" do
      expect(test_base.resource.class.ancestors).to include TestResource
    end
  end
end
