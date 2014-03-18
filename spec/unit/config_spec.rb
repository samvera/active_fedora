require 'spec_helper'

describe ActiveFedora::Config do
  describe "with a single fedora instance" do
    conf = Psych.load(File.read('spec/fixtures/rails_root/config/fedora.yml'))['test']
    subject { ActiveFedora::Config.new(conf) }
    its(:credentials) { should == {:url => 'http://testhost.com:8983/fedora', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'}}
    it { should_not be_sharded }
  end
  describe "with several fedora shards" do
    conf = Psych.load(File.read('spec/fixtures/sharded_fedora.yml'))['test']
    subject { ActiveFedora::Config.new(conf) }
    its(:credentials) { should == [{:url => 'http://127.0.0.1:8983/fedora1', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'},
                              {:url => 'http://127.0.0.1:8983/fedora2', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'},
                              {:url => 'http://127.0.0.1:8983/fedora3', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'}]}
    it { should be_sharded }
  end

end
