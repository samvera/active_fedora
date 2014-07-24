require 'spec_helper'

describe ActiveFedora::Associations::HasAndBelongsToManyAssociation do
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

  it "should set the relationship attribute" do
    subject = Book.new('subject:a')
    allow(subject).to receive(:new_record?).and_return(false)
    allow(subject).to receive(:save).and_return(true)

    predicate = Book.create_reflection(:has_and_belongs_to_many, 'pages', {property: 'predicate'}, Book)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    expect(ac).to receive(:callback).twice
    object = Page.new
    allow(object).to receive(:new_record?).and_return(false)
    allow(object).to receive(:save).and_return(true)
    allow(object).to receive(:id).and_return('1234')
  
    allow(subject).to receive(:[]).with('page_ids').and_return([])
    expect(subject).to receive(:[]=).with('page_ids', ['1234'])
 
    ac.concat object

  end

  it "should set the relationship attribute on subject and object when inverse_of is given" do
    subject = Book.new('subject:a')
    allow(subject).to receive(:new_record?).and_return(false)
    allow(subject).to receive(:save).and_return(true)

    Page.create_reflection(:has_and_belongs_to_many, 'books', {:property=>'inverse_predicate'}, Page)
    predicate = Book.create_reflection(:has_and_belongs_to_many, 'pages', {:property=>'predicate', :inverse_of => 'books'}, Book)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    expect(ac).to receive(:callback).twice
    object = Page.new('object:b')
    allow(object).to receive(:new_record?).and_return(false)
    allow(object).to receive(:save).and_return(true)
  
    allow(subject).to receive(:[]).with('page_ids').and_return([])
    expect(subject).to receive(:[]=).with('page_ids', [object.id])
 
    expect(object).to receive(:[]).with('book_ids').and_return([]).twice
    expect(object).to receive(:[]=).with('book_ids', [subject.id])
 
    ac.concat object

  end

  it "should call solr query multiple times" do

    subject = Book.new('subject:a')
    allow(subject).to receive(:new_record?).and_return(false)
    allow(subject).to receive(:save).and_return(true)
    predicate = Book.create_reflection(:has_and_belongs_to_many, 'pages', {:property=>'predicate', :solr_page_size => 10}, Book)
    ids = []
    0.upto(15) {|i| ids << i.to_s}
    query1 = ids.slice(0,10).map {|i| "_query_:\"{!raw f=id}#{i}\""}.join(" OR ")
    query2 = ids.slice(10,10).map {|i| "_query_:\"{!raw f=id}#{i}\""}.join(" OR ")
    expect(subject).to receive(:[]).with('page_ids').and_return(ids)
    expect(ActiveFedora::SolrService).to receive(:query).with(query1, {:rows=>10}).and_return([])
    expect(ActiveFedora::SolrService).to receive(:query).with(query2, {:rows=>10}).and_return([])

    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    ac.find_target
  end

  context "class with association" do
    before do
      class Collection < ActiveFedora::Base
        has_and_belongs_to_many :members, property: :has_collection_member, class_name: "ActiveFedora::Base", after_remove: :remove_member
        def remove_member (m)
        end
      end

      class Thing < ActiveFedora::Base
        has_many :collections, property: :has_collection_member, class_name: "ActiveFedora::Base"
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
      let(:collection) { Collection.create().tap {|c| c.members << thing} }
      let(:thing) { Thing.create() }

      it "should call destroy" do
        # this is a pretty weak test
        expect { collection.destroy }.to_not raise_error
      end
    end

  end

end
