require 'spec_helper'

describe "delegating attributes" do
  before :all do
    class PropertiesDatastream < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path: "fields")
        t.depositor index_as: [:symbol, :stored_searchable]
        t.wrangler index_as: [:facetable]
      end
    end
    class TitledObject < ActiveFedora::Base
      extend Deprecation

      Deprecation.silence(TitledObject) do
        has_metadata 'foo', type: ActiveFedora::SimpleDatastream do |m|
          m.field "title", :string
        end
      end
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :title, datastream: 'foo', multiple: false
      end
    end

    class RdfObject < ActiveFedora::Base
      has_subresource 'foo', class_name: 'PropertiesDatastream'
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :depositor, datastream: :foo, multiple: false do |index|
          index.as :stored_searchable
        end
        has_attributes :wrangler, datastream: :foo, multiple: true
      end
      property :resource_type, predicate: ::RDF::Vocab::DC.type do |index|
        index.as :stored_searchable, :facetable
      end
    end
  end

  after :all do
    Object.send(:remove_const, :TitledObject)
    Object.send(:remove_const, :RdfObject)
    Object.send(:remove_const, :PropertiesDatastream)
  end

  describe "#index_config" do
    context "on a class with properties" do
      subject { RdfObject.index_config }
      it "has configuration" do
        expect(subject[:resource_type].behaviors).to eq [:stored_searchable, :facetable]
        expect(subject[:depositor].behaviors).to eq [:stored_searchable]
      end
    end

    context "when a class inherits properties" do
      before do
        class InheritedObject < RdfObject
        end
      end

      after do
        Object.send(:remove_const, :InheritedObject)
      end

      subject { InheritedObject.index_config }

      it "has configuration" do
        expect(subject[:resource_type].behaviors).to eq [:stored_searchable, :facetable]
        expect(subject[:depositor].behaviors).to eq [:stored_searchable]
      end

      context "when the inherited config is modifed" do
        before do
          InheritedObject.index_config[:resource_type].behaviors.delete(:stored_searchable)
        end
        subject { RdfObject.index_config }

        it "the parent config is unchanged" do
          expect(subject[:resource_type].behaviors).to eq [:stored_searchable, :facetable]
        end
      end
    end
  end

  context "with a simple datastream" do
    describe "save" do
      subject do
        obj = TitledObject.create
        obj.title = "Hydra for Dummies"
        obj.save
        obj
      end
      it "keeps a list of changes after a successful save" do
        expect(subject.previous_changes).to_not be_empty
        expect(subject.previous_changes.keys).to include("title")
      end
      it "cleans out changes" do
        expect(subject).to_not be_title_changed
        expect(subject.changes).to be_empty
      end
    end
  end

  context "with multiple datastreams" do
    subject { RdfObject.create }

    describe "getting attributes" do
      before do
        subject.depositor = "foo"
        subject.resource_type = ["bar"]
        subject.save
      end

      specify "using strings for keys" do
        expect(subject["depositor"]).to eql("foo")
        expect(subject["resource_type"]).to eql(["bar"])
      end
      specify "using symbols for keys" do
        expect(subject[:depositor]).to eql("foo")
        expect(subject[:resource_type]).to eql(["bar"])
      end
    end

    describe "setting attributes" do
      specify "using strings for keys" do
        subject["depositor"] = "foo"
        subject["resource_type"] = ["bar"]
        subject.save
        expect(subject.depositor).to eql("foo")
        expect(subject.resource_type).to eql(["bar"])
      end

      specify "using symbols for keys" do
        subject[:depositor] = "foo"
        subject[:resource_type] = ["bar"]
        subject.save
        expect(subject.depositor).to eql("foo")
        expect(subject.resource_type).to eql(["bar"])
      end

      # TODO: bug logged in issue #540
      describe "using shift", pending: "has_changed? not returning true" do
        specify "with rdf properties" do
          subject.resource_type << "bar"
          subject.save
          expect(subject.resource_type).to eql(["bar"])
        end
        specify "with om terms" do
          subject.wrangler << "bar"
          subject.save
          expect(subject.wrangler).to eql(["bar"])
        end
      end
    end
  end

  describe 'dangerous attributes' do
    it 'raises an exception if a dangerous attribute is defined' do
      Deprecation.silence(ActiveFedora::Attributes) do
        expect { TitledObject.has_attributes :save, datastream: 'foo', multiple: false }.to raise_error ActiveFedora::DangerousAttributeError
      end
    end
  end
end
