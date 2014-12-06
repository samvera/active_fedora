require 'spec_helper'

describe ActiveFedora::Indexing do
  context "internal methods" do
    before :all do
      class SpecNode
        include ActiveFedora::Indexing
      end
    end
    after :all do
      Object.send(:remove_const, :SpecNode)
    end

    subject { SpecNode.new }

    describe "#create_needs_index?" do
      subject { SpecNode.new.send(:create_needs_index?) }
      it { should be true }
    end

    describe "#update_needs_index?" do
      subject { SpecNode.new.send(:update_needs_index?) }
      it { should be true }
    end
  end

  describe "#to_solr" do
    before :all do
      class SpecNode < ActiveFedora::Base
        property :title, predicate: ::RDF::DC.title do |index|
          index.as :stored_searchable
        end
        property :abstract, predicate: ::RDF::DC.abstract, multiple: false do |index|
          index.as :stored_sortable
        end
      end
    end
    after :all do
      Object.send(:remove_const, :SpecNode)
    end

    let(:test_object) { SpecNode.new(title: ['first title'], abstract: 'The abstract') }

    subject { test_object.to_solr }

    it "should index the rdf properties" do
      expect(subject).to include('title_tesim' => ['first title'], 'abstract_ssi' => 'The abstract')
    end

    it "should add id, system_create_date, system_modified_date from object attributes" do
      expect(test_object).to receive(:create_date).and_return(DateTime.parse("2012-03-04T03:12:02Z")).twice
      expect(test_object).to receive(:modified_date).and_return(DateTime.parse("2012-03-07T03:12:02Z")).twice
      allow(test_object).to receive(:id).and_return('changeme:123')
      solr_doc = test_object.to_solr
      expect(solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("system_create", :stored_sortable, type: :date)]).to eql("2012-03-04T03:12:02Z")
      expect(solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("system_modified", :stored_sortable, type: :date)]).to eql("2012-03-07T03:12:02Z")
      expect(solr_doc[:id]).to eql("changeme:123")
    end

    it "should add self.class as the :active_fedora_model" do
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("active_fedora_model", :stored_sortable)]).to eql "SpecNode"
    end

    context "with attached files" do
      let(:mock1) { double("ds1") }
      let(:mock2) { double("ds2") }

      it "should call .to_solr on all datastreams, passing the resulting document to solr" do
        expect(mock1).to receive(:to_solr).and_return("one" => "title one")
        expect(mock2).to receive(:to_solr).and_return("two" => "title two")

        allow(test_object).to receive(:attached_files).and_return(ds1: mock1, ds2: mock2)
        expect(subject).to include('one' => 'title one', 'two' => 'title two')
      end
    end
  end

end
