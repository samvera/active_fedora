require 'spec_helper'

describe ActiveFedora::Base do
  describe "with inverse" do
    before do
      class Book < ActiveFedora::Base 
        has_and_belongs_to_many :topics, :property=>:has_topic, :inverse_of=>:is_topic_of
        has_and_belongs_to_many :collections, :property=>:is_member_of_collection
      end

      class Collection < ActiveFedora::Base
      end

      class Topic < ActiveFedora::Base 
        has_and_belongs_to_many :books, :property=>:is_topic_of
      end
    end

    after do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Collection)
      Object.send(:remove_const, :Topic)
    end

    describe "an unsaved instance" do
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
        Topic.delete_all
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
      # before_add, after_add, before_remove and after_remove
      book.collections.should == [collection1, collection2]
      book.collections.delete(collection1)
      book.collections.should == [collection2]
      book.save!
      book.reload
      book.collections.should == [collection2]
      expect {Collection.find(collection1.pid)}.to_not be_nil
    end

    it "destroy should cause the entries to be removed from RELS-EXT, but not destroy the original record" do
      # before_add, after_add, before_remove and after_remove
      book.collections.should == [collection1, collection2]
      book.collections.destroy(collection1)
      book.collections.should == [collection2]
      book.save!
      book.reload
      book.collections.should == [collection2]
      expect {Collection.find(collection1.pid)}.to_not be_nil
    end

  end

end
