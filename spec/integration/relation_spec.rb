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

  subject { Library.all }

  it "is a relation" do
    expect(subject.class).to be ActiveFedora::Relation
  end

  it "is enumerable" do
    expect(subject).to respond_to(:each_with_index)
  end

  context "when some records exist" do
    before do
      Library.create
    end

    let!(:library1) { Library.create }

    describe "is cached" do
      before do
        subject.to_a # trigger initial load
      end

      it "should be loaded" do
        expect(subject).to be_loaded
      end
      it "shouldn't reload" do
        expect_any_instance_of(ActiveFedora::Relation).to_not receive :find_each
        subject[0]
      end
    end

    describe "#find" do
      it "should find one of them" do
        expect(subject.find(library1.id)).to eq library1
      end
      it "should find with a block" do
        expect(subject.find { |l| l.id == library1.id}).to eq library1
      end
    end

    describe "#select" do
      it "should find with a block" do
        expect(subject.select { |l| l.id == library1.id}).to eq [library1]
      end
    end

    context "unpermitted methods" do
      it "excludes them" do
        expect{ subject.sort! }.to raise_error NoMethodError
      end
    end

    context "when limit is applied" do
      subject { Library.create books: [Book.create, Book.create] }
      it "limits the number of books" do
        expect(subject.books.limit(1).size).to eq 1
      end
    end
  end
end
