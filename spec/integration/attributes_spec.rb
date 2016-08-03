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
      subject(:index_config) { RdfObject.index_config }
      it "has configuration" do
        expect(index_config[:resource_type].behaviors).to eq [:stored_searchable, :facetable]
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

      subject(:index_config) { InheritedObject.index_config }

      it "has configuration" do
        expect(index_config[:resource_type].behaviors).to eq [:stored_searchable, :facetable]
      end

      context "when the inherited config is modifed" do
        before do
          InheritedObject.index_config[:resource_type].behaviors.delete(:stored_searchable)
        end
        subject(:index_config) { RdfObject.index_config }

        it "the parent config is unchanged" do
          expect(index_config[:resource_type].behaviors).to eq [:stored_searchable, :facetable]
        end
      end
    end
  end

  describe "previous_changes" do
    subject(:titled_object) { TitledObject.create(title: ["Hydra for Dummies"]) }
    it "keeps a list of changes after a successful save" do
      expect(titled_object.previous_changes).to_not be_empty
      expect(titled_object.previous_changes.keys).to include("title")
    end
  end

  describe "#changes" do
    let(:titled_object) { TitledObject.create(title: ["Hydra for Dummies"]) }
    it "cleans out changes" do
      expect(titled_object).to_not be_title_changed
      expect(titled_object.changes).to be_empty
    end
  end
end
