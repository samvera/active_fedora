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

  after do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end

  describe "load_from_solr" do
    let!(:book1) { Book.create!(library: library) }
    let!(:book2) { Book.create!(library: library) }

    it "sets rows to count, if not specified" do
      expect(library.books(response_format: :solr).size).to eq 2
    end

    it "limits rows returned if option passed" do
      expect(library.books(response_format: :solr, rows: 1).size).to eq 1
    end

    it "does not query solr if rows is 0" do
      expect(ActiveFedora::SolrService).not_to receive(:query)
      expect(library.books(response_format: :solr, rows: 0)).to eq []
    end
  end

  describe "#delete_all" do
    let!(:book1) { Book.create!(library: library) }
    let!(:book2) { Book.create!(library: library) }
    it "deletes em" do
      expect {
        library.books.delete_all
      }.to change { library.books.count }.by(-2)
    end
  end

  describe "#delete" do
    context "when given items not in collection" do
      it "returns an empty set" do
        expect(library.books.delete(Book.new)).to eq []
      end
      it "does not act on it" do
        b = Book.new
        allow(b).to receive(:persisted?).and_return(true)

        library.books.delete(b)

        expect(b).not_to have_received(:persisted?)
      end
    end
  end

  describe "#destroy_all" do
    let!(:book1) { Book.create!(library: library) }
    let!(:book2) { Book.create!(library: library) }
    it "deletes em" do
      expect {
        library.books.destroy_all
      }.to change { library.books.count }.by(-2)
    end
  end

  describe "#find" do
    let!(:book1) { Book.create!(library: library) }
    let!(:book2) { Book.create!(library: library) }
    it "finds the record that matches" do
      expected = library.books.find(book1.id)
      expect(expected).to eq book1
    end
    describe "with some records that aren't part of the collection" do
      let!(:book3) { Book.create }
      it "finds no records" do
        expect(library.books.find(book3.id)).to be_nil
      end
    end
  end

  describe "#select" do
    let!(:book1) { Book.create!(library: library) }
    let!(:book2) { Book.create!(library: library) }

    # TODO: Bug described in issue #609
    xit "chooses a subset of objects in the relationship" do
      expect(library.books.select([:id])).to include(book1.id)
    end
    it "works as a block" do
      expect(library.books.select { |x| x.id == book1.id }).to eq [book1]
    end
  end

  describe "#size" do
    context "with associations in memory" do
      context "and the association is already loaded" do
        before do
          library.books.to_a # force the association to be loaded
          library.books.build
        end
        subject { library.books.size }
        it { is_expected.to eq 1 }
      end

      context "and the association is not loaded" do
        before do
          library.books.build
        end
        subject { library.books.size }
        it { is_expected.to eq 1 }
      end
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

      it "raises an error" do
        expect { instance.items }.to raise_error "No :inverse_of or :predicate attribute was set or could be inferred for has_many :items on SpecContainer"
      end
    end

    context "when classes are namespaced" do
      before do
        class Item < ActiveFedora::Base
          has_and_belongs_to_many :container, predicate: ::RDF::Vocab::DC.extent, class_name: 'Foo::Container'
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

      subject { instance.items }
      let(:instance) { Foo::Container.new }

      it { is_expected.to eq [] }
    end
  end
end
