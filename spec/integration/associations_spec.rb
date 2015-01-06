require 'spec_helper'

class Library < ActiveFedora::Base
  has_many :books, :property=>:has_constituent
end

class Book < ActiveFedora::Base
  belongs_to :library, :property=>:has_constituent
  belongs_to :author, :property=>:has_member, :class_name=>'Person'
  has_and_belongs_to_many :topics, :property=>:has_topic, :inverse_of=>:is_topic_of
  has_and_belongs_to_many :collections, :property=>:is_member_of_collection
end

class Person < ActiveFedora::Base
end

class Collection < ActiveFedora::Base
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

      it "should build child" do
        new_book = @library.books.build({})
        expect(new_book).to be_new_record
        expect(new_book).to be_kind_of Book
        expect(new_book.library).to be_nil
        expect(@library.books).to eq([new_book])
        #TODO save the associated children too, requires something like ActiveRecord::AutosaveAssociation (ver 3.0.12)
        #@library.save
        #new_book.library.should == @library
      end

      it "should not create children if the parent isn't saved" do
        expect {@library.books.create({})}.to raise_error ActiveFedora::RecordNotSaved, "You cannot call create unless the parent is saved"
      end

      it "should create children" do
        @library.save!
        new_book = @library.books.create({})
        expect(new_book).not_to be_new_record
        expect(new_book).to be_kind_of Book
        expect(new_book.library).to eq(@library)
      end

      it "should build parent" do
        new_library = @book.build_library({})
        expect(new_library).to be_new_record
        expect(new_library).to be_kind_of Library
        expect(@book.library).to eq(new_library)
      end

      it "should create parent" do
        new_library = @book.create_library({})
        expect(new_library).not_to be_new_record
        expect(new_library).to be_kind_of Library
        expect(@book.library).to eq(new_library)
      end

      it "should let you shift onto the association" do
        expect(@library.new_record?).to be_truthy
        @library.books.size == 0
        expect(@library.books).to eq([])
        expect(@library.book_ids).to eq([])
        @library.books << @book
        expect(@library.books).to eq([@book])
        expect(@library.book_ids).to eq([@book.pid])

      end

      it "should let you set an array of objects" do
        @library.books = [@book, @book2]
        expect(@library.books).to eq([@book, @book2])
        @library.save

        @library.books = [@book]
        expect(@library.books).to eq([@book])

      end
      it "should let you set an array of object ids" do
        @library.book_ids = [@book.pid, @book2.pid]
        expect(@library.books).to eq([@book, @book2])
      end

      it "setter should wipe out previously saved relations" do
        @library.book_ids = [@book.pid, @book2.pid]
        @library.book_ids = [@book2.pid]
        expect(@library.books).to eq([@book2])

      end

      it "saving the parent should save the relationships on the children" do
        @library.save
        @library.books = [@book, @book2]
        @library.save
        @library = Library.find(@library.pid)
        expect(@library.books).to eq([@book, @book2])
      end


      it "should let you lookup an array of objects with solr" do
        @library.save
        @book.library = @library
        @book2.library = @library
        @book.save
        @book2.save

        @library = Library.find(@library.pid)
        expect(@library.books).to eq([@book, @book2])

        solr_resp =  @library.books(:response_format=>:solr)
        expect(solr_resp.size).to eq(2)
        expect(solr_resp[0]['id']).to eq(@book.pid)
        expect(solr_resp[1]['id']).to eq(@book2.pid)

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
      it "shouldn't do anything if you set a nil id" do
        @book.library_id = nil
      end
      it "should be settable from the book side" do
        @book.library_id = @library.pid
        expect(@book.library).to eq(@library)
        expect(@book.library.pid).to eq(@library.pid)
        @book.attributes= {:library_id => ""}
        expect(@book.library_id).to be_nil
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
        expect(@book.topics.map(&:pid)).to eq([@topic1.pid])
        expect(Topic.find(@topic1.pid).books).to eq([]) #Can't have saved it because @book isn't saved yet.
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

        expect(@book.library.pid).to eq(@library.pid)
        @library.books.reload
        expect(@library.books).to eq([@book])

        @library2 = Library.find(@library.pid)
        expect(@library2.books).to eq([@book])
      end

      it "should have a count once it has been saved" do
        @library.books << @book << Book.create
        @library.save

        # @book.library.pid.should == @library.pid
        # @library.books.reload
        # @library.books.should == [@book]

        @library2 = Library.find(@library.pid)
        expect(@library2.books.size).to eq(2)
      end

      it "should respect the :class_name parameter" do
        @book.author = @person
        @book.save
        expect(Book.find(@book.id).author_id).to eq(@person.pid)
        expect(Book.find(@book.id).author.send(:find_target)).to be_kind_of Person
      end

      describe "when changing the belonger" do
        before do
          @book.library = @library
          @book.save
          @library2 = Library.create
        end
        it "should replace an existing instance" do
          expect(@book.library_id).to eq(@library.id)
          @book.library = @library2
          @book.save
          expect(Book.find(@book.id).library_id).to eq(@library2.id)
        end
        after do
          @library2.delete
        end
      end

      after do
        @library.delete
        @book.delete
      end
    end
    describe "of has_many_and_belongs_to" do
      before do
        @book = Book.create
      end
      after do
        @book.delete
      end
      describe "when invese is specified" do
        before do
          @topic1 = Topic.create
          @topic2 = Topic.create
        end
        it "should set relationships bidirectionally" do
          @book.topics << @topic1
          expect(@book.topics).to eq([@topic1])
          expect(@book.relationships(:has_topic)).to eq([@topic1.internal_uri])
          expect(@topic1.relationships(:has_topic)).to eq([])
          expect(@topic1.relationships(:is_topic_of)).to eq([@book.internal_uri])
          expect(Topic.find(@topic1.pid).books).to eq([@book]) #Can't have saved it because @book isn't saved yet.
        end
        it "should save new child objects" do
          @book.topics << Topic.new
          expect(@book.topics.first.pid).not_to be_nil
        end
        it "should clear out the old associtions" do
          @book.topics = [@topic1]
          @book.topics = [@topic2]
          expect(@book.topic_ids).to eq([@topic2.pid])
        end
        after do
          @topic1.delete
          @topic2.delete
        end
      end
      describe "when invese is not specified" do
        before do
          @c = Collection.create
          @book.collections << @c
          @book.save
        end
        after do
          @c.delete
        end
        it "should have a collection" do
          expect(@book.relationships(:is_member_of_collection)).to eq([@c.internal_uri])
          expect(@book.collections).to eq([@c])
        end
        it "habtm should not set foreign relationships if :inverse_of is not specified" do
           expect(@c.relationships(:is_member_of_collection)).to eq([])
        end
        it "should load the collections" do
          reloaded = Book.find(@book.pid)
          expect(reloaded.collections).to eq([@c])
        end
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
      expect(@book.library.pid).to eq(@library.pid)
      @book.save


      expect(Book.find(@book.pid).library.pid).to eq(@library.pid)

    end
    it "should clear the association" do
      @book.library = @library
      @book.library = nil
      @book.save

      expect(Book.find(@book.pid).library).to be_nil

    end

    it "should replace the association" do
      @library2 = Library.new
      @library2.save
      @book.library = @library
      @book.save
      @book.library = @library2
      @book.save
      expect(Book.find(@book.pid).library.pid).to eq(@library2.pid)

    end

    it "should be able to be set by id" do
      @book.library_id = @library.pid
      expect(@book.library_id).to eq(@library.pid)
      expect(@book.library.pid).to eq(@library.pid)
      @book.save
      expect(Book.find(@book.pid).library_id).to eq(@library.pid)
    end

    after do
      @library.delete
      @book.delete
      @library2.delete if @library2
    end
  end

  describe "single direction habtm" do
    before :all do
      class LibraryBook < ActiveFedora::Base
        has_and_belongs_to_many :pages, :property=>:is_part_of
      end
      class Page < ActiveFedora::Base
        has_many :library_books, :property=>:is_part_of
      end

    end
    after :all do
      Object.send(:remove_const, :LibraryBook)
      Object.send(:remove_const, :Page)
    end

    describe "with a parent that has two children" do
      before do
        @book = LibraryBook.create
        @p1 = Page.create()
        @p2 = Page.create()
        @book.pages = [@p1, @p2]
        @book.save
      end

      it "should load the association stored in the parent" do
        @reloaded_book = LibraryBook.find(@book.pid)
        expect(@reloaded_book.pages).to eq([@p1, @p2])
      end

      it "should allow a parent to be deleted from the has_many association" do
        @reloaded_book = LibraryBook.find(@book.pid)
        @p1.library_books.delete(@reloaded_book)
        @reloaded_book.save

        @reloaded_book = LibraryBook.find(@book.pid)
        expect(@reloaded_book.pages).to eq([@p2])
      end

      it "should allow a child to be deleted from the has_and_belongs_to_many association" do
        skip "This isn't working and we ought to fix it"
        @reloaded_book = LibraryBook.find(@book.pid)
        @reloaded_book.pages.delete(@p1)
        @reloaded_book.save
        @p1.save

        @reloaded_book = LibraryBook.find(@book.pid)
        expect(@reloaded_book.pages).to eq([@p2])
      end
    end
  end



  describe "when a object is deleted" do
    before (:all) do
      class MasterFile < ActiveFedora::Base
        belongs_to :media_object, :property=>:is_part_of
      end
      class MediaObject < ActiveFedora::Base
        has_many :parts, :class_name=>'MasterFile', :property=>:is_part_of
      end
    end

    before :each do
      @master = MasterFile.create
      @media = MediaObject.create
      @master.media_object = @media
      @master.save
      @master.reload

    end

    it "should also remove the relationships that point at that object" do
      @media.delete
      @master = MasterFile.find(@master.pid)
      expect(@master.relationships(:is_part_of)).to eq([])
    end
  end


end
