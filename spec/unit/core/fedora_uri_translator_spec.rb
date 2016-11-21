require 'spec_helper'

RSpec.describe ActiveFedora::Core::FedoraUriTranslator do
  describe ".call" do
    let(:result) { described_class.call(uri) }
    context "when given a Fedora URI" do
      let(:uri) { ActiveFedora.fedora.base_uri + "/6" }
      it "returns the id" do
        expect(result).to eq '6'
      end
    end
    context "when given a URI missing a slash" do
      let(:uri) { ActiveFedora.fedora.base_uri + "602-a" }
      it "returns the id" do
        expect(result).to eq "602-a"
      end
    end
  end
end
