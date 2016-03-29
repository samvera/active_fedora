require 'spec_helper'

describe ActiveFedora::Fedora do
  subject { described_class.new(config) }
  describe "#authorized_connection" do
    describe "with SSL options" do
      let(:config) {
        { url: "https://example.com",
          user: "fedoraAdmin",
          password: "fedoraAdmin",
          ssl: { ca_path: '/path/to/certs' }
        }
      }
      specify {
        expect(Faraday).to receive(:new).with("https://example.com", ssl: { ca_path: '/path/to/certs' }).and_call_original
        subject.authorized_connection
      }
    end
  end
end
