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
      @book2 = Book.new
      @book2.save
    end

    it "should let you shift onto the association" do
      @library.new_record?.should be_true
      @library.books.size == 0
      @library.books.to_ary.should == []
      @library.book_ids.should ==[]
      @library.books << @book
      @library.books.map(&:pid).should == [@book.pid]
      @library.book_ids.should ==[@book.pid]
    end

    it "should let you set an array of objects" do
      @library.books = [@book, @book2]
      @library.books.map(&:pid).should == [@book.pid, @book2.pid]
      @library.save

      @library.books = [@book]
      @library.books.map(&:pid).should == [@book.pid]
    
    end
    it "should let you set an array of object ids" do
      @library.book_ids = [@book.pid, @book2.pid]
      @library.books.map(&:pid).should == [@book.pid, @book2.pid]
    end
    after do
      @book.delete
      @book2.delete
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

  describe "setting belongs_to" do
    before do
      @library = Library.new()
      @library.save()
      @book = Book.new
    end
    it "should set the association" do
      @book.library = @library
      @book.library.pid.should == @library.pid
      @book.save


      Book.find(@book.pid).library.pid.should == @library.pid
      
    end
    it "should clear the association" do
      @book.library = @library
      @book.library = nil
      @book.save

      Book.find(@book.pid).library.should be_nil 
      
    end

    it "should replace the association" do
      @library2 = Library.new
      @library2.save
      @book.library = @library
      @book.save
      @book.library = @library2
      @book.save
      Book.find(@book.pid).library.pid.should == @library2.pid 

    end

    it "should be able to be set by id" do
      @book.library_id = @library.pid
      @book.library_id.should == @library.pid
      @book.library.pid.should == @library.pid
      @book.save
      Book.find(@book.pid).library_id.should == @library.pid
    end

    after do
      @library.delete
      @book.delete
      @library2.delete if @library2
    end
  end




end
