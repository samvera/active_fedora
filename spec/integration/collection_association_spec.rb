require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Library < ActiveFedora::Base
      has_many :books
    end
    class Book < ActiveFedora::Base
      belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
    end
  end

  let(:library) { Library.create! }
  let!(:book1) { Book.create!(library: library) }
  let!(:book2) { Book.create!(library: library) }

  after do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end

  describe "load_from_solr" do
    it "should set rows to count, if not specified" do
      expect(library.books(response_format: :solr).size).to eq 2
    end

    it "should limit rows returned if option passed" do
      expect(library.books(response_format: :solr, rows: 1).size).to eq 1
    end

    it "should not query solr if rows is 0" do
      expect(ActiveFedora::SolrService).not_to receive(:query)
      expect(library.books(response_format: :solr, rows: 0)).to eq []
    end
  end

  describe "#delete_all" do
    it "should delete em" do
      expect {
        library.books.delete_all
      }.to change { library.books.count }.by(-2)
    end
  end

  describe "#delete" do
    context "when given items not in collection" do
      it "should return an empty set" do
        expect(library.books.delete(Book.new)).to eq []
      end
      it "should not act on it" do
        b = Book.new
        allow(b).to receive(:persisted?).and_return(true)

        library.books.delete(b)

        expect(b).not_to have_received(:persisted?)
      end
    end
  end

  describe "#destroy_all" do
    it "should delete em" do
      expect {
        library.books.destroy_all
      }.to change { library.books.count }.by(-2)
    end
  end

  describe "#find" do
    it "should find the record that matches" do
      expected = library.books.find(book1.id)
      expect(expected).to eq book1
    end
    describe "with some records that aren't part of the collection" do
      let!(:book3) { Book.create }
      it "should find no records" do
        expect(library.books.find(book3.id)).to be_nil
      end
    end
  end

  describe "#select" do
    # TODO: Bug described in issue #609
    xit "should choose a subset of objects in the relationship" do
      expect(library.books.select([:id])).to include(book1.id)
    end
    it "should work as a block" do
      expect(library.books.select{|x| x.id == book1.id}).to eq [book1]
    end
  end

  describe "finding the inverse" do
    context "when no inverse exists" do
      before do
        class Item < ActiveFedora::Base
        end
        class SpecContainer < ActiveFedora::Base
          has_many :items
        end
      end
      after do
        Object.send(:remove_const, :Item)
        Object.send(:remove_const, :SpecContainer)
      end

      let(:instance) { SpecContainer.new }
      subject { instance.items }

      it "raises an error" do
        expect { subject }.to raise_error "No :inverse_of or :predicate attribute was set or could be inferred for has_many :items on SpecContainer"
      end
    end

    context "when classes are namespaced" do
      before do
        class Item < ActiveFedora::Base
          has_and_belongs_to_many :container, predicate: ::RDF::DC.extent, class_name: 'Foo::Container'
        end
        module Foo
          class Container < ActiveFedora::Base
            has_many :items
          end
        end
      end
      after do
        Object.send(:remove_const, :Item)
        Object.send(:remove_const, :Foo)
      end

      let(:instance) { Foo::Container.new }
      subject { instance.items }

      it "finds the association" do
        expect(subject).to eq []
      end
    end
  end
end
