require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Library < ActiveFedora::Base 
      has_many :books
    end

    class Book < ActiveFedora::Base 
      belongs_to :library, property: :has_constituent
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
      expect(book.library_id).to eq(library.id)
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
      expect(book.library_id).to eq(library.id)
    end

    it "safely handles invalid data" do
      book[:library_id] = 'bad:identifier'
      expect(book.library).to be_nil
    end
  end

  describe "getting the id property" do
    it "should be accessable via []" do
      book[:library_id] = library.id
      expect(book[:library_id]).to eq(library.id)
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
        belongs_to :simple_collection, property: :is_part_of, class_name: 'SimpleCollection'
        belongs_to :complex_collection, property: :is_part_of, class_name: 'ComplexCollection'
      end

      class ComplexObject < SimpleObject
      end

      class SimpleCollection < ActiveFedora::Base
        has_many :objects, property: :is_part_of, class_name: 'SimpleObject'
        has_many :complex_objects, property: :is_part_of, class_name: 'ComplexObject'
      end

      class ComplexCollection < SimpleCollection
      end

    end
    after :all do
      Object.send(:remove_const, :SimpleObject)
      Object.send(:remove_const, :ComplexObject)
      Object.send(:remove_const, :SimpleCollection)
      Object.send(:remove_const, :ComplexCollection)
    end

    describe "saving between the before and after hooks" do
      before do
        @simple_collection = SimpleCollection.create
        @complex_collection = ComplexCollection.create

        @simple_object = SimpleObject.create
        @simple_object_second = SimpleObject.create
        @simple_object_third = SimpleObject.create
        @complex_object = ComplexObject.create
        @complex_object_second = ComplexObject.create

        #Need to add the simpler cmodel here as currently inheritance support is read-only.
        #See ActiveFedora pull request 207 on how to do this programmatically.
        @complex_object.add_relationship(:has_model, @complex_object.class.superclass.to_class_uri)
        @complex_collection.add_relationship(:has_model, @complex_collection.class.superclass.to_class_uri)

        @simple_collection.objects = [@simple_object, @simple_object_second, @complex_object]
        @simple_collection.save!
        @complex_collection.objects = [@simple_object_third, @complex_object_second]
        @complex_collection.save!
        @complex_object.save!
        @simple_object.save!
        @simple_object_second.save!
      end


      it "casted association methods should work and return the most complex class" do

        expect(@complex_object.simple_collection).to be_instance_of SimpleCollection
        expect(@complex_object.complex_collection).to be_nil

        expect(@complex_object_second.simple_collection).to be_instance_of ComplexCollection
        expect(@complex_object_second.complex_collection).to be_instance_of ComplexCollection

        expect(@simple_object.simple_collection).to be_instance_of SimpleCollection
        expect(@simple_object.complex_collection).to be_nil

        expect(@simple_object_second.simple_collection).to be_instance_of SimpleCollection
        expect(@simple_object_second.complex_collection).to be_nil

        expect(@simple_object_third.simple_collection).to be_instance_of ComplexCollection
        expect(@simple_object_third.complex_collection).to be_instance_of ComplexCollection

        expect(@simple_collection.objects.size).to eq(3)
        expect(@simple_collection.objects[0]).to be_instance_of SimpleObject
        expect(@simple_collection.objects[1]).to be_instance_of SimpleObject
        expect(@simple_collection.objects[2]).to be_instance_of ComplexObject

        expect(@complex_collection.objects.size).to eq(2)
        expect(@complex_collection.objects[0]).to be_instance_of SimpleObject
        expect(@complex_collection.objects[1]).to be_instance_of ComplexObject

      end

      it "specified ending relationships should ignore classes not specified" do
        expect(@simple_collection.complex_objects.size).to eq(1)
        expect(@simple_collection.complex_objects[0]).to be_instance_of ComplexObject
        expect(@simple_collection.complex_objects[1]).to be_nil

        expect(@complex_collection.complex_objects.size).to eq(1)
        expect(@complex_collection.complex_objects[0]).to be_instance_of ComplexObject
        expect(@complex_collection.complex_objects[1]).to be_nil
      end

      after do
        @simple_object.delete
        @simple_object_second.delete
        @complex_object.delete
      end
    end
  end
end


