require 'spec_helper'

describe ActiveFedora::RDF::IndexingService do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      Deprecation.silence(ActiveFedora::RDFDatastream) do
        property :created, predicate: ::RDF::DC.created do |index|
          index.as :sortable, :displayable
          index.type :date
        end
        property :title, predicate: ::RDF::DC.title do |index|
          index.as :stored_searchable, :sortable
          index.type :text
        end
        property :publisher, predicate: ::RDF::DC.publisher do |index|
          index.as :facetable, :sortable, :stored_searchable
        end
        property :based_near, predicate: ::RDF::FOAF.based_near do |index|
          index.as :facetable, :stored_searchable
          index.type :text
        end
        property :related_url, predicate: ::RDF::RDFS.seeAlso do |index|
          index.as :stored_searchable
        end
      end
      property :rights, predicate: ::RDF::DC.rights
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

  let(:indexer) { described_class.new(f2) }

  describe "#generate_solr_document" do
    subject { indexer.generate_solr_document(lambda { |key| "solr_rdf__#{key}" }) }
    it "should return the right fields" do
      expect(subject.keys).to include(ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__related_url", type: :string),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__publisher", type: :string),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__publisher", :sortable),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__publisher", :facetable),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__created", :sortable, type: :date),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__created", :displayable),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__title", type: :string),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__title", :sortable),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__based_near", type: :string),
            ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__based_near", :facetable))

    end

    it "should return the right values" do
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__related_url", type: :string)]).to eq ["http://example.org/blogtastic/"]
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__based_near", type: :string)]).to eq ["Tacoma, WA","Renton, WA"]
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__based_near", :facetable)]).to eq ["Tacoma, WA","Renton, WA"]
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__publisher", type: :string)]).to eq ["Bob's Blogtastic Publishing"]
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__publisher", :sortable)]).to eq "Bob's Blogtastic Publishing"
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("solr_rdf__publisher", :facetable)]).to eq ["Bob's Blogtastic Publishing"]
    end
  end

  describe "#fields" do
    let(:fields) { indexer.send(:fields) }

    it "should return the right fields" do
      expect(fields.keys).to eq ["created", "title", "publisher", "based_near", "related_url"]
    end

    it "should return the right values" do
      expect(fields["related_url"].values).to eq ["http://example.org/blogtastic/"]
      expect(fields["based_near"].values).to eq ["Tacoma, WA", "Renton, WA"]
    end

    it "should return the right type information" do
      expect(fields["created"].type).to eq :date
    end
  end

end
