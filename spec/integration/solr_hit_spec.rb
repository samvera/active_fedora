require 'spec_helper'

describe ActiveFedora::SolrHit do
  before do
    class Foo < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title, multiple: false
    end
  end

  after do
    Object.send(:remove_const, :Foo)
  end

  subject(:solr_hit) { described_class.new(doc) }
  let(:another) { Foo.create }

  let!(:obj) { Foo.create!(
    id: 'test-123',
    title: 'My Title'
  ) }

  let(:doc) { obj.to_solr }

  describe "#reify" do
    let(:solr_reified) { solr_hit.reify }

    it "finds the document in solr" do
      expect(solr_reified).to be_instance_of Foo
      expect(solr_reified.title).to eq 'My Title'
    end
  end
end
