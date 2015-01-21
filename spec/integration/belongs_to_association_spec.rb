require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Library < ActiveFedora::Base
      has_many :books
    end

    class Book < ActiveFedora::Base
      belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
    end
    class SpecialInheritedBook < Book
    end

  end
  after do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :SpecialInheritedBook)
    Object.send(:remove_const, :Book)
  end

  let(:library) { Library.create }
  let(:book) { Book.new }

  describe "setting the id property" do
    it "should store it" do
      book.library_id = library.id
      expect(book.library_id).to eq library.id
    end

    it "should mark it as changed" do
      expect {
        book.library_id = library.id
      }.to change { book.changed? }.from(false).to(true)
    end

    describe "reassigning the parent_id" do
      let(:library2) { Library.create}
      before { book.library = library2 }

      it "should update the object" do
        expect(book.library).to eq library2 # cause the association to set @loaded
        library_proxy = book.send(:association_instance_get, :library)
        expect(library_proxy).to_not be_stale_target
        book.library_id = library.id
        expect(library_proxy).to be_stale_target
        expect(book.library).to eq library
      end
    end

    it "should be settable via []=" do
      book[:library_id] = library.id
      expect(book.library_id).to eq library.id
    end
  end

  describe "getting the id property" do
    it "should be accessable via []" do
      book[:library_id] = library.id
      expect(book[:library_id]).to eq library.id
    end
  end

  describe "when dealing with inherited objects" do
    before do
      @library2 = Library.create
      @special_book = SpecialInheritedBook.create

      book.library = @library2
      book.save
      @special_book.library = @library2
      @special_book.save
    end

    it "should cast to the most specific class for the association" do
      @library2.books[0].class == Book
      @library2.books[1].class == SpecialInheritedBook
    end

    after do
      @library2.delete
      @special_book.delete
    end
  end

  describe "casting inheritance detailed test cases" do
    before :all do
      class SimpleObject < ActiveFedora::Base
        belongs_to :simple_collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SimpleCollection'
        belongs_to :complex_collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ComplexCollection'
      end

      class ComplexObject < SimpleObject
        belongs_to :simple_collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SimpleCollection'
        belongs_to :complex_collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ComplexCollection'
      end

      class SimpleCollection < ActiveFedora::Base
        has_many :objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SimpleObject', autosave: true
        has_many :complex_objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ComplexObject', autosave: true
      end

      class ComplexCollection < SimpleCollection
        has_many :objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SimpleObject', autosave: true
        has_many :complex_objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ComplexObject', autosave: true
      end

    end
    after :all do
      Object.send(:remove_const, :SimpleObject)
      Object.send(:remove_const, :ComplexObject)
      Object.send(:remove_const, :SimpleCollection)
      Object.send(:remove_const, :ComplexCollection)
    end

    describe "saving between the before and after hooks" do
      context "Add a complex_object into a simple_collection" do
        before do
          @simple_collection = SimpleCollection.create
          @complex_collection = ComplexCollection.create
          @complex_object = ComplexObject.create
          @simple_collection.objects = [@complex_object]
          @simple_collection.save!
          @complex_collection.save!
        end
        it "should have added the inverse relationship for the correct class" do
          expect(@complex_object.simple_collection).to be_instance_of SimpleCollection
          expect(@complex_object.complex_collection).to be_nil
        end
      end

      context "Add a complex_object into a complex_collection" do
        before do
          @complex_collection = ComplexCollection.create
          @complex_object = ComplexObject.create
          @complex_collection.objects = [@complex_object] # this sticks it into the :objects association, but since it is a ComplexObject it should also be fetched by :complex_collection association
          @complex_collection.save
        end

        it "should have added the inverse relationship for the correct class" do
          expect(@complex_object.complex_collection).to be_instance_of ComplexCollection
          expect(@complex_object.reload.simple_collection).to be_instance_of ComplexCollection
        end
      end

      context "Adding mixed types on a base class with a filtered has_many relationship" do
        before do
          @simple_collection = SimpleCollection.create
          @complex_object = ComplexObject.create
          @simple_object = SimpleObject.create
          @simple_collection.objects = [@complex_object, @simple_object]
          @simple_collection.save!
        end
        it "ignores objects who's classes aren't specified" do
          expect(@simple_collection.complex_objects.size).to eq 1
          expect(@simple_collection.complex_objects[0]).to be_instance_of ComplexObject
          expect(@simple_collection.complex_objects[1]).to be_nil

          expect(@simple_collection.objects.size).to eq 2
          expect(@simple_collection.objects[0]).to be_instance_of ComplexObject
          expect(@simple_collection.objects[1]).to be_instance_of SimpleObject

          expect(@simple_object.simple_collection).to be_instance_of SimpleCollection
          expect(@simple_object.complex_collection).to be_nil
        end
      end

      context "Adding mixed types on a subclass with a filtered has_many relationship" do
        before do
          @complex_collection = ComplexCollection.create
          @complex_object = ComplexObject.create
          @simple_object = SimpleObject.create
          @complex_collection.objects = [@complex_object, @simple_object]
          @complex_collection.save!
        end
        it "ignores objects who's classes aren't specified" do
          expect(@complex_collection.complex_objects.size).to eq 1
          expect(@complex_collection.complex_objects[0]).to be_instance_of ComplexObject
          expect(@complex_collection.complex_objects[1]).to be_nil

          expect(@complex_collection.objects.size).to eq 2
          expect(@complex_collection.objects[0]).to be_instance_of ComplexObject
          expect(@complex_collection.objects[1]).to be_instance_of SimpleObject

          expect(@simple_object.complex_collection).to be_instance_of ComplexCollection
          expect(@simple_object.reload.simple_collection).to be_instance_of ComplexCollection
        end
      end
    end
  end
end


