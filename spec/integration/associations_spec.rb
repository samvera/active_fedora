require 'spec_helper'

describe ActiveFedora::Base do
  describe "complex example" do
    before do
      class Library < ActiveFedora::Base 
        has_many :books, :property=>:has_constituent
      end

      class Book < ActiveFedora::Base 
        belongs_to :library, :property=>:has_constituent
        belongs_to :author, :property=>:has_member, :class_name=>'Person'
        belongs_to :publisher, :property=>:has_member
        has_and_belongs_to_many :topics, :property=>:has_topic, :inverse_of=>:is_topic_of
        has_and_belongs_to_many :collections, :property=>:is_member_of_collection
      end

      class Person < ActiveFedora::Base
      end

      class Publisher < ActiveFedora::Base
      end

      class Collection < ActiveFedora::Base
      end

      class Topic < ActiveFedora::Base 
        has_and_belongs_to_many :books, :property=>:is_topic_of
      end
    end

    after do
      Object.send(:remove_const, :Library)
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Person)
      Object.send(:remove_const, :Collection)
      Object.send(:remove_const, :Topic)
    end

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
          new_book.should be_new_record
          new_book.should be_kind_of Book
          new_book.library.should be_nil
          @library.books.should == [new_book]
          #TODO save the associated children too, requires something like ActiveRecord::AutosaveAssociation (ver 3.0.12) 
          #@library.save
          #new_book.library.should == @library
        end

        it "should not create children if the parent isn't saved" do
          lambda {@library.books.create({})}.should raise_error ActiveFedora::RecordNotSaved, "You cannot call create unless the parent is saved"
        end

        it "should create children" do
          @library.save!
          new_book = @library.books.create({})
          new_book.should_not be_new_record
          new_book.should be_kind_of Book
          new_book.library.should == @library
        end

        it "should build parent" do
          new_library = @book.build_library({})
          new_library.should be_new_record
          new_library.should be_kind_of Library
          @book.library.should == new_library
        end

        it "should create parent" do
          new_library = @book.create_library({})
          new_library.should_not be_new_record
          new_library.should be_kind_of Library
          @book.library.should == new_library
        end

        it "should let you shift onto the association" do
          @library.new_record?.should be_true
          @library.books.size == 0
          @library.books.should == []
          @library.book_ids.should ==[]
          @library.books << @book
          @library.books.should == [@book]
          @library.book_ids.should ==[@book.pid]

        end

        it "should let you set an array of objects" do
          @library.books = [@book, @book2]
          @library.books.should == [@book, @book2]
          @library.save

          @library.books = [@book]
          @library.books.should == [@book]
        
        end
        it "should let you set an array of object ids" do
          @library.book_ids = [@book.pid, @book2.pid]
          @library.books.should == [@book, @book2]
        end

        it "setter should wipe out previously saved relations" do
          @library.book_ids = [@book.pid, @book2.pid]
          @library.book_ids = [@book2.pid]
          @library.books.should == [@book2]
          
        end

        it "saving the parent should save the relationships on the children" do
          @library.save
          @library.books = [@book, @book2]
          @library.save
          @library = Library.find(@library.pid)
          @library.books.should == [@book, @book2]
        end


        it "should let you lookup an array of objects with solr" do
          @library.save
          @book.library = @library
          @book2.library = @library
          @book.save
          @book2.save

          @library = Library.find(@library.pid)
          @library.books.should == [@book, @book2]
        
          solr_resp =  @library.books(:response_format=>:solr)
          solr_resp.size.should == 2
          solr_resp[0]['id'].should == @book.pid 
          solr_resp[1]['id'].should == @book2.pid 
        
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
          @book.library.should == @library
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
          @topic1 = Topic.create
          @topic2 = Topic.create
          @book = Book.create
        end
        it "habtm should set and remove relationships bidirectionally" do
          @book.topics << @topic1
          @book.topics.should == [@topic1]
          @topic1.books.should == [@book]
          @topic1.reload.books.should == [@book]

          @book.topics.delete(@topic1)
          #@topic1.books.delete(@book)
          @book.topics.should == []
          @topic1.books.should == []
        end
        it "Should allow for more than 10 items" do

          (0..11).each do
            @book.topics << Topic.create
          end
          @book.save
          @book.topics.count.should == 12
          book2 = Book.find(@book.pid)
          book2.topics.count.should == 12
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
          @publisher = Publisher.new
          @publisher.save
        end
        it "should have many books once it has been saved" do
          @library.books << @book

          @book.library.pid.should == @library.pid
          @library.books.reload
          @library.books.should == [@book]

          @library2 = Library.find(@library.pid)
          @library2.books.should == [@book]
        end

        it "should have a count once it has been saved" do
          @library.books << @book << Book.create 
          @library.save

          # @book.library.pid.should == @library.pid
          # @library.books.reload
          # @library.books.should == [@book]

          @library2 = Library.find(@library.pid)
          @library2.books.size.should == 2
        end

        it "should respect the :class_name parameter" do
          @book.author = @person
          @book.save
          Book.find(@book.id).author_id.should == @person.pid
          Book.find(@book.id).author.send(:find_target).should be_kind_of Person
        end

        it "should respect multiple associations that share the same :property and respect associated class" do
          @book.author = @person
          @book.publisher = @publisher
          @book.save
          
          Book.find(@book.id).publisher_id.should == @publisher.pid
          Book.find(@book.id).publisher.send(:find_target).should be_kind_of Publisher

          Book.find(@book.id).author_id.should == @person.pid
          Book.find(@book.id).author.send(:find_target).should be_kind_of Person
        end

        describe "when changing the belonger" do
          before do
            @book.library = @library
            @book.save
            @library2 = Library.create
          end
          it "should replace an existing instance" do
            @book.library_id.should == @library.id
            @book.library = @library2
            @book.save
            Book.find(@book.id).library_id.should == @library2.id
          end
          after do
            @library2.delete
          end
        end

        after do
          @library.delete
          @book.delete
          @person.delete
          @publisher.delete
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
            @book.topics.should == [@topic1]
            @book.relationships(:has_topic).should == [@topic1.internal_uri]
            @topic1.relationships(:has_topic).should == []
            @topic1.relationships(:is_topic_of).should == [@book.internal_uri]
            Topic.find(@topic1.pid).books.should == [@book] #Can't have saved it because @book isn't saved yet.
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
            @book.relationships(:is_member_of_collection).should == [@c.internal_uri]
            @book.collections.should == [@c]
          end
          it "habtm should not set foreign relationships if :inverse_of is not specified" do
             @c.relationships(:is_member_of_collection).should == []
          end
          it "should load the collections" do
            reloaded = Book.find(@book.pid)
            reloaded.collections.should == [@c]
          end
        end
      end
    end

    describe "setting belongs_to" do
      before do
        @library = Library.new()
        @library.save()
        @book = Book.new
        @author = Person.new
        @author.save
        @publisher = Publisher.new
        @publisher.save
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

      it "should only replace the matching class association" do
        @publisher2 = Publisher.new
        @publisher2.save

        @book.publisher = @publisher
        @book.author = @author      
        @book.save 

        @book.publisher = @publisher2
        @book.save

        Book.find(@book.pid).publisher.pid.should == @publisher2.pid
        Book.find(@book.pid).author.pid.should == @author.pid
      end

      it "should only clear the matching class association" do
        @book.publisher = @publisher
        @book.author = @author
        @book.save

        @book.author = nil
        @book.save

        Book.find(@book.pid).author.should be_nil
        Book.find(@book.pid).publisher.pid.should == @publisher.pid
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
        @author.delete
        @publisher.delete
        @library2.delete if @library2
        @publisher2.delete if @publisher2
      end
    end
  end

  describe "single direction habtm" do
    before :all do
      class Course < ActiveFedora::Base
        has_and_belongs_to_many :textbooks, :property=>:is_part_of
      end
      class Textbook < ActiveFedora::Base
        has_many :courses, :property=>:is_part_of
      end
        
    end
    after :all do
      Object.send(:remove_const, :Course)
      Object.send(:remove_const, :Textbook)
    end

    describe "with a parent that has two children" do
      before do
        @course = Course.create
        @t1 = Textbook.create()
        @t2 = Textbook.create()
        @course.textbooks = [@t1, @t2]
        @course.save
      end

      it "should load the association stored in the parent" do
        @reloaded_course = Course.find(@course.pid)
        @reloaded_course.textbooks.should == [@t1, @t2]
      end

      it "should allow a parent to be deleted from the has_many association" do
        @reloaded_course = Course.find(@course.pid)
        @t1.courses.delete(@reloaded_course)
        @reloaded_course.save

        @reloaded_course = Course.find(@course.pid)
        @reloaded_course.textbooks.should == [@t2]
      end

      it "should allow replacing the children" do
        @t3 = Textbook.create()
        @t4 = Textbook.create()
        @course.textbooks = [@t3, @t4]
        @course.save

        @course.reload.textbooks.should == [@t3, @t4]
      end

      it "should allow a child to be deleted from the has_and_belongs_to_many association" do
        @reloaded_course = Course.find(@course.pid)
        @reloaded_course.textbooks.delete(@t1)
        @reloaded_course.save
        @t1.save

        @reloaded_course = Course.find(@course.pid)
        @reloaded_course.textbooks.should == [@t2]
      end
    end
  end

  describe "association hooks" do
    describe "for habtm" do
      before :all do
        class LibraryBook < ActiveFedora::Base
          has_and_belongs_to_many :pages, :property=>:is_part_of, after_remove: :after_hook, before_remove: :before_hook

          def before_hook(m)
            say_hi(m)
            m.reload.library_books.count.should == 1
          end

          def after_hook(m)
            say_hi(m)
            m.reload.library_books.count.should == 0
          end


        end
        class Page < ActiveFedora::Base
          has_many :library_books, :property=>:is_part_of
        end
          
      end
      after :all do
        Object.send(:remove_const, :LibraryBook)
        Object.send(:remove_const, :Page)
      end

      describe "removing association" do
        subject {LibraryBook.create}
        before do
          @p1 = Page.create
          @p2 = Page.create
          subject.pages << @p1 << @p2
          subject.save!
        end
        it "should save between the before and after hooks" do
          subject.should_receive(:say_hi).with(@p2).twice
          subject.pages.delete(@p2)
        end
      end
    end
    describe "for has_many" do
      before :all do
        class LibraryBook < ActiveFedora::Base
          has_many :pages, :property=>:is_part_of, after_remove: :say_hi

        end
        class Page < ActiveFedora::Base
          belongs_to :library_book, :property=>:is_part_of
        end
          
      end
      after :all do
        Object.send(:remove_const, :LibraryBook)
        Object.send(:remove_const, :Page)
      end

      describe "removing association" do
        subject {LibraryBook.new}
        before do
          @p1 = subject.pages.build
          @p2 = subject.pages.build
        end
        it "should run the hooks" do
          subject.should_receive(:say_hi).with(@p2)
          subject.pages.delete(@p2)
        end
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

    after :all do
      Object.send(:remove_const, :MasterFile)
      Object.send(:remove_const, :MediaObject)
    end

    it "should also remove the relationships that point at that object" do
      @media.delete
      @master = MasterFile.find(@master.pid)
      @master.relationships(:is_part_of).should == []
    end
  end

  describe "has_many" do
    describe "when an object doesn't have a property, and the class_name is predictable" do
      before (:all) do
        class Bauble < ActiveFedora::Base
          belongs_to :media_object, property: :is_part_of
        end
        class MediaObject < ActiveFedora::Base
          has_many :baubles
        end
      end
      after :all do
        Object.send(:remove_const, :Bauble)
        Object.send(:remove_const, :MediaObject)
      end

      it "it should find the predicate" do
        MediaObject.new.baubles.send(:find_predicate).should == :is_part_of
      end
    end

    describe "when an object doesn't have a property, but has a class_name" do
      before (:all) do
        class MasterFile < ActiveFedora::Base
          belongs_to :media_object, property: :is_part_of
        end
        class MediaObject < ActiveFedora::Base
          has_many :parts, :class_name=>'MasterFile'
        end
      end
      after :all do
        Object.send(:remove_const, :MasterFile)
        Object.send(:remove_const, :MediaObject)
      end

      it "it should find the predicate" do
        MediaObject.new.parts.send(:find_predicate).should == :is_part_of
      end
    end

    describe "an object has an explicity property" do
      before (:all) do
        class Bauble < ActiveFedora::Base
          belongs_to :media_object, property: :is_part_of
        end
        class MediaObject < ActiveFedora::Base
          has_many :baubles, property: :has_baubles
        end
      end
      after :all do
        Object.send(:remove_const, :Bauble)
        Object.send(:remove_const, :MediaObject)
      end

      it "it should find the predicate" do
        MediaObject.new.baubles.send(:find_predicate).should == :has_baubles
      end
    end
    describe "an object doesn't have a property" do
      before (:all) do
        class Bauble < ActiveFedora::Base
          belongs_to :media_object, property: :is_part_of
        end
        class MediaObject < ActiveFedora::Base
          has_many :shoes
        end
      end
      after :all do
        Object.send(:remove_const, :Bauble)
        Object.send(:remove_const, :MediaObject)
      end

      it "it should find the predicate" do
        expect { MediaObject.new.shoes.send(:find_predicate) }.to raise_error RuntimeError, "No :property attribute was set or could be inferred for has_many :shoes on MediaObject"
      end
    end
  end

  describe "casting when the class name is ActiveFedora::Base" do
    describe "for habtm" do
      before :all do
        class Novel < ActiveFedora::Base
          has_and_belongs_to_many :contents, property: :is_part_of, class_name: 'ActiveFedora::Base'
        end
        class TextBook < ActiveFedora::Base
          has_and_belongs_to_many :contents, property: :is_part_of, class_name: 'ActiveFedora::Base'
        end
        class Text < ActiveFedora::Base
          has_many :books, property: :is_part_of, class_name: 'ActiveFedora::Base'
        end
        class Image < ActiveFedora::Base
          has_many :books, property: :is_part_of, class_name: 'ActiveFedora::Base'
        end
          
      end
      after :all do
        Object.send(:remove_const, :Novel)
        Object.send(:remove_const, :TextBook)
        Object.send(:remove_const, :Text)
        Object.send(:remove_const, :Image)
      end

      describe "saving between the before and after hooks" do
        let(:text1) { Text.create}
        let(:image1) { Image.create}
        let(:text2) { Text.create}
        let(:image2) { Image.create}
        let(:book1) { TextBook.create}
        let(:book2) { Novel.create}

        it "should work when added via the has_and_belongs_to_many" do
          book1.contents = [text1, image1]
          book1.save!
          book2.contents = [text2, image2]
          book2.save!

          book1.reload.contents.should include(text1, image1)
          text1.reload.books.should == [book1]
          image1.reload.books.should == [book1]

          book2.reload.contents.should include(text2, image2)
          text2.reload.books.should == [book2]
          image2.reload.books.should == [book2]
        end

        it "should work when added via the has_many" do
          text2.books << book2
          book2.save
          book2.reload.contents.should == [text2]
          text2.reload.books.should == [book2]
        end
      end
    end
  end
end