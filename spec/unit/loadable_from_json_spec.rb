require 'spec_helper'

describe ActiveFedora::LoadableFromJson::SolrBackedResource do
  before do
    class Foo < ActiveFedora::Base
      belongs_to :bar, predicate: ::RDF::DC.extent
    end

    class Bar < ActiveFedora::Base
    end
  end

  after do
    Object.send(:remove_const, :Foo)
    Object.send(:remove_const, :Bar)
  end

  let(:resource) { described_class.new(Foo) }

  before do
    resource.insert [nil, ::RDF::DC.extent, RDF::URI('http://example.org/123')]
  end

  describe "#query" do
    subject { resource.query(predicate: ::RDF::DC.extent) }

    it "is enumerable" do
      expect(subject.map { |g| g.object }).to eq [RDF::URI('http://example.org/123')]
    end
  end
end
