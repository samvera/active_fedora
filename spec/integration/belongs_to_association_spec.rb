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
      def assert_content_model
        self.has_model = [self.class.to_s, self.class.superclass.to_s]
      end
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
    it "stores it" do
      book.library_id = library.id
      expect(book.library_id).to eq library.id
    end

    it "marks it as changed" do
      expect {
        book.library_id = library.id
      }.to change { book.changed? }.from(false).to(true)
    end

    describe "reassigning the parent_id" do
      let(:library2) { Library.create }
      before { book.library = library2 }

      it "updates the object" do
        expect(book.library).to eq library2 # cause the association to set @loaded
        library_proxy = book.send(:association_instance_get, :library)
        expect(library_proxy).to_not be_stale_target
        book.library_id = library.id
        expect(library_proxy).to be_stale_target
        expect(book.library).to eq library
      end
    end

    it "is settable via []=" do
      book[:library_id] = library.id
      expect(book.library_id).to eq library.id
    end
  end

  describe "getting the id property" do
    it "is accessable via []" do
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

    it "casts to the most specific class for the association" do
      expect(@library2.books[0]).to be_instance_of Book
      expect(@library2.books[1]).to be_instance_of SpecialInheritedBook
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

      # NOTE: As RDF assertions seem to be returned in alphabetical order, the "Z" is to insure this is stored
      # after the SimpleObject relationship for this particular case. This is to ensure people don't just change ActiveFedora
      # to pick the first content model and it works by alphabetical chance.
      class ZComplexObject < SimpleObject
        belongs_to :simple_collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SimpleCollection'
        belongs_to :complex_collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ComplexCollection'

        def assert_content_model
          self.has_model = [self.class.to_s, self.class.superclass.to_s]
        end
      end

      class SimpleCollection < ActiveFedora::Base
        has_many :objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SimpleObject'
        has_many :complex_objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ZComplexObject'
      end

      class ComplexCollection < SimpleCollection
        has_many :objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SimpleObject'
        has_many :complex_objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ZComplexObject'

        def assert_content_model
          self.has_model = [self.class.to_s, self.class.superclass.to_s]
        end
      end
    end
    after :all do
      Object.send(:remove_const, :SimpleObject)
      Object.send(:remove_const, :ZComplexObject)
      Object.send(:remove_const, :SimpleCollection)
      Object.send(:remove_const, :ComplexCollection)
    end

    describe "saving between the before and after hooks" do
      let(:complex_object) { ZComplexObject.find(ZComplexObject.create.id) }
      let(:complex_collection) { ComplexCollection.find(ComplexCollection.create.id) }

      context "Verify that an inherited object will save and retrieve with the correct models" do
        it "has added the inverse relationship for the correct class" do
          expect(complex_object.has_model).to match_array(["SimpleObject", "ZComplexObject"])
          expect(complex_collection.has_model).to match_array(["SimpleCollection", "ComplexCollection"])
        end
      end

      context "Add a complex_object into a simple_collection" do
        let(:simple_collection) { SimpleCollection.create }

        before do
          simple_collection.objects = [complex_object]
          simple_collection.save!
          complex_collection.save!
        end
        it "has added the inverse relationship for the correct class" do
          expect(complex_object.simple_collection).to be_instance_of SimpleCollection
          expect(complex_object.complex_collection).to be_nil
        end
      end

      context "Add a complex_object into a complex_collection" do
        before do
          complex_collection.objects = [complex_object] # this sticks it into the :objects association, but since it is a ZComplexObject it should also be fetched by :complex_collection association
          complex_collection.save
        end

        it "has added the inverse relationship for the correct class" do
          expect(complex_object.complex_collection).to be_instance_of ComplexCollection
          expect(complex_object.reload.simple_collection).to be_instance_of ComplexCollection
        end
      end

      context "Adding mixed types on a base class with a filtered has_many relationship" do
        let(:simple_collection) { SimpleCollection.create }
        let(:simple_object) { SimpleObject.create }

        before do
          simple_collection.objects = [complex_object, simple_object]
          simple_collection.save!
        end
        it "ignores objects whose classes aren't specified" do
          expect(simple_collection.complex_objects.size).to eq 1
          expect(simple_collection.complex_objects[0]).to be_instance_of ZComplexObject
          expect(simple_collection.complex_objects[1]).to be_nil

          expect(simple_collection.objects.size).to eq 2
          expect(simple_collection.objects[0]).to be_instance_of ZComplexObject
          expect(simple_collection.objects[1]).to be_instance_of SimpleObject

          expect(simple_object.simple_collection).to be_instance_of SimpleCollection
          expect(simple_object.complex_collection).to be_nil
        end
      end

      context "Adding mixed types on a subclass with a filtered has_many relationship" do
        let(:simple_object) { SimpleObject.create }

        before do
          complex_collection.objects = [complex_object, simple_object]
          complex_collection.save!
        end
        it "ignores objects who's classes aren't specified" do
          expect(complex_collection.complex_objects.size).to eq 1
          expect(complex_collection.complex_objects[0]).to be_instance_of ZComplexObject
          expect(complex_collection.complex_objects[1]).to be_nil

          expect(complex_collection.objects.size).to eq 2
          expect(complex_collection.objects[0]).to be_instance_of ZComplexObject
          expect(complex_collection.objects[1]).to be_instance_of SimpleObject

          expect(simple_object.complex_collection).to be_instance_of ComplexCollection
          expect(simple_object.reload.simple_collection).to be_instance_of ComplexCollection
        end
      end
    end
  end

  describe "casting inheritance super class test cases" do
    before :all do
      class SuperclassObject < ActiveFedora::Base
        belongs_to :superclass_collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SuperclassCollection'

        def assert_content_model
          self.has_model = [self.class.to_s, self.class.superclass.to_s]
        end
      end

      class SubclassObject < SuperclassObject
      end

      class SuperclassCollection < ActiveFedora::Base
        has_many :objects, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'SuperclassObject'
      end
    end
    after :all do
      Object.send(:remove_const, :SuperclassObject)
      Object.send(:remove_const, :SubclassObject)
      Object.send(:remove_const, :SuperclassCollection)
    end

    describe "Adding subclass objects" do
      let(:superclass_collection) { SuperclassCollection.create }
      let(:superclass_object) { SubclassObject.create }

      context "Add a subclass_object into a superclass_collection" do
        before do
          superclass_collection.objects = [subclass_object]
          superclass_collection.save!
        end
        it "has added the inverse relationship for the correct class" do
          expect(subclass_object.superclass_collection).to be_instance_of SuperclassCollection
        end
      end

      context "Set the superclass_collection of a subclass object"
      let(:subclass_object) { SubclassObject.create }

      before do
        subclass_object.superclass_collection = superclass_collection
        subclass_object.save!
      end
      it "has added the inverse relationship for the correct class" do
        expect(superclass_collection.objects.size).to eq 1
        expect(superclass_collection.objects[0]).to be_instance_of SubclassObject
      end
    end
  end
end
