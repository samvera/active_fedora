require 'spec_helper'

describe ActiveFedora::RDF::IndexingService do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      property :created, predicate: ::RDF::Vocab::DC.created
      property :title, predicate: ::RDF::Vocab::DC.title
      property :publisher, predicate: ::RDF::Vocab::DC.publisher
      property :based_near, predicate: ::RDF::Vocab::FOAF.based_near
      property :related_url, predicate: ::RDF::Vocab::RDFS.seeAlso
      property :rights, predicate: ::RDF::Vocab::DC.rights
    end
  end

  after do
    Object.send(:remove_const, :MyDatastream)
  end

  let(:f2) do
    MyDatastream.new.tap do |obj|
      obj.created = Date.parse("2012-03-04")
      obj.title = "Of Mice and Men, The Sequel"
      obj.publisher = "Bob's Blogtastic Publishing"
      obj.based_near = ["Tacoma, WA", "Renton, WA"]
      obj.related_url = "http://example.org/blogtastic/"
      obj.rights = "Totally open, y'all"
    end
  end

  let(:index_config) do
    {}.tap do |index_config|
      index_config[:created] = ActiveFedora::Indexing::Map::IndexObject.new(:created) do |index|
        index.as :sortable, :displayable
        index.type :date
      end
      index_config[:title] = ActiveFedora::Indexing::Map::IndexObject.new(:title) do |index|
        index.as :stored_searchable, :sortable
        index.type :text
      end
      index_config[:publisher] = ActiveFedora::Indexing::Map::IndexObject.new(:publisher) do |index|
        index.as :facetable, :sortable, :stored_searchable
      end
      index_config[:based_near] = ActiveFedora::Indexing::Map::IndexObject.new(:based_near) do |index|
        index.as :facetable, :stored_searchable
        index.type :text
      end
      index_config[:related_url] = ActiveFedora::Indexing::Map::IndexObject.new(:related_url) do |index|
        index.as :stored_searchable
      end
    end
  end

  before do
    allow(MyDatastream).to receive(:index_config).and_return(index_config)
  end

  let(:indexer) { described_class.new(f2) }

  describe "#generate_solr_document" do
    subject { indexer.generate_solr_document(lambda { |key| "solr_rdf__#{key}" }) }
    it "returns the right fields" do
      expect(subject.keys).to include(ActiveFedora.index_field_mapper.solr_name("solr_rdf__related_url", type: :string),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__publisher", type: :string),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__publisher", :sortable),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__publisher", :facetable),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__created", :sortable, type: :date),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__created", :displayable),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__title", type: :string),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__title", :sortable),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__based_near", type: :string),
                                      ActiveFedora.index_field_mapper.solr_name("solr_rdf__based_near", :facetable))
    end

    it "returns the right values" do
      expect(subject[ActiveFedora.index_field_mapper.solr_name("solr_rdf__related_url", type: :string)]).to eq ["http://example.org/blogtastic/"]
      expect(subject[ActiveFedora.index_field_mapper.solr_name("solr_rdf__based_near", type: :string)]).to contain_exactly "Tacoma, WA", "Renton, WA"
      expect(subject[ActiveFedora.index_field_mapper.solr_name("solr_rdf__based_near", :facetable)]).to contain_exactly "Tacoma, WA", "Renton, WA"
      expect(subject[ActiveFedora.index_field_mapper.solr_name("solr_rdf__publisher", type: :string)]).to eq ["Bob's Blogtastic Publishing"]
      expect(subject[ActiveFedora.index_field_mapper.solr_name("solr_rdf__publisher", :sortable)]).to eq "Bob's Blogtastic Publishing"
      expect(subject[ActiveFedora.index_field_mapper.solr_name("solr_rdf__publisher", :facetable)]).to eq ["Bob's Blogtastic Publishing"]
    end
  end

  describe "#fields" do
    let(:fields) { indexer.send(:fields) }

    it "returns the right fields" do
      expect(fields.keys).to eq ["created", "title", "publisher", "based_near", "related_url"]
    end

    it "returns the right values" do
      expect(fields["related_url"].values).to eq ["http://example.org/blogtastic/"]
      expect(fields["based_near"].values).to contain_exactly "Tacoma, WA", "Renton, WA"
    end

    it "returns the right type information" do
      expect(fields["created"].type).to eq :date
    end
  end
end
