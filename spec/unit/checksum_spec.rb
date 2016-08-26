require "spec_helper"

module ActiveFedora
  describe Checksum do
    subject { described_class.new(file) }

    let(:uri) { ::RDF::URI("urn:sha1:bb3200c2ddaee4bd7b9a4dc1ad3e10ed886eaef1") }

    describe "when initialized with a file having a digest" do
      let(:file) { instance_double(ActiveFedora::File, digest: [uri]) }

      its(:uri) { is_expected.to eq(uri) }
      its(:value) { is_expected.to eq("bb3200c2ddaee4bd7b9a4dc1ad3e10ed886eaef1") }
      its(:algorithm) { is_expected.to eq("SHA1") }
    end

    describe "when initialized with a file not having a digest" do
      let(:file) { instance_double(ActiveFedora::File, digest: []) }

      its(:uri) { is_expected.to be_nil }
      its(:value) { is_expected.to be_nil }
      its(:algorithm) { is_expected.to be_nil }
    end
  end
end
