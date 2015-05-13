require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      property :publisher, predicate: ::RDF::DC.publisher
    end
    class Library < ActiveFedora::Base
    end
    class Book < ActiveFedora::Base
      belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
      has_metadata "foo", type: ActiveFedora::SimpleDatastream do |m|
        m.field "title", :string
      end
      has_metadata "bar", type: MyDatastream
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :title, datastream: 'foo' # Om backed property
        has_attributes :publisher, datastream: 'bar' # RDF backed property
      end
    end
  end

  let (:library) { Library.create }
  subject { Book.new(library: library, title: "War and Peace", publisher: "Random House") }

  after do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :MyDatastream)
  end

  it "should assert a content model" do
    expect(subject.has_model).to eq ['Book']
  end

  describe "initialize with a block" do
    subject { Book.new { |b| b.title= "The Sun also Rises" } }

    it "should have set the title" do
      expect(subject.title).to eq "The Sun also Rises"
    end
  end


  describe "#freeze" do
    before { subject.freeze }

    it "should be frozen" do
      expect(subject).to be_frozen
    end

    it "should make the associations immutable" do
      expect {
        subject.library_id = Library.create!.id
      }.to raise_error RuntimeError, "can't modify frozen Book"
      expect(subject.library_id).to eq library.id
    end

    describe "when the association is set via an id" do
      subject {Book.new(library_id: library.id)}
      it "should be able to load the association" do
        expect(subject.library).to eq library
      end
    end

    it "should make the om properties immutable" do
      expect {
        subject.title = "HEY"
      }.to raise_error RuntimeError, "can't modify frozen ActiveFedora::SimpleDatastream"
      expect(subject.title).to eq "War and Peace"
    end

    it "should make the RDF properties immutable" do
      expect {
        subject.publisher = "HEY"
      }.to raise_error TypeError
      expect(subject.publisher).to eq "Random House"
    end

  end

  describe "an object that hasn't loaded the associations" do
    before {subject.save! }

    it "should access associations" do
      f = Book.find(subject.id)
      f.freeze
      expect(f.library_id).to_not be_nil

    end
  end
end
