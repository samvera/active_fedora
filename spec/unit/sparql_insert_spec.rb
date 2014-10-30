require 'spec_helper'

describe ActiveFedora::SparqlInsert do
  subject { ActiveFedora::SparqlInsert.new(base) }

  context "with an unchanged object" do
    let(:base) { ActiveFedora::Base.new }
    it "should return the string" do
      expect(subject.build).to eq "DELETE { \n\n}\nWHERE { \n\n} ;INSERT { \n\n}\n WHERE { }"
    end
    it { should be_empty }
  end

  context "with a changed object" do
    before do
      class Library < ActiveFedora::Base
      end

      class Book < ActiveFedora::Base
        belongs_to :library, property: :has_constituent
        property :title, predicate: RDF::DC.title
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
      expect(subject.build).to eq "DELETE { \n<> <http://fedora.info/definitions/v4/rels-ext#hasConstituent> ?a0 .\n<> <http://purl.org/dc/terms/title> ?a1 .\n}\nWHERE { \n<> <http://fedora.info/definitions/v4/rels-ext#hasConstituent> ?a0 .\n<> <http://purl.org/dc/terms/title> ?a1 .\n} ;INSERT { \n<> <http://fedora.info/definitions/v4/rels-ext#hasConstituent> <http://localhost:8983/fedora/rest/test/foo> .\n<> <http://purl.org/dc/terms/title> \"bar\" .\n}\n WHERE { }"
    end
    it { should_not be_empty }
  end
end
