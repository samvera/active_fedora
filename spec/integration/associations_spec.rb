# frozen_string_literal: true
require 'spec_helper'

describe ActiveFedora::Base do
  describe "use a URI as the property" do
    before do
      class Book < ActiveFedora::Base
        belongs_to :author, predicate: ::RDF::Vocab::DC.creator, class_name: 'Person'
      end

      class Person < ActiveFedora::Base
      end
    end

    after do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Person)
    end

    subject(:book) { Book.new(author: person) }
    let(:person) { Person.create }

    it "goes" do
      book.save
    end
  end

  describe "explicit foreign key" do
    before do
      class FooThing < ActiveFedora::Base
        has_many :bars, class_name: 'BarThing', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, as: :foothing
      end

      class BarThing < ActiveFedora::Base
        belongs_to :foothing, class_name: 'FooThing', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end
    end

    after do
      Object.send(:remove_const, :FooThing)
      Object.send(:remove_const, :BarThing)
    end

    let(:foo) { FooThing.create }
    let(:bar) { BarThing.create }

    it "associates from bar to foo" do
      bar.foothing = foo
      bar.save
      expect(foo.bars).to eq [bar]
    end

    it "associates from foo to bar" do
      foo.bars << bar
      expect(bar.foothing).to eq foo
    end
  end

  describe "type validator" do
    before do
      class EnsureBanana
        def self.validate!(_reflection, object)
          raise ActiveFedora::AssociationTypeMismatch, "#{object} must be a banana" unless object.try(:banana?)
        end
      end

      class FooThing < ActiveFedora::Base
        attr_accessor :banana
        has_many :bars, class_name: 'BarThing', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, as: :foothing, type_validator: EnsureBanana
        def banana?
          !banana.nil?
        end
      end

      class BarThing < ActiveFedora::Base
        attr_accessor :banana
        belongs_to :foothing, class_name: 'FooThing', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, type_validator: EnsureBanana
        def banana?
          !banana.nil?
        end
      end
    end

    after do
      Object.send(:remove_const, :FooThing)
      Object.send(:remove_const, :BarThing)
    end

    let(:foo) { FooThing.create }
    let(:bar) { BarThing.create }

    it "validates on singular associations" do
      expect { bar.foothing = foo }.to raise_error ActiveFedora::AssociationTypeMismatch, "#{foo} must be a banana"
      foo.banana = true
      expect { bar.foothing = foo }.not_to raise_error
    end
    it "validates on collection associations" do
      expect { foo.bars << bar }.to raise_error ActiveFedora::AssociationTypeMismatch, "#{bar} must be a banana"
      bar.banana = true
      expect { foo.bars << bar }.not_to raise_error
    end
    it "does NOT validate on destroy" do
      bar.banana = true
      foo.bars << bar
      bar.banana = false
      expect { foo.bars.destroy(bar) }.not_to raise_error
    end
  end

  describe "complex example" do
    before do
      class Library < ActiveFedora::Base
        has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
      end

      class Book < ActiveFedora::Base
        belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
        belongs_to :author, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember, class_name: 'Person'
        belongs_to :publisher, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
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
          @library = Library.new
          @book = Book.new
          @book.save
          @book2 = Book.new
          @book2.save
        end

        it "builds child" do
          new_book = @library.books.build({})
          expect(new_book).to be_new_record
          expect(new_book).to be_kind_of Book
          expect(new_book.library).to be_kind_of Library
          expect(@library.books).to eq [new_book]
        end

        it "makes a new child" do
          new_book = @library.books.new
          expect(new_book).to be_new_record
          expect(new_book).to be_kind_of Book
          expect(new_book.library).to be_kind_of Library
          expect(@library.books).to eq [new_book]
        end

        it "does not create children if the parent isn't saved" do
          expect { @library.books.create({}) }.to raise_error ActiveFedora::RecordNotSaved, "You cannot call create unless the parent is saved"
        end

        it "creates children" do
          @library.save!
          new_book = @library.books.create({})
          expect(new_book).to_not be_new_record
          expect(new_book).to be_kind_of Book
          expect(new_book.library).to eq @library
        end

        it "builds parent" do
          new_library = @book.build_library({})
          expect(new_library).to be_new_record
          expect(new_library).to be_kind_of Library
          expect(@book.library).to eq new_library
        end

        it "creates parent" do
          new_library = @book.create_library({})
          expect(new_library).to_not be_new_record
          expect(new_library).to be_kind_of Library
          expect(@book.library).to eq new_library
        end

        it "lets you shift onto the association" do
          expect(@library).to be_new_record
          expect(@library.books.size).to eq 0
          expect(@library.books).to eq []
          expect(@library.book_ids).to eq []
          @library.books << @book
          expect(@library.books).to eq [@book]
          expect(@library.book_ids).to eq [@book.id]
        end

        it "lets you set an array of objects" do
          @library.books = [@book, @book2]
          expect(@library.books).to contain_exactly @book, @book2
          @library.save

          @library.books = [@book]
          expect(@library.books).to eq [@book]
        end
        it "lets you set an array of object ids" do
          @library.book_ids = [@book.id, @book2.id]
          expect(@library.books).to contain_exactly @book, @book2
        end

        it "setter should wipe out previously saved relations" do
          @library.book_ids = [@book.id, @book2.id]
          @library.book_ids = [@book2.id]
          expect(@library.books).to eq [@book2]
        end

        it "saving the parent should save the relationships on the children" do
          @library.save
          @library.books = [@book, @book2]
          @library.save
          @library = Library.find(@library.id)
          expect(@library.books).to contain_exactly @book, @book2
        end

        it "lets you lookup an array of objects with solr" do
          @library.save
          @book.library = @library
          @book2.library = @library
          @book.save
          @book2.save

          @library = Library.find(@library.id)
          expect(@library.books).to contain_exactly @book, @book2

          solr_resp = @library.books(response_format: :solr)
          expect(solr_resp.size).to eq 2
          expect(solr_resp[0].id).to eq @book.id
          expect(solr_resp[1].id).to eq @book2.id
        end
      end

      describe "of belongs to" do
        before do
          @library = Library.new
          @library.save
          @book = Book.new
          @book.save
        end
        it "does not do anything if you set a nil id" do
          @book.library_id = nil
        end
        it "is settable from the book side" do
          @book.library_id = @library.id
          expect(@book.library).to eq @library
          expect(@book.library.id).to eq @library.id
          @book.attributes = { library_id: nil }
          expect(@book.library_id).to be_nil
        end
      end
    end

    describe "a saved instance" do
      describe "of belongs_to" do
        before do
          @library = Library.new
          @library.save
          @book = Book.new
          @book.save
          @person = Person.new
          @person.save
          @publisher = Publisher.new
          @publisher.save
        end
        it "has many books once it has been saved" do
          @library.books << @book

          expect(@book.library.id).to eq @library.id
          @library.books.reload
          expect(@library.books).to eq [@book]

          @library2 = Library.find(@library.id)
          expect(@library2.books).to eq [@book]
        end

        it "has a count once it has been saved" do
          @book_two = Book.create
          @library.books << @book << @book_two
          @library.save

          @library2 = Library.find(@library.id)
          expect(@library2.books.size).to eq 2
          @book_two.reload
          @book_two.delete
        end

        it "respects the :class_name parameter" do
          @book.author = @person
          @book.save
          new_book = Book.find(@book.id)
          expect(new_book.author_id).to eq @person.id
          expect(new_book.author).to be_kind_of Person
        end

        it "respects multiple associations that share the same :property and respect associated class" do
          @book.author = @person
          @book.publisher = @publisher
          @book.save

          new_book = Book.find(@book.id)

          expect(new_book.publisher_id).to eq @publisher.id
          expect(new_book.publisher).to be_kind_of Publisher

          expect(new_book.author_id).to eq @person.id
          expect(new_book.author).to be_kind_of Person
        end

        describe "when changing the belonger" do
          before do
            @book.library = @library
            @book.save
            @library2 = Library.create
          end
          it "replaces an existing instance" do
            expect(@book.library_id).to eq @library.id
            @book.library = @library2
            @book.save
            expect(Book.find(@book.id).library_id).to eq @library2.id
          end
        end
      end
    end

    describe "when fetching an existing object" do
      before do
        class Dog < ActiveFedora::Base; end
        class BigDog < Dog; end
        class Cat < ActiveFedora::Base; end
        @dog = Dog.create
        @big_dog = BigDog.create
      end
      it "detects class mismatch" do
        expect {
          Cat.find @dog.id
        }.to raise_error(ActiveFedora::ActiveFedoraError)
      end

      it "does not accept parent class into a subclass" do
        expect {
          BigDog.find @dog.id
        }.to raise_error(ActiveFedora::ActiveFedoraError)
      end

      it "accepts a subclass into a parent class" do
        # We could prevent this altogether since loading a subclass into
        # a parent class (a BigDog into a Dog) would result in lost of
        # data if the object is saved back and the subclass has more
        # properties than the parent class. However, it does seem reasonable
        # that people might want to use them interchangeably (after all
        # a BigDog is a Dog) and therefore we allow for it.
        expect {
          Dog.find @big_dog.id
        }.not_to raise_error
      end
    end

    describe "setting belongs_to" do
      before do
        @library = Library.new
        @library.save
        @book = Book.new
        @author = Person.new
        @author.save
        @publisher = Publisher.new
        @publisher.save
      end
      it "sets the association" do
        @book.library = @library
        expect(@book.library.id).to eq @library.id
        @book.save

        expect(Book.find(@book.id).library.id).to eq @library.id
      end
      it "clears the association" do
        @book.library = @library
        @book.library = nil
        @book.save

        expect(Book.find(@book.id).library).to be_nil
      end

      it "replaces the association" do
        @library2 = Library.new
        @library2.save
        @book.library = @library
        @book.save
        @book.library = @library2
        @book.save
        expect(Book.find(@book.id).library.id).to eq @library2.id
      end

      it "only replaces the matching class association" do
        @publisher2 = Publisher.new
        @publisher2.save

        @book.publisher = @publisher
        @book.author = @author
        @book.save!

        @book.publisher = @publisher2
        @book.save!

        new_book = Book.find(@book.id)
        expect(new_book.publisher.id).to eq @publisher2.id
        expect(new_book.author.id).to eq @author.id
      end

      it "only clears the matching class association" do
        @book.publisher = @publisher
        @book.author = @author
        @book.save

        @book.author = nil
        @book.save

        expect(Book.find(@book.id).author).to be_nil
        expect(Book.find(@book.id).publisher.id).to eq @publisher.id
      end

      it "is able to be set by id" do
        @book.library_id = @library.id
        expect(@book.library_id).to eq @library.id
        expect(@book.library.id).to eq @library.id
        @book.save
        expect(Book.find(@book.id).library_id).to eq @library.id
      end
    end
  end

  describe "single direction habtm" do
    before :all do
      class Course < ActiveFedora::Base
        has_and_belongs_to_many :textbooks, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end

      class Textbook < ActiveFedora::Base
        has_many :courses, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end
    end
    after :all do
      Object.send(:remove_const, :Course)
      Object.send(:remove_const, :Textbook)
    end

    describe "with a parent that has two children" do
      before do
        @course = Course.create
        @t1 = Textbook.create
        @t2 = Textbook.create
        @course.textbooks = [@t1, @t2]
        @course.save
      end

      it "loads the association stored in the parent" do
        @reloaded_course = Course.find(@course.id)
        expect(@reloaded_course.textbooks).to contain_exactly @t1, @t2
      end

      it "allows a parent to be deleted from the has_many association" do
        @reloaded_course = Course.find(@course.id)
        @t1.courses.delete(@reloaded_course)
        @reloaded_course.save

        @reloaded_course = Course.find(@course.id)
        expect(@reloaded_course.textbooks).to eq [@t2]
      end

      it "allows replacing the children" do
        @t3 = Textbook.create
        @t4 = Textbook.create
        @course.textbooks = [@t3, @t4]
        @course.save

        expect(@course.reload.textbooks).to contain_exactly @t3, @t4
      end

      it "allows a child to be deleted from the has_and_belongs_to_many association" do
        @reloaded_course = Course.find(@course.id)
        @reloaded_course.textbooks.delete(@t1)
        @reloaded_course.save
        @t1.save

        @reloaded_course = Course.find(@course.id)
        expect(@reloaded_course.textbooks).to eq [@t2]
      end
    end
  end

  describe "association hooks" do
    describe "for habtm" do
      before :all do
        class LibraryBook < ActiveFedora::Base
          has_and_belongs_to_many :pages, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, after_remove: :after_hook, before_remove: :before_hook

          def before_hook(m)
            say_hi(m)
            before_count(m.reload.library_books.count)
          end

          def after_hook(m)
            say_hi(m)
            after_count(m.reload.library_books.count)
          end

          def say_hi(_var); end
        end

        class Page < ActiveFedora::Base
          has_many :library_books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
        end
      end
      after :all do
        Object.send(:remove_const, :LibraryBook)
        Object.send(:remove_const, :Page)
      end

      describe "removing association" do
        subject(:book) do
          book = LibraryBook.create
          book.pages << p1 << p2
          book.save!
          book
        end
        let(:p1) { Page.create }
        let(:p2) { Page.create }

        it "saves between the before and after hooks" do
          expect(book).to receive(:before_count).with(1)
          expect(book).to receive(:after_count).with(0)
          expect(book).to receive(:say_hi).with(p2).twice
          book.pages.delete(p2)
        end
      end
    end
    describe "for has_many" do
      before :all do
        class LibraryBook < ActiveFedora::Base
          has_many :pages, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, after_remove: :say_hi
        end

        class Page < ActiveFedora::Base
          belongs_to :library_book, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
        end
      end

      after :all do
        Object.send(:remove_const, :LibraryBook)
        Object.send(:remove_const, :Page)
      end

      describe "removing association" do
        let(:p1) { book.pages.build }
        let(:p2) { book.pages.build }
        let(:book) { LibraryBook.new }
        it "runs the hooks" do
          expect(book).to receive(:say_hi).with(p2)
          book.pages.delete(p2)
        end
      end
    end
  end

  describe "has_many" do
    describe "when an object doesn't have a property, and the class_name is predictable" do
      before(:all) do
        class Bauble < ActiveFedora::Base
          belongs_to :media_object, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
        end

        class MediaObject < ActiveFedora::Base
          has_many :baubles
        end
      end
      after :all do
        Object.send(:remove_const, :Bauble)
        Object.send(:remove_const, :MediaObject)
      end

      it "finds the reflection that bears the predicate" do
        expect(MediaObject.new.association(:baubles).send(:find_reflection)).to eq Bauble._reflect_on_association(:media_object)
      end
    end

    describe "when an object doesn't have a property, but has a class_name" do
      before :all do
        class MasterFile < ActiveFedora::Base
          belongs_to :media_object, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
        end

        class MediaObject < ActiveFedora::Base
          has_many :parts, class_name: 'MasterFile'
        end
      end

      after :all do
        Object.send(:remove_const, :MasterFile)
        Object.send(:remove_const, :MediaObject)
      end

      it "finds the reflection that bears the predicate" do
        expect(MediaObject.new.association(:parts).send(:find_reflection)).to eq MasterFile._reflect_on_association(:media_object)
      end
    end

    describe "an object has an explicity property" do
      before :all do
        class Bauble < ActiveFedora::Base
          belongs_to :media_object, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
        end

        class MediaObject < ActiveFedora::Base
          has_many :baubles, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasEquivalent
        end
      end

      after :all do
        Object.send(:remove_const, :Bauble)
        Object.send(:remove_const, :MediaObject)
      end

      it "finds the reflection that bears the predicate" do
        expect(MediaObject.new.association(:baubles).send(:find_reflection)).to eq MediaObject._reflect_on_association(:baubles)
      end
    end
  end

  describe "casting when the class name is ActiveFedora::Base" do
    describe "for habtm" do
      before :all do
        class Novel < ActiveFedora::Base
          has_and_belongs_to_many :contents, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
        end

        class TextBook < ActiveFedora::Base
          has_and_belongs_to_many :contents, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
        end

        class Text < ActiveFedora::Base
          has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
        end

        class Image < ActiveFedora::Base
          has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
        end
      end

      after :all do
        Object.send(:remove_const, :Novel)
        Object.send(:remove_const, :TextBook)
        Object.send(:remove_const, :Text)
        Object.send(:remove_const, :Image)
      end

      describe "saving between the before and after hooks" do
        let(:text1) { Text.create }
        let(:image1) { Image.create }
        let(:text2) { Text.create }
        let(:image2) { Image.create }
        let(:book1) { TextBook.create }
        let(:book2) { Novel.create }

        it "works when added via the has_and_belongs_to_many" do
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
