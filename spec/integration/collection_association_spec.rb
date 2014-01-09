require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Library < ActiveFedora::Base 
      has_many :books
    end
    class Book < ActiveFedora::Base
      belongs_to :library, property: :has_member
    end
  end
  let(:library) { Library.create! }
  let!(:book1) { Book.create!(library: library) }
  let!(:book2) { Book.create!(library: library) }
  after do
    Book.delete_all
    Library.delete_all
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end
  describe "load_from_solr" do
    it "should set rows to count, if not specified" do
      library.books(response_format: :solr).size.should == 2
    end
    it "should limit rows returned if option passed" do
      library.books(response_format: :solr, rows: 1).size.should == 1
    end
  end

  describe "#delete_all" do
    it "should delete em" do
      expect {
        library.books.delete_all
      }.to change { library.books.count }.by(-2)
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
end
