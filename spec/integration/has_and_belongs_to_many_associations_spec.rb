require 'spec_helper'

describe ActiveFedora::Base do
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
      @topic1.delete
      @topic2.delete
    end
  end
  describe "a saved instance" do
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
