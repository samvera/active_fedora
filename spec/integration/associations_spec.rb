require 'spec_helper'

class Library < ActiveFedora::Base 
  has_many :books, :property=>:has_collection_member
end

class Book < ActiveFedora::Base 
  belongs_to :library, :property=>:has_collection_member
end

describe ActiveFedora::Base do
  describe "an unsaved instance" do
    before do
      @library = Library.new()
      @book = Book.new
      @book.save
    end

    it "should have many books" do
      @library.new_record?.should be_true
      @library.books.size == 0
      @library.books.to_ary.should == []
      @library.book_ids.should ==[]
      @library.books << @book
      @library.books.map(&:pid).should == [@book.pid]
      @library.book_ids.should ==[@book.pid]
    end
    after do
      @book.delete
    end
  end


  describe "a saved instance" do
    before do
      @library = Library.new()
      @library.save()
      @book = Book.new
      @book.save
    end
    it "should have many books once it has been saved" do
      @library.save
      @library.books << @book

      @book.library.pid.should == @library.pid
      @library.books.reload
      @library.books.map(&:pid).should == [@book.pid]


      @library2 = Library.find(@library.pid)
      @library2.books.map(&:pid).should == [@book.pid]

    
    end
    after do
      @library.delete
      @book.delete
    end
  end




end
