require 'spec_helper'

describe ActiveFedora::SparqlInsert do
  let(:change_set) { ActiveFedora::ChangeSet.new(base, base.resource, base.changed_attributes.keys) }
  subject { ActiveFedora::SparqlInsert.new(change_set.changes) }

  context "with a changed object" do
    before do
      class Library < ActiveFedora::Base
      end

      class Book < ActiveFedora::Base
        belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
        property :title, predicate: ::RDF::DC.title
      end

      base.library_id = 'foo'
      base.title = ['bar']
    end
    after do
      Object.send(:remove_const, :Library)
      Object.send(:remove_const, :Book)
    end

    let(:base) { Book.create }


    it "should return the string" do
      expect(subject.build).to eq "DELETE { <> <info:fedora/fedora-system:def/relations-external#hasConstituent> ?change . }\n  WHERE { <> <info:fedora/fedora-system:def/relations-external#hasConstituent> ?change . } ;\nDELETE { <> <http://purl.org/dc/terms/title> ?change . }\n  WHERE { <> <http://purl.org/dc/terms/title> ?change . } ;\nINSERT { \n<> <info:fedora/fedora-system:def/relations-external#hasConstituent> <http://localhost:8983/fedora/rest/test/foo> .\n<> <http://purl.org/dc/terms/title> \"bar\" .\n}\n WHERE { }"
    end
  end
end
