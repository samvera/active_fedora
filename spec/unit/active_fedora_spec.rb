require 'spec_helper'
require 'config_helper'

# For testing Module-level methods like ActiveFedora.init

describe ActiveFedora do
  
  before(:each) do
    restore_spec_configuration
  end
  after :all do
    unstub_rails
    # Restore to default fedora configs
    restore_spec_configuration
  end

  describe "initialization methods" do
    describe "environment" do
      it "should use config_options[:environment] if set" do
        allow(ActiveFedora).to receive(:config_options).and_return(:environment=>"ballyhoo")
        expect(ActiveFedora.environment).to eql("ballyhoo")
      end

      it "should use Rails.env if no config_options and Rails.env is set" do
        stub_rails(:env => "bedbugs")
        allow(ActiveFedora).to receive(:config_options).and_return({})
        expect(ActiveFedora.environment).to eql("bedbugs")
        unstub_rails
      end

      it "should use ENV['environment'] if neither config_options nor Rails.env are set" do
        ENV['environment'] = "wichita"
        allow(ActiveFedora).to receive(:config_options).and_return({})
        expect(ActiveFedora.environment).to eql("wichita")
        ENV['environment']='test'
      end

      it "should use ENV['RAILS_ENV'] and log a warning if none of the above are set" do
        ENV['environment']=nil
        ENV['RAILS_ENV'] = "rails_env"
        expect{ ActiveFedora.environment }.to raise_error(RuntimeError, "You're depending on RAILS_ENV for setting your environment. Please use ENV['environment'] for non-rails environment setting: 'rake foo:bar environment=test'")
        ENV['environment']='test'
      end

      it "should be development if none of the above are present" do
        ENV['environment']=nil
        ENV['RAILS_ENV'] = nil
        allow(ActiveFedora).to receive(:config_options).and_return({})
        expect(ActiveFedora.environment).to eq 'development'
        ENV['environment']="test"
      end
    end
  end
  
  describe ".init" do
    
    after(:each) do
      # Restore to default fedora configs
      ActiveFedora.init(:environment => "test", :fedora_config_path => File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml"))
    end

    describe "outside of rails" do
       it "should load the passed config if explicit config passed in as a string" do
        ActiveFedora.init(:fedora_config_path=>'./spec/fixtures/rails_root/config/fedora.yml', :environment => 'test')
        expect(ActiveFedora.config.credentials).to eq(url: "http://testhost.com:8983/fedora", :user=>'fedoraAdmin', :password=>'fedoraAdmin')
      end
    end

    describe "within rails" do

      after(:each) do
        unstub_rails
      end

      describe "versions prior to 3.0" do
        describe "with explicit config path passed in" do
          it "should load the specified config path" do
            fedora_config="test:\n  url: http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
            solr_config = "test:\n  default:\n    url: http://foosolr:8983"

            fedora_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/fedora.yml"))
            solr_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/solr.yml"))
            pred_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/predicate_mappings.yml"))

            allow(File).to receive(:open).with(fedora_config_path).and_return(fedora_config)
            allow(File).to receive(:open).with(solr_config_path).and_return(solr_config)
            allow(ActiveFedora::SolrService).to receive(:load_mappings) #For the solrizer solr_mappings.yml

            ActiveFedora.init(:fedora_config_path=>fedora_config_path,:solr_config_path=>solr_config_path)
            expect(ActiveFedora.solr.class).to eq ActiveFedora::SolrService
          end
        end

        describe "with no explicit config path" do
          it "should look for the file in the path defined at Rails.root" do
            allow(ActiveFedora::SolrService).to receive(:load_mappings) #necessary or else it will load the solrizer config and it breaks other tests in the suite.
            
            stub_rails(:root=>File.join(File.dirname(__FILE__),"../fixtures/rails_root"))
            ActiveFedora.init()
            expect(ActiveFedora.config.credentials[:url]).to eq "http://testhost.com:8983/fedora"
          end
        end
      end
    end
  end
  
  describe "#class_from_string" do
    before do
      module ParentClass
        class SiblingClass
        end
        class OtherSiblingClass
        end
      end
    end
    it "should return class constants based on strings" do
      expect(ActiveFedora.class_from_string("Om")).to eq Om
      expect(ActiveFedora.class_from_string("ActiveFedora::Rdf::Indexing")).to eq ActiveFedora::Rdf::Indexing
      expect(ActiveFedora.class_from_string("Indexing", ActiveFedora::Rdf)).to eq ActiveFedora::Rdf::Indexing
    end

    it "should find sibling classes" do
      expect(ActiveFedora.class_from_string("SiblingClass", ParentClass::OtherSiblingClass)).to eq ParentClass::SiblingClass
    end

    it "should raise a NameError if the class isn't found" do
      expect {
        ActiveFedora.class_from_string("FooClass", ParentClass::OtherSiblingClass)
      }.to raise_error NameError, "uninitialized constant FooClass"
    end
  end
end
