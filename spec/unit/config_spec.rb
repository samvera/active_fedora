require 'spec_helper'

describe ActiveFedora::Config do
  context "with a single fedora instance" do
    let(:yaml) { Psych.load(File.read('spec/fixtures/rails_root/config/fedora.yml')) }
    let(:section) { 'test' }
    let(:conf) { described_class.new(yaml[section]) }

    describe "#credentials" do
      subject { conf.credentials }
      it { is_expected.to eq(url: 'http://testhost.com:8983/fedora', user: 'fedoraAdmin', password: 'fedoraAdmin') }
      describe "with SSL options" do
        let(:section) { 'test_ssl' }
        its([:ssl]) { is_expected.to eq(verify: false, ca_path: '/path/to/certs') }
      end
    end
  end
end
