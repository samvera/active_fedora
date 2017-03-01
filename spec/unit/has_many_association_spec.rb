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
  let(:book) { Book.new(id: 'subject-a') }
  let(:page) { Page.new(id: 'object-b') }

  describe "setting the foreign key" do
    before do
      allow(book).to receive(:new_record?).and_return(false)
      allow(page).to receive(:save).and_return(true)
      allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    end

    let(:reflection) { ActiveFedora::Reflection.create(:has_many, 'pages', nil, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf }, Book) }
    let(:association) { described_class.new(book, reflection) }

    it "sets the book_id attribute" do
      expect(association).to receive(:callback).twice
      expect(page).to receive(:[]=).with('book_id', book.id)
      association.concat page
    end
  end

  describe "#find_polymorphic_inverse" do
    subject(:af_page) { association.send(:find_polymorphic_inverse, page) }

    let(:book_reflection) { ActiveFedora::Reflection.create(:has_many, 'pages', nil, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf }, Book) }
    let(:association) { described_class.new(book, book_reflection) }

    context "when a has_many is present" do
      before do
        # :books must come first, so that we can test that is being passed over in favor of :contents
        Page.has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
        Page.has_and_belongs_to_many :contents, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
      end

      it "finds the HABTM reflection" do
        expect(af_page.name).to eq :contents
      end
    end

    context "when multiple belongs_to are present" do
      before do
        # :foo must come first, so that we can test that is being passed over in favor of :bar
        Page.belongs_to :foo, predicate: ::RDF::Vocab::DC.isPartOf, class_name: 'ActiveFedora::Base'
        Page.belongs_to :bar, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'
      end

      it "finds the belongs_to reflection" do
        expect(af_page.name).to eq :bar
      end
    end
  end

  context "when inverse doesn't have a predictable name" do
    before do
      class TimeSpan < ActiveFedora::Base
        has_many :images, inverse_of: :created # predicate: ::RDF::Vocab::DC.created
      end

      class Image < ActiveFedora::Base
        has_and_belongs_to_many :created, predicate: ::RDF::Vocab::DC.created, class_name: 'TimeSpan'
      end
    end

    after do
      Object.send(:remove_const, :TimeSpan)
      Object.send(:remove_const, :Image)
    end

    let(:owner) { TimeSpan.new }
    let(:reflection) { TimeSpan._reflect_on_association(:images) }

    it "finds the predicate" do
      expect { described_class.new(owner, reflection) }.not_to raise_error
    end
  end

  describe "scope" do
    before do
      class Library < ActiveFedora::Base
        has_many :images
      end

      class Image < ActiveFedora::Base
        belongs_to :library, predicate: ::RDF::URI('http://example.com/library')
      end
    end

    after do
      Object.send(:remove_const, :Library)
      Object.send(:remove_const, :Image)
    end

    context "of an unsaved target" do
      subject { Library.new.images.scope }
      it { is_expected.to be_kind_of ActiveFedora::NullRelation }
    end
  end

  describe "#ids_reader" do
    let(:owner) { instance_double(ActiveFedora::Base) }
    let(:reflection) { instance_double(ActiveFedora::Reflection::AssociationReflection, check_validity!: true) }
    let(:association) { described_class.new(owner, reflection) }

    let(:r1) { ActiveFedora::Base.new(id: 'r1-id', &:mark_for_destruction) }
    let(:r2) { ActiveFedora::Base.new(id: 'r2-id') }

    context "when some records are marked_for_destruction" do
      before do
        allow(association).to receive(:loaded?).and_return(true)
        allow(association).to receive(:load_target).and_return([r1, r2])
      end

      it "only returns the records not marked for destruction" do
        expect(association.ids_reader).to eq ['r2-id']
      end
    end
  end
end
