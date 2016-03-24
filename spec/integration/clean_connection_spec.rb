require 'spec_helper'

RSpec.describe ActiveFedora::CleanConnection do
  subject { ActiveFedora.fedora.clean_connection }
  describe "#get" do
    context "when given an existing resource uri" do
      let(:uri) { asset.rdf_subject }
      let(:asset) do
        ActiveFedora::Base.create do |a|
          a.resource << [a.rdf_subject, RDF::Vocab::DC.title, "test"]
        end
      end
      let(:result) { subject.get(uri) }
      it "returns a clean graph" do
        graph = result.graph
        expect(graph.statements.to_a.length).to eq 1
        expect(graph.statements.to_a.first).to contain_exactly asset.rdf_subject, RDF::Vocab::DC.title, RDF::Literal.new("test")
      end
    end
  end
end
