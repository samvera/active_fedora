require 'spec_helper'

describe ActiveFedora::Associations::HasManyAssociation do
  before do
    class Book < ActiveFedora::Base
    end
    class Page < ActiveFedora::Base
    end
  end

  after do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Page)
  end
  let(:book) { Book.new('subject-a') }
  let(:page) { Page.new('object-b') }

  describe "setting the foreign key" do
    before do
      allow(book).to receive(:new_record?).and_return(false)
      allow(page).to receive(:save).and_return(true)
      allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    end

    let(:reflection) { Book.create_reflection(:has_many, 'pages', { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf }, Book) }
    let(:association) { ActiveFedora::Associations::HasManyAssociation.new(book, reflection) }

    it "should set the book_id attribute" do
      expect(association).to receive(:callback).twice
      expect(page).to receive(:[]=).with('book_id', book.id)
      association.concat page
    end
  end

  describe "Finding a polymorphic inverse relation" do

    before do
      # :books must come first, so that we can test that is being passed over in favor of :contents
      Page.has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
      Page.has_and_belongs_to_many :contents, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
    end
    let(:book_reflection) { Book.create_reflection(:has_many, 'pages', { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf }, Book) }
    let(:association) { ActiveFedora::Associations::HasManyAssociation.new(book, book_reflection) }

    subject { association.send(:find_polymorphic_inverse, page) }

    it "should find the HABTM reflection" do
      expect(subject.name).to eq :contents
    end
  end
end
