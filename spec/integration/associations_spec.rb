require 'spec_helper'

describe ActiveFedora::Base do
  describe "use a URI as the property" do
    before do
      class Book < ActiveFedora::Base
        belongs_to :author, property: RDF::DC.creator, class_name: 'Person'
      end

      class Person < ActiveFedora::Base
      end
    end

    after do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Person)
    end

    let(:person) { Person.create }
    let(:book) { Book.new(author: person) }

    it "should go" do
      book.save
    end

  end

  describe "complex example" do
    before do
      class Library < ActiveFedora::Base
        has_many :books, property: :has_constituent
      end

      class Book < ActiveFedora::Base
        belongs_to :library, property: :has_constituent
        belongs_to :author, property: :has_member, class_name: 'Person'
        belongs_to :publisher, property: :has_member
      end

      class Person < ActiveFedora::Base
      end

      class Publisher < ActiveFedora::Base
      end
    end

    after do
      Object.send(:remove_const, :Library)
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Person)
      Object.send(:remove_const, :Publisher)
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
          expect(new_book).to be_new_record
          expect(new_book).to be_kind_of Book
          expect(new_book.library).to be_kind_of Library
          expect(@library.books).to eq [new_book]
        end

        it "should make a new child" do
          new_book = @library.books.new
          expect(new_book).to be_new_record
          expect(new_book).to be_kind_of Book
          expect(new_book.library).to be_kind_of Library
          expect(@library.books).to eq [new_book]
        end

        it "should not create children if the parent isn't saved" do
          expect {@library.books.create({})}.to raise_error ActiveFedora::RecordNotSaved, "You cannot call create unless the parent is saved"
        end

        it "should create children" do
          @library.save!
          new_book = @library.books.create({})
          expect(new_book).to_not be_new_record
          expect(new_book).to be_kind_of Book
          expect(new_book.library).to eq @library
        end

        it "should build parent" do
          new_library = @book.build_library({})
          expect(new_library).to be_new_record
          expect(new_library).to be_kind_of Library
          expect(@book.library).to eq new_library
        end

        it "should create parent" do
          new_library = @book.create_library({})
          expect(new_library).to_not be_new_record
          expect(new_library).to be_kind_of Library
          expect(@book.library).to eq new_library
        end

        it "should let you shift onto the association" do
          expect(@library).to be_new_record
          expect(@library.books.size).to eq 0
          expect(@library.books).to eq []
          expect(@library.book_ids).to eq []
          @library.books << @book
          expect(@library.books).to eq [@book]
          expect(@library.book_ids).to eq [@book.pid]

        end

        it "should let you set an array of objects" do
          @library.books = [@book, @book2]
          expect(@library.books).to eq [@book, @book2]
          @library.save

          @library.books = [@book]
          expect(@library.books).to eq [@book]

        end
        it "should let you set an array of object ids" do
          @library.book_ids = [@book.pid, @book2.pid]
          expect(@library.books).to eq [@book, @book2]
        end

        it "setter should wipe out previously saved relations" do
          @library.book_ids = [@book.pid, @book2.pid]
          @library.book_ids = [@book2.pid]
          expect(@library.books).to eq [@book2]

        end

        it "saving the parent should save the relationships on the children" do
          @library.save
          @library.books = [@book, @book2]
          @library.save
          @library = Library.find(@library.pid)
          expect(@library.books).to eq [@book, @book2]
        end


        it "should let you lookup an array of objects with solr" do
          @library.save
          @book.library = @library
          @book2.library = @library
          @book.save
          @book2.save

          @library = Library.find(@library.pid)
          expect(@library.books).to eq [@book, @book2]

          solr_resp =  @library.books(:response_format=>:solr)
          expect(solr_resp.size).to eq 2
          expect(solr_resp[0]['id']).to eq @book.pid
          expect(solr_resp[1]['id']).to eq @book2.pid

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
          expect(@book.library).to eq @library
          expect(@book.library.pid).to eq @library.pid
          @book.attributes= {:library_id => nil }
          expect(@book.library_id).to be_nil
        end
        after do
          @library.delete
          @book.delete
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

          expect(@book.library.pid).to eq @library.pid
          @library.books.reload
          expect(@library.books).to eq [@book]

          @library2 = Library.find(@library.pid)
          expect(@library2.books).to eq [@book]
        end

        it "should have a count once it has been saved" do
          @book_2 = Book.create
          @library.books << @book << @book_2
          @library.save

          @library2 = Library.find(@library.pid)
          expect(@library2.books.size).to eq 2
          @book_2.reload
          @book_2.delete
        end

        it "should respect the :class_name parameter" do
          @book.author = @person
          @book.save
          new_book = Book.find(@book.id)
          expect(new_book.author_id).to eq @person.pid
          expect(new_book.author).to be_kind_of Person
        end

        it "should respect multiple associations that share the same :property and respect associated class" do
          @book.author = @person
          @book.publisher = @publisher
          @book.save

          new_book = Book.find(@book.id)

          expect(new_book.publisher_id).to eq @publisher.pid
          expect(new_book.publisher).to be_kind_of Publisher

          expect(new_book.author_id).to eq @person.pid
          expect(new_book.author).to be_kind_of Person
        end

        describe "when changing the belonger" do
          before do
            @book.library = @library
            @book.save
            @library2 = Library.create
          end
          it "should replace an existing instance" do
            expect(@book.library_id).to eq @library.id
            @book.library = @library2
            @book.save
            expect(Book.find(@book.id).library_id).to eq @library2.id
          end
          after do
            @library2.delete
          end
        end


        after do
          [@library, @book, @person, @publisher].each do |var|
            var.reload
            var.delete
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
        expect(@book.library.pid).to eq @library.pid
        @book.save


        expect(Book.find(@book.pid).library.pid).to eq@library.pid
        
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
        expect(Book.find(@book.pid).library.pid).to eq @library2.pid

      end

      it "should only replace the matching class association" do
        @publisher2 = Publisher.new
        @publisher2.save

        @book.publisher = @publisher
        @book.author = @author      
        @book.save!

        @book.publisher = @publisher2
        @book.save!

        new_book = Book.find(@book.pid)
        expect(new_book.publisher.pid).to eq @publisher2.pid
        expect(new_book.author.pid).to eq @author.pid
      end

      it "should only clear the matching class association" do
        @book.publisher = @publisher
        @book.author = @author
        @book.save

        @book.author = nil
        @book.save

        expect(Book.find(@book.pid).author).to be_nil
        expect(Book.find(@book.pid).publisher.pid).to eq @publisher.pid
      end

      it "should be able to be set by id" do
        @book.library_id = @library.pid
        expect(@book.library_id).to eq @library.pid
        expect(@book.library.pid).to eq @library.pid
        @book.save
        expect(Book.find(@book.pid).library_id).to eq @library.pid
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
        expect(@reloaded_course.textbooks).to eq [@t1, @t2]
      end

      it "should allow a parent to be deleted from the has_many association" do
        @reloaded_course = Course.find(@course.pid)
        @t1.courses.delete(@reloaded_course)
        @reloaded_course.save

        @reloaded_course = Course.find(@course.pid)
        expect(@reloaded_course.textbooks).to eq [@t2]
      end

      it "should allow replacing the children" do
        @t3 = Textbook.create()
        @t4 = Textbook.create()
        @course.textbooks = [@t3, @t4]
        @course.save

        expect(@course.reload.textbooks).to eq [@t3, @t4]
      end

      it "should allow a child to be deleted from the has_and_belongs_to_many association" do
        @reloaded_course = Course.find(@course.pid)
        @reloaded_course.textbooks.delete(@t1)
        @reloaded_course.save
        @t1.save

        @reloaded_course = Course.find(@course.pid)
        expect(@reloaded_course.textbooks).to eq [@t2]
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
            before_count(m.reload.library_books.count)
          end

          def after_hook(m)
            say_hi(m)
            after_count(m.reload.library_books.count)
          end

          def say_hi(var)
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
          expect(subject).to receive(:before_count).with(1)
          expect(subject).to receive(:after_count).with(0)
          expect(subject).to receive(:say_hi).with(@p2).twice
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
          expect(subject).to receive(:say_hi).with(@p2)
          subject.pages.delete(@p2)
        end
      end
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
        expect(MediaObject.new.association(:baubles).send(:find_predicate)).to eq :is_part_of
      end
    end

    describe "when an object doesn't have a property, but has a class_name" do
      before :all do
        class MasterFile < ActiveFedora::Base
          belongs_to :media_object, property: :is_part_of
        end
        class MediaObject < ActiveFedora::Base
          has_many :parts, class_name: 'MasterFile'
        end
      end

      after :all do
        Object.send(:remove_const, :MasterFile)
        Object.send(:remove_const, :MediaObject)
      end

      it "it should find the predicate" do
        expect(MediaObject.new.association(:parts).send(:find_predicate)).to eq :is_part_of
      end
    end

    describe "an object has an explicity property" do
      before :all do
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
        expect(MediaObject.new.association(:baubles).send(:find_predicate)).to eq :has_baubles
      end
    end

    describe "an object doesn't have a property" do
      before :all do
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

          expect(book1.reload.contents).to include(text1, image1)
          expect(text1.reload.books).to eq [book1]
          expect(image1.reload.books).to eq [book1]

          expect(book2.reload.contents).to include(text2, image2)
          expect(text2.reload.books).to eq [book2]
          expect(image2.reload.books).to eq [book2]
        end
      end
    end
  end
end
