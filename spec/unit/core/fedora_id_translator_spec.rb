require 'spec_helper'

RSpec.describe ActiveFedora::Core::FedoraIdTranslator do
  describe ".call" do
    let(:result) { described_class.call(id) }
    context "when given an id" do
      let(:good_uri) { ActiveFedora.fedora.base_uri + "/banana" }
      let(:id) { "banana" }
      it "returns a fedora URI" do
        expect(result).to eq good_uri
      end

      context "with a leading slash" do
        let(:id) { "/banana" }
        it "returns a good fedora URI" do
          expect(result).to eq good_uri
        end
      end

      context "with characters that need escaping" do
        let(:good_uri) { ActiveFedora.fedora.base_uri + "/%5Bfrob%5D" }
        let(:id) { "[frob]" }
        it "returns a good fedora URI" do
          expect(result).to eq good_uri
        end
      end
    end
  end
end
