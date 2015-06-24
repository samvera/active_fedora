require 'spec_helper'

describe ActiveFedora::Associations::HasAndBelongsToManyAssociation do

  context "creating the reflection" do
    before do
      class Book < ActiveFedora::Base
      end
      class Page < ActiveFedora::Base
      end
      allow_any_instance_of(Book).to receive(:load_datastreams).and_return(false)
      allow_any_instance_of(Page).to receive(:load_datastreams).and_return(false)

      allow(subject).to receive(:new_record?).and_return(false)
      allow(subject).to receive(:save).and_return(true)
    end

    after do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :Page)
    end
    subject { Book.new('subject-a') }

    context "a one way relationship " do
      describe "adding memeber" do
        it "should set the relationship attribute" do
          reflection = Book.create_reflection(:has_and_belongs_to_many, :pages, {predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection}, Book)
          allow(ActiveFedora::SolrService).to receive(:query).and_return([])
          ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, reflection)
          expect(ac).to receive(:callback).twice
          object = Page.new
          allow(object).to receive(:new_record?).and_return(false)
          allow(object).to receive(:save).and_return(true)
          allow(object).to receive(:id).and_return('1234')

          allow(subject).to receive(:[]).with('page_ids').and_return([])
          expect(subject).to receive(:[]=).with('page_ids', ['1234'])

          ac.concat object
        end
      end

      describe "finding member" do
        let(:ids) { (0..15).map(&:to_s) }
        let(:reflection) { Book.create_reflection(:has_and_belongs_to_many, :pages, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection }, Book) }
        let(:association) { ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, reflection) }
        it "calls ActiveFedora::Base.find" do
          expect(subject).to receive(:[]).with('page_ids').and_return(ids)
          expect(ActiveFedora::Base).to receive(:find).with(ids)
          association.send(:find_target)
        end
      end

      describe "solr page size option" do
        it "sends a deprecation warning" do
          expect(Deprecation).to receive(:warn)
          Book.has_and_belongs_to_many(:pages, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection, solr_page_size: 123)
        end
      end
    end

    context "with an inverse reflection" do
      let!(:inverse) { Page.create_reflection(:has_and_belongs_to_many, :books, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection }, Page) }
      let(:reflection) { Book.create_reflection(:has_and_belongs_to_many, :pages, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, inverse_of: 'books'}, Book) }
      let(:ac) { ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, reflection) }
      let(:object) { Page.new }

      it "should set the relationship attribute on subject and object when inverse_of is given" do
        allow(ActiveFedora::SolrService).to receive(:query).and_return([])
        expect(ac).to receive(:callback).twice
        allow(object).to receive(:new_record?).and_return(false)
        allow(object).to receive(:save).and_return(true)

        allow(subject).to receive(:[]).with('page_ids').and_return([])
        expect(subject).to receive(:[]=).with('page_ids', [object.id])

        expect(object).to receive(:[]).with('book_ids').and_return([]).twice
        expect(object).to receive(:[]=).with('book_ids', [subject.id])

        ac.concat object
      end
    end

  end

  context "class with association" do
    before do
      class Collection < ActiveFedora::Base
        has_and_belongs_to_many :members, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, class_name: "ActiveFedora::Base", after_remove: :remove_member
        def remove_member (m)
        end
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
      it "should have an empty list of collection members" do
        expect(collection.member_ids).to eq []
        expect(collection.members).to eq []
      end
    end

    context "with a persisted collection" do
      let(:collection) { Collection.create.tap {|c| c.members << thing} }
      let(:thing) { Thing.create }

      context "when the ids are set" do
        let(:thing2) { Thing.create }
        let(:thing3) { Thing.create }

        it "should clear the object set" do
          expect(collection.members).to eq [thing]
          collection.member_ids = [thing2.id, thing3.id]
          expect(collection.members).to eq [thing2, thing3]
        end
      end

      it "should call destroy" do
        # this is a pretty weak test
        expect { collection.destroy }.to_not raise_error
      end
    end
  end
end
