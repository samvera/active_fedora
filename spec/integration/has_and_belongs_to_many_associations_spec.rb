require 'spec_helper'

describe ActiveFedora::Base do
  describe "with inverse" do
    before do
      class Book < ActiveFedora::Base 
        has_and_belongs_to_many :topics, :property=>:has_topic, :inverse_of=>:is_topic_of
        has_and_belongs_to_many :collections, :property=>:is_member_of_collection
      end

      class SpecialInheritedBook < Book
      end


      class Collection < ActiveFedora::Base
      end

      class Topic < ActiveFedora::Base 
        has_and_belongs_to_many :books, :property=>:is_topic_of
      end
    end

    after do
      Object.send(:remove_const, :SpecialInheritedBook)
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Collection)
      Object.send(:remove_const, :Topic)
    end

    describe "an unsaved instance" do
      before do
        @topic1 = Topic.create
        @topic2 = Topic.create
        @book = Book.create
        @special_book = SpecialInheritedBook.create #TODO this isnt' needed in every test.
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

      it "Should find inherited objects along with base objects" do
        @book.topics << @topic1
        @special_book.topics << @topic1
        @topic1.books.should == [@book, @special_book]
        @topic1.reload.books.should == [@book, @special_book]
      end

      it "Should cast found books to the correct cmodel" do
        @topic1.books[0].class == Book
        @topic1.books[1].class == SpecialInheritedBook
      end

      after do
        @topic1.delete
        @topic2.delete
        @book.delete
        @special_book.delete
      end
    end
    describe "a saved instance" do
      before do
        @book = Book.create
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
        @book.delete
        @topic1.delete
        @topic2.delete
      end
    end
  end

  describe "when inverse is not specified" do
    before do
      class Book < ActiveFedora::Base 
        has_and_belongs_to_many :collections, :property=>:is_member_of_collection
      end

      class Collection < ActiveFedora::Base
      end
    end

    after do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Collection)
    end

    let (:book) { Book.create }
    let (:collection) { Collection.create }
    before do
      book.collections << collection
      book.save!
    end
    after do
      collection.delete
      book.delete
    end
    it "should have a collection" do
      book.relationships(:is_member_of_collection).should == [collection.internal_uri]
      book.collections.should == [collection]
    end
    it "habtm should not set foreign relationships if :inverse_of is not specified" do
       collection.relationships(:is_member_of_collection).should == []
    end
    it "should load the collections" do
      reloaded = Book.find(book.pid)
      reloaded.collections.should == [collection]
    end
  end


  describe "when destroying the association" do
    describe "without callbacks" do
      before do
        class Book < ActiveFedora::Base 
          has_and_belongs_to_many :collections, property: :is_member_of_collection
        end

        class Collection < ActiveFedora::Base
        end
      end

      after do
        Object.send(:remove_const, :Book)
        Object.send(:remove_const, :Collection)
      end

      let (:book) { Book.create }
      let (:collection1) { Collection.create }
      let (:collection2) { Collection.create }
      before do
        book.collections << collection1 << collection2
        book.save!
      end
      after do
        collection1.delete
        collection2.delete
        book.delete
      end

      it "delete should cause the entries to be removed from RELS-EXT, but not destroy the original record" do
        book.collections.should == [collection1, collection2]
        book.collections.delete(collection1)
        book.collections.should == [collection2]
        book.save!
        book.reload
        book.collections.should == [collection2]
        expect {Collection.find(collection1.pid)}.to_not be_nil
      end

      it "destroy should cause the entries to be removed from RELS-EXT, but not destroy the original record" do
        book.collections.should == [collection1, collection2]
        book.collections.destroy(collection1)
        book.collections.should == [collection2]
        book.save!
        book.reload
        book.collections.should == [collection2]
        expect {Collection.find(collection1.pid)}.to_not be_nil
      end
    end

    describe "with remove callbacks" do
      before do
        class Book < ActiveFedora::Base 
          has_and_belongs_to_many :collections, 
                                  property: :is_member_of_collection,
                                  before_remove: :foo, after_remove: :bar
        end

        class Collection < ActiveFedora::Base
        end
      end

      after do
        Object.send(:remove_const, :Book)
        Object.send(:remove_const, :Collection)
      end

      let (:book) { Book.create }
      let (:collection) { Collection.create }
      before do
        book.collections << collection
        book.save!
      end
      after do
        collection.delete
        book.delete
      end

      it "destroy should cause the before_remove and after_remove callback to be triggered" do
        book.should_receive(:foo).with(collection)
        book.should_receive(:bar).with(collection)
        book.collections.destroy(collection)
      end

      it "delete should cause the before_remove and after_remove callback to be triggered" do
        book.should_receive(:foo).with(collection)
        book.should_receive(:bar).with(collection)
        book.collections.delete(collection)
      end

      it "should not remove if an exception is thrown in before_remove" do
        book.should_receive(:foo).with(collection).and_raise
        book.should_not_receive(:bar)
        begin
          book.collections.delete(collection)
        rescue RuntimeError
        end
        book.collections.should == [collection]
      end
    end

    describe "with add callbacks" do
      before do
        class Book < ActiveFedora::Base 
          has_and_belongs_to_many :collections, 
                                  property: :is_member_of_collection,
                                  before_add: :foo, after_add: :bar
        end

        class Collection < ActiveFedora::Base
        end
      end

      after do
        Object.send(:remove_const, :Book)
        Object.send(:remove_const, :Collection)
      end

      let (:book) { Book.create }
      let (:collection) { Collection.create }
      after do
        collection.delete
        book.delete
      end

      it "shift should cause the before_add and after_add callback to be triggered" do
        book.should_receive(:foo).with(collection)
        book.should_receive(:bar).with(collection)
        book.collections << collection
      end

      it "assignment should cause the before_add and after_add callback to be triggered" do
        book.should_receive(:foo).with(collection)
        book.should_receive(:bar).with(collection)
        book.collections = [collection]
      end

      it "should not add if an exception is thrown in before_add" do
        book.should_receive(:foo).with(collection).and_raise
        book.should_not_receive(:bar)
        begin
          book.collections << collection
        rescue RuntimeError
        end
        book.collections.should == []
      end
    end

  end

end

describe "Autosave" do
  before do
    class Item < ActiveFedora::Base
      has_many :components
      has_metadata "foo", type: ActiveFedora::SimpleDatastream do |m|
        m.field "title", :string
      end
      has_attributes :title, datastream: 'foo'
    end
    class Component < ActiveFedora::Base
      has_and_belongs_to_many :items, :property => :is_part_of
      has_metadata "foo", type: ActiveFedora::SimpleDatastream do |m|
        m.field "description", :string
      end
      has_attributes :description, datastream: 'foo'
    end
  end

  after do
      Object.send(:remove_const, :Item)
      Object.send(:remove_const, :Component)
  end

  describe "From the has_and_belongs_to_many side" do
    let(:component) { Component.create(items: [Item.new(title: 'my title')]) }

    it "should save dependent records" do
      component.reload
      component.items.first.title.should == 'my title'
    end
  end
  describe "From the has_many side" do
    let(:item) { Item.create(components: [Component.new(description: 'my description')]) }

    it "should save dependent records" do
      item.reload
      item.components.first.description.should == 'my description'
    end
  end

end

