require 'spec_helper'

describe "Looking up collection members" do
  before :all do
    class Library < ActiveFedora::Base 
      has_many :books
    end

    class Book < ActiveFedora::Base 
      belongs_to :library, property: :has_constituent
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
      library.reload
    end
    it "should read book_ids from solr" do
      expect(library.book_ids).to eq [book.pid]
    end
    it "should read books from solr" do
      expect(library.books).to eq [book]
    end

    it "should cache the results" do
      expect(library.books.loaded?).to be_false
      expect(library.books).to eq [book]
      expect(library.books.loaded?).to be_true
    end
  end
end

describe "After save callbacks" do
  before :all do
    class Library < ActiveFedora::Base 
      has_many :books
    end

    class Book < ActiveFedora::Base 
      belongs_to :library, :property=>:has_constituent
      after_save :find_self
      attr_accessor :library_books

      def find_self
        # It's important we have the to_a so that it fetches the relationship immediately instead of lazy loading
        self.library_books = library.books.to_a
      end
    end
  end
  after :all do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Library)
  end
  let(:library) { Library.create() }
  let(:book) { Book.new(library: library) }
  it "should have the relationship available in after_save" do
    book.save!
    book.library_books.should include book
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
  end

  after do
      Object.send(:remove_const, :Image)
      Object.send(:remove_const, :PDF)
      Object.send(:remove_const, :Email)
  end


  describe "creating new objects with object relationships" do
    before do
      @book = Email.create!
      @image = Image.create!(:email=>@book)
      @pdf = PDF.create!(:email=>@book)
    end
    it "Should not restrict relationships " do
      @book.reload
      @book.attachments.should == [@image, @pdf]
    end
  end

  describe "creating new objects with id setter" do
    let!(:image) { Image.create }
    let!(:email) { Email.create }
    let!(:pdf) { PDF.create }

    after do
      email.destroy
      pdf.destroy
      image.destroy
    end

    it "Should not restrict relationships " do
      email.attachment_ids = [image.id, pdf.id]
      email.reload
      email.attachments.should == [image, pdf]
    end
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

  it "should remove relationships" do
    component.item = item
    component.save!
    item.components.should == [component]
    item.components.delete(component)
    item.reload
    component.reload
    component.relationships(:is_part_of).should == []
    item.components.should == []
  end

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

  it "should not save deleted objects" do
    item.components << component
    item.save!
    c2 = Component.find(component.id)
    c2.delete
    item.delete
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
      belongs_to :item, :property => :is_part_of
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

  describe "From the belongs_to side" do
    let(:component) { Component.create(item: Item.new(title: 'my title')) }

    it "should save dependent records" do
      component.reload
      component.item.title.should == 'my title'
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


