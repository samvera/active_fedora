require 'spec_helper'

describe ActiveFedora::Associations::HasAndBelongsToManyAssociation do
  context "creating the reflection" do
    before do
      class Book < ActiveFedora::Base
      end
      class Page < ActiveFedora::Base
      end

      allow(book).to receive(:new_record?).and_return(false)
      allow(book).to receive(:save).and_return(true)
    end

    after do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Page)
    end

    subject(:book) { Book.new(id: 'subject-a') }

    context "a one way relationship " do
      describe "adding memeber" do
        it "sets the relationship attribute" do
          reflection = ActiveFedora::Reflection.create(:has_and_belongs_to_many, :pages, nil, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection }, Book)
          allow(ActiveFedora::SolrService).to receive(:query).and_return([])
          ac = described_class.new(book, reflection)
          expect(ac).to receive(:callback).twice
          object = Page.new
          allow(object).to receive(:new_record?).and_return(false)
          allow(object).to receive(:save).and_return(true)
          allow(object).to receive(:id).and_return('1234')

          allow(book).to receive(:[]).with('page_ids').and_return([])
          expect(book).to receive(:[]=).with('page_ids', ['1234'])

          ac.concat object
        end
      end

      describe "finding member" do
        let(:ids) { (0..15).map(&:to_s) }
        let(:reflection) { ActiveFedora::Reflection.create(:has_and_belongs_to_many, :pages, nil, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection }, Book) }
        let(:association) { described_class.new(book, reflection) }
        it "calls ActiveFedora::Base.find" do
          expect(book).to receive(:[]).with('page_ids').and_return(ids)
          expect(ActiveFedora::Base).to receive(:find).with(ids)
          association.send(:find_target)
        end
      end
    end

    context "with an inverse reflection" do
      let!(:inverse) { ActiveFedora::Reflection.create(:has_and_belongs_to_many, :books, nil, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection }, Page) }
      let(:reflection) { ActiveFedora::Reflection.create(:has_and_belongs_to_many, :pages, nil, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, inverse_of: 'books' }, Book) }
      let(:ac) { described_class.new(book, reflection) }
      let(:object) { Page.new }

      it "sets the relationship attribute on subject and object when inverse_of is given" do
        allow(ActiveFedora::SolrService).to receive(:query).and_return([])
        expect(ac).to receive(:callback).twice
        allow(object).to receive(:new_record?).and_return(false)
        allow(object).to receive(:save).and_return(true)

        allow(book).to receive(:[]).with('page_ids').and_return([])
        expect(book).to receive(:[]=).with('page_ids', [object.id])

        expect(object).to receive(:[]).with('book_ids').and_return([]).twice
        expect(object).to receive(:[]=).with('book_ids', [book.id])

        ac.concat object
      end
    end
  end

  context "class with association" do
    before do
      class Collection < ActiveFedora::Base
        has_and_belongs_to_many :members, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, class_name: "ActiveFedora::Base", after_remove: :remove_member
        def remove_member(_m); end
      end

      class Thing < ActiveFedora::Base
        has_many :collections, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, class_name: "ActiveFedora::Base"
      end
    end

    after do
      Collection.destroy_all
      Thing.destroy_all

      Object.send(:remove_const, :Collection)
      Object.send(:remove_const, :Thing)
    end

    context "with a new collection" do
      let(:collection) { Collection.new }
      it "has an empty list of collection members" do
        expect(collection.member_ids).to eq []
        expect(collection.members).to eq []
      end
    end

    context "with a persisted collection" do
      let(:collection) { Collection.create.tap { |c| c.members << thing } }
      let(:thing) { Thing.create }

      context "when the ids are set" do
        let(:thing2) { Thing.create }
        let(:thing3) { Thing.create }

        it "clears the object set" do
          expect(collection.members).to eq [thing]
          collection.member_ids = [thing2.id, thing3.id]
          expect(collection.members).to contain_exactly thing2, thing3
        end
      end

      it "calls destroy" do
        # this is a pretty weak test
        expect { collection.destroy }.to_not raise_error
      end
    end
  end
end
