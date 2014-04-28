require 'spec_helper'

describe ActiveFedora::Config do
  describe "with a single fedora instance" do
    conf = Psych.load(File.read('spec/fixtures/rails_root/config/fedora.yml'))['test']
    subject { ActiveFedora::Config.new(conf) }
    its(:credentials) { should == {:url => 'http://testhost.com:8983/fedora', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'}}
  end
end
