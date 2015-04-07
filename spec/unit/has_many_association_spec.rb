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
    let(:association) { described_class.new(book, reflection) }

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
    let(:association) { described_class.new(book, book_reflection) }

    subject { association.send(:find_polymorphic_inverse, page) }

    it "should find the HABTM reflection" do
      expect(subject.name).to eq :contents
    end
  end


  context "when inverse doesn't have a predictable name" do
    before do
      class TimeSpan < ActiveFedora::Base
        has_many :images, inverse_of: :created # predicate: ::RDF::DC.created
      end

      class Image < ActiveFedora::Base
         has_and_belongs_to_many :created, predicate: ::RDF::DC.created, class_name: 'TimeSpan'
      end
    end

    after do
      Object.send(:remove_const, :TimeSpan)
      Object.send(:remove_const, :Image)
    end

    let(:owner) { TimeSpan.new }
    let(:reflection) { TimeSpan.reflect_on_association(:images) }

    it "finds the predicate" do
      expect { described_class.new(owner, reflection) }.not_to raise_error
    end
  end
end
