require 'spec_helper'

describe "Collection members" do
  before :all do
    class Library < ActiveFedora::Base
      has_many :books
    end

    class Book < ActiveFedora::Base
      belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
    end
  end
  after :all do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Library)
  end

  describe "size of has_many" do
    let(:library) { Library.create }
    context "when no members" do
      it "should cache the count" do
        expect(library.books).not_to be_loaded
        expect(library.books.size).to eq(0)
        expect(library.books).to be_loaded
        expect(library.books.any?).to be false
      end
    end

    context "loading the association prior to a save that affects the association" do
      let(:library) { Library.new }
      before do
        Book.create
        library.books
        library.save
      end
      subject { library.books.size }
      it { is_expected.to eq 0 }
    end
  end

  describe "looking up has_many" do
    let(:book) { Book.create }
    let(:library) { Library.create() }
    before do
      library.books = [book]
      library.save!
      library.reload
    end

    it "should read book_ids from solr" do
      expect(library.book_ids).to eq [book.id]
    end
    it "should read books from solr" do
      expect(library.books).to eq [book]
    end

    it "should cache the results" do
      expect(library.books).to_not be_loaded
      expect(library.books).to eq [book]
      expect(library.books).to be_loaded
    end
    it "should load from solr" do
      expect(library.books.load_from_solr.map {|r| r["id"]}).to eq([book.id])
    end
    it "should load from solr with options" do
      expect(library.books.load_from_solr(rows: 0).size).to eq(0)
    end
    it "should respond to #any?" do
      expect(library.books.any?).to be true
      expect(library.books.any? {|book| book.library == nil}).to be false
      expect(library.books.any? {|book| book.library == library}).to be true
    end
  end
end

describe "After save callbacks" do
  before :all do
    class Library < ActiveFedora::Base
      has_many :books
    end

    class Book < ActiveFedora::Base
      belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
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

  let(:library) { Library.create }
  let(:book) { Book.new(library: library) }

  it "should have the relationship available in after_save" do
    book.save!
    expect(book.library_books).to include book
  end
end

describe "When two or more relationships share the same property" do
  before do
    class Book < ActiveFedora::Base
      has_many :collections, :class_name=>'Collection'
      has_many :people
    end

    class Person < ActiveFedora::Base
      belongs_to :book, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end

    class Collection < ActiveFedora::Base
      belongs_to :book, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
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
    expect(@book.people).to eq [@person1, @person2]
    expect(@book.collections).to eq []
  end
end

describe "with an polymorphic association" do
  before do
    class Permissionable1 < ActiveFedora::Base
      has_many :permissions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, inverse_of: :access_to
    end
    class Permissionable2 < ActiveFedora::Base
      has_many :permissions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, inverse_of: :access_to
    end

    class Permission < ActiveFedora::Base
      belongs_to :access_to, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
    end
  end

  after do
    Permissionable1.destroy_all
    Object.send(:remove_const, :Permissionable1)
    Object.send(:remove_const, :Permissionable2)
    Object.send(:remove_const, :Permission)
  end
  let(:p1) { Permissionable1.create }

  it "should make an association" do
    expect(p1.permissions.create).to be_kind_of Permission
  end
end

describe "When relationship is restricted to AF::Base" do
  before do
    class Email < ActiveFedora::Base
      has_many :attachments, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, :class_name=>'ActiveFedora::Base'
    end

    class Image < ActiveFedora::Base
      belongs_to :email, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end

    class PDF < ActiveFedora::Base
      belongs_to :email, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
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
      expect(@book.attachments).to eq [@image, @pdf]
    end
  end

  describe "creating new objects with id setter" do
    let!(:image) { Image.create }
    let!(:email) { Email.create }
    let!(:pdf) { PDF.create }

    after do
      pdf.destroy
      image.destroy
      email.destroy
    end

    it "Should not restrict relationships " do
      email.attachment_ids = [image.id, pdf.id]
      email.reload
      expect(email.attachments).to eq [image, pdf]
    end
  end
end

describe "Deleting a dependent relationship" do
  before do
    class Item < ActiveFedora::Base
      has_many :components
    end
    class Component < ActiveFedora::Base
      belongs_to :item, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end
  end

  after do
      Object.send(:remove_const, :Item)
      Object.send(:remove_const, :Component)
  end

  let(:item) { Item.create }
  let(:component) { Component.create }

  context "when the relationship is set by an id" do
    let(:item_id) { item.id }
    let!(:component1) { Component.create(item_id: item_id) }
    let!(:component2) { Component.create(item_id: item_id) }

    it "should set the inverse relationship" do
      expect(component1.item.components).to match_array [component1, component2]
    end
  end

  it "should remove relationships" do
    component.item = item
    component.save!
    expect(item.components).to eq [component]
    item.components.delete(component)
    item.reload
    component.reload
    expect(component['item_id']).to be_nil
    expect(item.components).to eq []
  end

  it "should remove the relationships that point at that object" do
    component.item = item
    component.save!
    item.delete
    component.reload
    expect(component['item_id']).to be_nil
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
  context "with new objects" do
    context "a has_many - belongs_to relationship" do
      before do
        class Item < ActiveFedora::Base
          has_many :components
          has_metadata "foo", type: ActiveFedora::SimpleDatastream do |m|
            m.field "title", :string
          end
          Deprecation.silence(ActiveFedora::Attributes) do
            has_attributes :title, datastream: 'foo'
          end
        end
        class Component < ActiveFedora::Base
          belongs_to :item, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
          has_metadata "foo", type: ActiveFedora::SimpleDatastream do |m|
            m.field "description", :string
          end
          Deprecation.silence(ActiveFedora::Attributes) do
            has_attributes :description, datastream: 'foo'
          end
        end
      end

      after do
        Object.send(:remove_const, :Item)
        Object.send(:remove_const, :Component)
      end

      context "From the belongs_to side" do
        let(:component) { Component.create(item: Item.new(title: 'my title')) }

        it "should save dependent records" do
          component.reload
          expect(component.item.title).to eq 'my title'
        end
      end

      context "From the has_many side" do
        let(:item) { Item.create(components: [Component.new(description: 'my description')]) }

        it "should save dependent records" do
          item.reload
          expect(item.components.first.description).to eq 'my description'
        end
      end
    end

    context "a has_many - has_and_belongs_to_many relationship" do
      context "with ActiveFedora::Base as classes" do
        before do
          class Novel < ActiveFedora::Base
            has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
            has_and_belongs_to_many :contents, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
          end
          class Text < ActiveFedora::Base
            has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
          end
        end
        let(:text) { Text.create}
        let(:novel) { Novel.create}

        after do
          Object.send(:remove_const, :Novel)
          Object.send(:remove_const, :Text)
        end

        it "should work when added via the has_many" do
          text.books << novel
          novel.save
          expect(novel.reload.contents).to eq [text]
          expect(text.reload.books).to eq [novel]
        end

        it "should work when added via the has_and_belongs_to_many" do
          novel.contents << text
          novel.save!
          text.reload
          expect(text.books).to eq [novel]
        end

      end
    end
  end

  context "with updated objects" do
    
    before :all do
      class Library < ActiveFedora::Base
        has_many :books, autosave: true
      end

      class Book < ActiveFedora::Base
        belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
        property :title, predicate: ::RDF::DC.title
      end
    end
    after :all do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Library)
    end
  
    let(:library) { Library.create }
    
    before do
      library.books.create(title: ["Great Book"])
      library.books.first.title = ["Better book"]
      library.save
    end

    subject { library.books(true) }

    it "saves the new title" do
      expect(subject.first.title).to eql ["Better book"]
    end

  end
end
