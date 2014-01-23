require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      property :publisher, :predicate => RDF::DC.publisher
    end
    class Library < ActiveFedora::Base
    end
    class Book < ActiveFedora::Base
      belongs_to :library, property: :has_constituent
      has_metadata "foo", type: ActiveFedora::SimpleDatastream do |m|
        m.field "title", :string
      end
      has_metadata "bar", type: MyDatastream
      has_attributes :title, datastream: 'foo' # Om backed property
      has_attributes :publisher, datastream: 'bar' # RDF backed property
    end
    subject.library = library
  end
  let (:library) { Library.create }
  subject {Book.new(library: library, title: "War and Peace", publisher: "Random House")}
  after do 
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Library)
  end

  describe "#freeze" do
    before { subject.freeze }

    it "should be frozen" do
      expect(subject).to be_frozen
    end

    it "should make the associations immutable" do
      expect {
        subject.library_id = Library.create!.pid
      }.to raise_error RuntimeError, "can't modify frozen Book"
      expect(subject.library_id).to eq library.pid
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
      f.library_id.should_not be_nil

    end
  end
end
