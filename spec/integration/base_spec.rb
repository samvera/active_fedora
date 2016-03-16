require 'spec_helper'

describe ActiveFedora::Base do
  describe "A base object with metadata" do
    before :each do
      class MockAFBaseRelationship < ActiveFedora::Base
        has_metadata 'foo', type: Hydra::ModsArticleDatastream
      end
    end
    after :each do
      Object.send(:remove_const, :MockAFBaseRelationship)
    end
    describe "a new document" do
      before do
        @obj = MockAFBaseRelationship.new

        @obj.foo.person = "bob"
        @obj.save
      end

      it "saves the datastream." do
        obj = described_class.find(@obj.id)
        expect(obj.foo).to_not be_new_record
        expect(obj.foo.person).to eq ['bob']
        person_field = ActiveFedora.index_field_mapper.solr_name('foo__person', type: :string)
        solr_result = ActiveFedora::SolrService.query("{!raw f=id}#{@obj.id}", fl: "id #{person_field}").first
        expect(solr_result).to eq("id" => @obj.id, person_field => ['bob'])
      end
    end

    describe "that already exists in the repo" do
      before do
        @release = MockAFBaseRelationship.create
        @release.foo.person = "test foo content"
        @release.save
      end
      describe "and has been changed" do
        before do
          @release.foo.person = 'frank'
          @release.save!
        end
        it "saves the datastream." do
          expect(MockAFBaseRelationship.find(@release.id).foo.person).to eq ['frank']
          person_field = ActiveFedora.index_field_mapper.solr_name('foo__person', type: :string)
          expect(ActiveFedora::SolrService.query("id:\"#{@release.id}\"", fl: "id #{person_field}").first).to eq("id" => @release.id, person_field => ['frank'])
        end
      end
      describe "when trying to create it again" do
        it "raises an error" do
          expect { MockAFBaseRelationship.create(id: @release.id) }.to raise_error(ActiveFedora::IllegalOperation, "Attempting to recreate existing ldp_source: `#{@release.uri}'")
          @release.reload
          expect(@release.foo.person).to include('test foo content')
        end
      end
    end

    describe '#reload' do
      before do
        @object = MockAFBaseRelationship.new
        @object.foo.person = 'bob'
        @object.save

        @object2 = @object.class.find(@object.id)

        @object2.foo.person = 'dave'
        @object2.save
      end

      it 'requeries Fedora' do
        @object.reload
        expect(@object.foo.person).to eq ['dave']
      end

      it 'raises an error if not persisted' do
        @object = MockAFBaseRelationship.new
        expect { @object.reload }.to raise_error(ActiveFedora::ObjectNotFoundError)
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

    describe "errors" do
      subject { obj.errors }
      it { should be_empty }
    end

    describe "id" do
      subject { obj.id }
      it { should_not be_nil }
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
      it { should_not be_nil }
    end

    describe "#modified_date" do
      subject { obj.modified_date }
      it { should_not be_nil }
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
      expect(described_class.exists?('test:missing_object')).to be false
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
          allow(ActiveFedora::SolrService).to receive(:query) { [double("solr document")] }
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
    subject { TestBase.new }
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
      expect(subject.resource.class.ancestors).to include TestResource
    end
  end
end
