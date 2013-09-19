require 'spec_helper'

describe "Looking up collection members" do
  before :all do
    class Library < ActiveFedora::Base 
      has_many :books, :property=>:has_constituent
    end

    class Book < ActiveFedora::Base 
      belongs_to :library, :property=>:has_constituent
    end
  end
  after :all do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Library)
  end
  describe "of has_many" do
    let(:book) { Book.create }
    let(:library) { Library.create() }
    before do
      library.books = [book]
      library.save!
    end
    it "should read book_ids from solr" do
      library.reload.book_ids.should ==[book.pid]
    end
    it "should read books from solr" do
      library.reload.books.should ==[book]
    end
  end
end

describe "When two or more relationships share the same property" do 
  before do
    class Book < ActiveFedora::Base 
      has_many :collections, :class_name=>'Collection'
      has_many :people
    end

    class Person < ActiveFedora::Base
      belongs_to :book, :property=>:is_part_of
    end

    class Collection < ActiveFedora::Base
      belongs_to :book, :property=>:is_part_of
    end

    @book = Book.create!
    @person1 = Person.create!(:book=>@book)
    @person2 = Person.create!(:book=>@book)
  end
  after do
      Object.send(:remove_const, :Collection)
      Object.send(:remove_const, :Person)
      Object.send(:remove_const, :Book)
  end

  it "Should only return relationships of the correct class" do
    @book.reload
    @book.people.should == [@person1, @person2]
    @book.collections.should == []
  end
end

describe "When relationship is restricted to AF::Base" do
  before do
    class Email < ActiveFedora::Base 
      has_many :attachments, :property=>:is_part_of, :class_name=>'ActiveFedora::Base'
    end

    class Image < ActiveFedora::Base
      belongs_to :email, :property=>:is_part_of
    end

    class PDF < ActiveFedora::Base
      belongs_to :email, :property=>:is_part_of
    end

    @book = Email.create!
    @image = Image.create!(:email=>@book)
    @pdf = PDF.create!(:email=>@book)
  end
  after do
      Object.send(:remove_const, :Image)
      Object.send(:remove_const, :PDF)
      Object.send(:remove_const, :Email)
  end


  it "Should not restrict relationships " do
    @book.reload
    @book.attachments.should == [@image, @pdf]
  end
end

describe "Deleting a dependent relationship" do
  before do
    class Item < ActiveFedora::Base
      has_many :components, :property => :is_part_of
    end
    class Component < ActiveFedora::Base
      belongs_to :item, :property => :is_part_of
    end
  end

  after do
      Object.send(:remove_const, :Item)
      Object.send(:remove_const, :Component)
  end

  let(:item) { Item.create }
  let(:component) { Component.create }

  it "should remove the relationships that point at that object" do
    component.item = item
    component.save!
    item.delete
    component.reload
    component.relationships(:is_part_of).should == []
  end

  it "should only try to delete objects that exist in the datastore (not cached objects)" do
    item.components << component
    item.save!
    component.delete
    item.delete
  end

end

