require 'spec_helper'

describe ActiveFedora::Config do
  context "with a single fedora instance" do
    let(:yaml) { Psych.load(File.read('spec/fixtures/rails_root/config/fedora.yml'))['test'] }
    let(:conf) { ActiveFedora::Config.new(yaml) }

    describe "#credentials" do
      subject { conf.credentials }
      it { should eq(url: 'http://testhost.com:8983/fedora', user: 'fedoraAdmin', password: 'fedoraAdmin') }
    end

  end
end
