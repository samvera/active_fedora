require 'spec_helper'

describe "delegating attributes" do
  before :all do
    class TitledObject < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title
    end

    class RdfObject < ActiveFedora::Base
      property :resource_type, predicate: ::RDF::Vocab::DC.type do |index|
        index.as :stored_searchable, :facetable
      end
    end
  end

  after :all do
    Object.send(:remove_const, :TitledObject)
    Object.send(:remove_const, :RdfObject)
  end

  describe "#index_config" do
    context "on a class with properties" do
      subject { RdfObject.index_config }
      it "has configuration" do
        expect(subject[:resource_type].behaviors).to eq [:stored_searchable, :facetable]
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

  describe "previous_changes" do
    subject do
      TitledObject.create(title: ["Hydra for Dummies"])
    end
    it "keeps a list of changes after a successful save" do
      expect(subject.previous_changes).to_not be_empty
      expect(subject.previous_changes.keys).to include("title")
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
        expect(subject["depositor"]).to eq("foo")
        expect(subject["resource_type"]).to eq(["bar"])
      end
      specify "using symbols for keys" do
        expect(subject[:depositor]).to eq("foo")
        expect(subject[:resource_type]).to eq(["bar"])
      end
    end

    describe "setting attributes" do
      specify "using strings for keys" do
        subject["depositor"] = "foo"
        subject["resource_type"] = ["bar"]
        subject.save
        expect(subject.depositor).to eq("foo")
        expect(subject.resource_type).to eq(["bar"])
      end

      specify "using symbols for keys" do
        subject[:depositor] = "foo"
        subject[:resource_type] = ["bar"]
        subject.save
        expect(subject.depositor).to eq("foo")
        expect(subject.resource_type).to eq(["bar"])
      end

      # TODO: bug logged in issue #540
      describe "using shift", pending: "has_changed? not returning true" do
        specify "with rdf properties" do
          subject.resource_type << "bar"
          subject.save
          expect(subject.resource_type).to eq(["bar"])
        end
        specify "with om terms" do
          subject.wrangler << "bar"
          subject.save
          expect(subject.wrangler).to eql(["bar"])
        end
      end
    end
  end

  describe "#changes" do
    subject do
      TitledObject.create(title: ["Hydra for Dummies"])
    end
    it "cleans out changes" do
      expect(subject).to_not be_title_changed
      expect(subject.changes).to be_empty
    end
  end
end
