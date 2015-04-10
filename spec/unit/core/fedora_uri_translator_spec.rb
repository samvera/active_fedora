require 'spec_helper'

RSpec.describe ActiveFedora::Core::FedoraUriTranslator do
  describe ".call" do
    let(:result) { described_class.call(uri) }
    context "when given a Fedora URI" do
      let(:uri) { ActiveFedora.fedora.host + ActiveFedora.fedora.base_path+"/6" }
      it "should return the id" do
        expect(result).to eq '6'
      end
    end
    context "when given a URI missing a slash" do
      let(:uri) { ActiveFedora.fedora.host + ActiveFedora.fedora.base_path+"602-a" }
      it "should return the id" do
        expect(result).to eq "602-a"
      end
    end
  end
end
