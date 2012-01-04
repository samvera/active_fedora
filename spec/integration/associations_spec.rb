require 'spec_helper'

class Library < ActiveFedora::Base 
  has_many :books, :property=>:has_constituent
end

class Book < ActiveFedora::Base 
  belongs_to :library, :property=>:has_constituent
  belongs_to :author, :property=>:has_member, :class_name=>'Person'
  has_and_belongs_to_many :topics, :property=>:is_topic_of
end

class Person < ActiveFedora::Base
end

class Topic < ActiveFedora::Base 
  has_and_belongs_to_many :books, :property=>:is_topic_of
end

describe ActiveFedora::Base do
  describe "an unsaved instance" do
    describe "of has_many" do
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
        @library.books.to_a.should == [@book]
        @library.book_ids.should ==[@book.pid]

      end

      it "should let you set an array of objects" do
        @library.books = [@book, @book2]
        @library.books.to_a.should == [@book, @book2]
        @library.save

        @library.books = [@book]
        @library.books.to_a.should == [@book]
      
      end
      it "should let you set an array of object ids" do
        @library.book_ids = [@book.pid, @book2.pid]
        @library.books.to_a.should == [@book, @book2]
      end

      it "setter should wipe out previously saved relations" do
        @library.book_ids = [@book.pid, @book2.pid]
        @library.book_ids = [@book2.pid]
        @library.books.to_a.should == [@book2]
        
      end



      after do
        @book.delete
        @book2.delete
      end
    end

    describe "of belongs to" do
      before do
        @library = Library.new()
        @library.save
        @book = Book.new
        @book.save
      end
      it "should be settable from the book side" do
        @book.library_id = @library.pid
        @book.library.pid.should == @library.pid
        @book.attributes= {:library_id => ""}
        @book.library_id.should be_nil
      end
      after do
        @library.delete
        @book.delete
      end
    end

    describe "of has_many_and_belongs_to" do
      before do
        @topic1 = Topic.new
        @topic1.save
        @topic2 = Topic.new
        @topic2.save
      end
      it "habtm should set relationships bidirectionally" do
        @book = Book.new
        @book.topics << @topic1
        @book.topics.map(&:pid).should == [@topic1.pid]
        Topic.find(@topic1.pid).books.to_a.should == [] #Can't have saved it because @book isn't saved yet.
      end
      after do
        @topic1.delete
        @topic2.delete
      end
    end
  end

  


  describe "a saved instance" do
    describe "of belongs_to" do
      before do
        @library = Library.new()
        @library.save()
        @book = Book.new
        @book.save
        @person = Person.new
        @person.save
      end
      it "should have many books once it has been saved" do
        @library.books << @book

        @book.library.pid.should == @library.pid
        @library.books.reload
        @library.books.to_a.should == [@book]

        @library2 = Library.find(@library.pid)
        @library2.books.to_a.should == [@book]
      end

      it "should have a count once it has been saved" do
        @library.books << @book << Book.create 
        @library.save

        # @book.library.pid.should == @library.pid
        # @library.books.reload
        # @library.books.to_a.should == [@book]

        @library2 = Library.find(@library.pid)
        @library2.books.size.should == 2
      end

      it "should respect the :class_name parameter" do
        @book.author = @person
        @book.save
        Book.find(@book.id).author_id.should == @person.pid
        Book.find(@book.id).author.send(:find_target).should be_kind_of Person
      end

      after do
        @library.delete
        @book.delete
      end
    end
    describe "of has_many_and_belongs_to" do
      before do
        @topic1 = Topic.new
        @topic1.save
        @topic2 = Topic.new
        @topic2.save
        @book = Book.new
        @book.save
      end
      it "habtm should set relationships bidirectionally" do
        @book.topics << @topic1
        @book.topics.to_a.should == [@topic1]
        Topic.find(@topic1.pid).books.to_a.should == [@book] #Can't have saved it because @book isn't saved yet.
      end
      it "should save new child objects" do
        @book.topics << Topic.new
        @book.topics.first.pid.should_not be_nil
      end
      it "should clear out the old associtions" do
        @book.topics = [@topic1]
        @book.topics = [@topic2]
        @book.topic_ids.should == [@topic2.pid]
      end
      after do
        @book.delete
        @topic1.delete
        @topic2.delete
      end
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
