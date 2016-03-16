require 'spec_helper'

describe ActiveFedora::SolrHit do
  before(:all) do
    class AudioRecord < ActiveFedora::Base
      attr_accessor :id
      def self.connection_for_id(_id)
      end
    end
  end

  subject { described_class.new "id" => "my:_ID1_", ActiveFedora::SolrQueryBuilder.solr_name("has_model", :symbol) => ["AudioRecord"] }

  describe "#reify" do
    it "uses .find to instantiate objects" do
      expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
      subject.reify
    end
  end

  describe "#id" do
    it "extracts the id from the solr hit" do
      expect(subject.id).to eq "my:_ID1_"
    end
  end

  describe "#rdf_uri" do
    it "provides an RDF URI for the solr hit" do
      expect(subject.rdf_uri).to eq ::RDF::URI.new(ActiveFedora::Base.id_to_uri("my:_ID1_"))
    end
  end

  describe "#model" do
    it "selects the appropriate model for the solr result" do
      expect(subject.model).to eq AudioRecord
    end
  end

  describe "#models" do
    it "provides all the relevant models for the solr result" do
      expect(subject.models).to match_array [AudioRecord]
    end
  end

  describe "#model?" do
    it 'is true if the object has the given model' do
      expect(subject.model?(AudioRecord)).to eq true
    end

    it 'is true if the object has an ancestor of the given model' do
      expect(subject.model?(ActiveFedora::Base)).to eq true
    end

    it 'is false if the given model is not in the ancestor tree for the models' do
      expect(subject.model?(String)).to eq false
    end
  end
end
