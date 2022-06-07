# frozen_string_literal: true
require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class Library < ActiveFedora::Base
      has_many :books
    end

    class Book < ActiveFedora::Base
      belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end
  end

  after :all do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end

  subject(:libraries) { Library.all }

  before do
    libraries.destroy_all
  end

  it "is a relation" do
    expect(libraries.class).to be ActiveFedora::Relation
  end

  it { is_expected.to respond_to(:each_with_index) }
  it { expect(libraries.any?).to eq false }
  it { is_expected.to be_blank }
  it { is_expected.to be_empty }
  it { is_expected.not_to be_present }

  context "when some records exist" do
    before do
      Library.create
    end

    let!(:library1) { Library.create }

    describe "is cached" do
      before do
        libraries.to_a # trigger initial load
      end

      it { is_expected.to be_loaded }

      it "does not reload" do
        expect_any_instance_of(ActiveFedora::Relation).to_not receive :find_each
        libraries[0]
      end

      it "does not reload" do
        expect_any_instance_of(ActiveFedora::Relation).to_not receive :find_each
        libraries.each(&:id)
      end
    end

    it { expect(libraries.any?).to eq true }
    it { is_expected.not_to be_blank }
    it { is_expected.not_to be_empty }
    it { is_expected.to be_present }

    describe '#each' do
      before { Book.create }

      it 'returns an enumerator' do
        expect(libraries.each).to be_a Enumerator
      end

      it 'yields the items' do
        expect { |b| libraries.each(&b) }
          .to yield_successive_args(*Library.all.to_a)
      end

      context 'when called from ActiveFedora::Base' do
        let(:items) { ActiveFedora::Base.all }
        let(:books) { Book.all }
        let(:yielded) { items.each.to_a }
        let(:yielded_books) do
          yielded.select { |e| e.is_a?(Book) }
        end
        let(:yielded_libraries) do
          yielded.select { |e| e.is_a?(Library) }
        end

        it 'yields all items' do
          expect(yielded_books.length).to eq(books.length)
          expect(yielded_libraries.length).to eq(libraries.length)
        end
      end

      context 'when cached' do
        it 'returns an enumerator' do
          expect(libraries.each).to be_a Enumerator
        end

        it 'yields the items' do
          expect { |b| libraries.each(&b) }
            .to yield_successive_args(*Library.all.to_a)
        end
      end
    end

    describe "#find" do
      it "finds one of them" do
        expect(libraries.find(library1.id)).to eq library1
      end
      it "finds with a block" do
        expect(libraries.find { |l| l.id == library1.id }).to eq library1
      end
    end

    describe "#select" do
      it "finds with a block" do
        expect(libraries.select { |l| l.id == library1.id }).to eq [library1]
      end
    end

    context "unpermitted methods" do
      it "excludes them" do
        expect { libraries.sort! }.to raise_error NoMethodError
      end
    end

    context "when limit is applied" do
      let(:book2) { Book.create }
      let(:book1) { Book.create }
      let(:library) { Library.create books: [book1, book2] }

      before do
        book1
        book2
        library
      end

      after do
        library.destroy
        book2
        book1
      end

      it "limits the number of books" do
        expect(library.books.limit(1).size).to eq 1
      end
    end
  end
end
