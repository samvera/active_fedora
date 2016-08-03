require 'spec_helper'

describe ActiveFedora::LoadableFromJson::SolrBackedResource do
  before do
    class Foo < ActiveFedora::Base
      belongs_to :bar, predicate: ::RDF::Vocab::DC.extent
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
    resource.insert [nil, ::RDF::Vocab::DC.extent, RDF::URI('http://example.org/123')]
  end

  describe "#query" do
    describe "a known relationship" do
      subject(:resources) { resource.query(predicate: ::RDF::Vocab::DC.extent) }

      it "is enumerable" do
        expect(resources.map(&:object)).to eq [RDF::URI('http://example.org/123')]
      end
    end

    describe "a unknown relationship" do
      subject(:resources) { resource.query(predicate: ::RDF::Vocab::DC.accrualPeriodicity) }
      it "raises an error" do
        expect { resources }.to raise_error "Unable to find reflection for http://purl.org/dc/terms/accrualPeriodicity in Foo"
      end
    end
  end
end
