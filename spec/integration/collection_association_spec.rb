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
  after do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end
  describe "load_from_solr" do
    before do
      @library = Library.create
      3.times { @library.books << Book.create }
    end
    after do
      @library.books.each { |b| b.delete }
      @library.delete
    end
    it "should set rows to count, if not specified" do
      @library.books(response_format: :solr).size.should == 3
    end
    it "should limit rows returned if option passed" do
      @library.books(response_format: :solr, rows: 1).size.should == 1
    end
  end

  describe "#delete_all" do
    before do
      @library = Library.create!
      @book1 = Book.create!(library: @library)
      @book2 = Book.create!(library: @library)
    end
    it "should delete em" do
      expect {
        @library.books.delete_all
      }.to change { @library.books.count}.by(-2)
    end
  end

  describe "#destroy_all" do
    before do
      @library = Library.create!
      @book1 = Book.create!(library: @library)
      @book2 = Book.create!(library: @library)
    end
    it "should delete em" do
      expect {
        @library.books.destroy_all
      }.to change { @library.books.count}.by(-2)
    end
  end
end
