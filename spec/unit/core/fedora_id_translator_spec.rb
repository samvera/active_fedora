require 'spec_helper'

RSpec.describe ActiveFedora::Core::FedoraIdTranslator do
  describe ".call" do
    let(:result) { described_class.call(id) }
    context "when given an id" do
      let(:good_uri) { ActiveFedora.fedora.host+ActiveFedora.fedora.base_path+"/banana" }
      let(:id) { "banana" }
      it "should return a fedora URI" do
        expect(result).to eq good_uri
      end
      context "when given an id with a leading slash" do
        let(:id) { "/banana" }
        it "should return a good fedora URI" do
          expect(result).to eq good_uri
        end
      end
    end
  end
end
