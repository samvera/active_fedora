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

  it "is a relation" do
    expect(libraries.class).to be ActiveFedora::Relation
  end

  it { is_expected.to respond_to(:each_with_index) }

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
      subject(:libraries) { Library.create books: [Book.create, Book.create] }
      it "limits the number of books" do
        expect(libraries.books.limit(1).size).to eq 1
      end
    end
  end
end
