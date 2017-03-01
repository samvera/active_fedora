require 'spec_helper'

describe ActiveFedora::SparqlInsert do
  subject(:sparql_insert) { described_class.new(change_set.changes) }
  let(:change_set) { ActiveFedora::ChangeSet.new(base, base.resource, base.changed_attributes.keys) }

  context "with a changed object" do
    before do
      class Library < ActiveFedora::Base
      end

      class Book < ActiveFedora::Base
        belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
        property :title, predicate: ::RDF::Vocab::DC.title
      end

      base.library_id = 'foo'
      base.title = ['bar']
    end
    after do
      Object.send(:remove_const, :Library)
      Object.send(:remove_const, :Book)
    end

    let(:base) { Book.create }

    it "returns the string" do
      expect(sparql_insert.build).to eq "DELETE { <> <info:fedora/fedora-system:def/relations-external#hasConstituent> ?change . }\n  WHERE { <> <info:fedora/fedora-system:def/relations-external#hasConstituent> ?change . } ;\nDELETE { <> <http://purl.org/dc/terms/title> ?change . }\n  WHERE { <> <http://purl.org/dc/terms/title> ?change . } ;\nINSERT { \n<> <info:fedora/fedora-system:def/relations-external#hasConstituent> <#{ActiveFedora.fedora.host}/test/foo> .\n<> <http://purl.org/dc/terms/title> \"bar\" .\n}\n WHERE { }"
    end
  end
end
