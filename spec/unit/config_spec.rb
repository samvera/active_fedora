require 'spec_helper'

describe ActiveFedora::Config do
  describe "with a single fedora instance" do
    before(:each) do
        yaml = YAML.load(File.read('spec/fixtures/rails_root/config/fedora.yml'))['test']
        @conf = ActiveFedora::Config.new(yaml)
    end
    it '#credentials' do
      expect(@conf.credentials).to eq({:url => 'http://testhost.com:8983/fedora', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'})
      expect(@conf).not_to be_sharded
    end
  end

  describe "with several fedora shards" do
    before(:each) do
        yaml = YAML.load(File.read('spec/fixtures/sharded_fedora.yml'))['test']
        @conf = ActiveFedora::Config.new(yaml)
    end

    it '#credentials' do
      expect(@conf.credentials).to eq([
        {:url => 'http://127.0.0.1:8983/fedora1', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'},
        {:url => 'http://127.0.0.1:8983/fedora2', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'},
        {:url => 'http://127.0.0.1:8983/fedora3', :user=> 'fedoraAdmin', :password=> 'fedoraAdmin'}
      ])
      expect(@conf).to be_sharded
    end
  end

end
