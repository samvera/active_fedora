require 'spec_helper'
require 'config_helper'

describe ActiveFedora::FileConfigurator do

  subject {ActiveFedora.configurator }

  after :all do
    unstub_rails
    # Restore to default fedora configs
    restore_spec_configuration
  end

  describe "#initialize" do
    it "should trigger configuration reset (to empty defaults)" do
      expect_any_instance_of(ActiveFedora::FileConfigurator).to receive(:reset!)
      ActiveFedora::FileConfigurator.new
    end
  end

  describe "#config_options" do
    before do
      subject.reset!
    end
    it "should be an empty hash" do
      expect(subject.config_options).to eq({})
    end
  end

  describe "#fedora_config" do
    before do
      subject.reset!
    end
    it "should trigger configuration to load" do
      expect(subject).to receive(:load_fedora_config)
      subject.fedora_config
    end
  end
  describe "#solr_config" do
    before do
      subject.reset!
    end
    it "should trigger configuration to load" do
      expect(subject).to receive(:load_solr_config)
      subject.solr_config
    end
  end

  describe "#reset!" do
    before { subject.reset! }
    it "should clear @fedora_config" do
      expect(subject.instance_variable_get(:@fedora_config)).to eq({})
    end
    it "should clear @solr_config" do
      expect(subject.instance_variable_get(:@solr_config)).to eq({})
    end
    it "should clear @config_options" do
      expect(subject.instance_variable_get(:@config_options)).to eq({})
    end
  end

  describe "initialization methods" do

    describe "get_config_path(:fedora)" do
      it "should use the config_options[:config_path] if it exists" do
        expect(subject).to receive(:config_options).and_return({:fedora_config_path => "/path/to/fedora.yml"})
        expect(File).to receive(:file?).with("/path/to/fedora.yml").and_return(true)
        expect(subject.get_config_path(:fedora)).to eql("/path/to/fedora.yml")
      end

      it "should look in Rails.root/config/fedora.yml if it exists and no fedora_config_path passed in" do
        expect(subject).to receive(:config_options).and_return({})
        stub_rails(:root => "/rails/root")
        expect(File).to receive(:file?).with("/rails/root/config/fedora.yml").and_return(true)
        expect(subject.get_config_path(:fedora)).to eql("/rails/root/config/fedora.yml")
        unstub_rails
      end

      it "should look in ./config/fedora.yml if neither rails.root nor :fedora_config_path are set" do
        expect(subject).to receive(:config_options).and_return({})
        allow(Dir).to receive(:getwd).and_return("/current/working/directory")
        expect(File).to receive(:file?).with("/current/working/directory/config/fedora.yml").and_return(true)
        expect(subject.get_config_path(:fedora)).to eql("/current/working/directory/config/fedora.yml")
      end

      it "should return default fedora.yml that ships with active-fedora if none of the above" do
        expect(subject).to receive(:config_options).and_return({})
        expect(Dir).to receive(:getwd).and_return("/current/working/directory")
        expect(File).to receive(:file?).with("/current/working/directory/config/fedora.yml").and_return(false)
        expect(File).to receive(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml'))).and_return(true)
        expect(ActiveFedora::Base.logger).to receive(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml') - or set Rails.root and put fedora.yml into \#{Rails.root}/config.")
        expect(subject.get_config_path(:fedora)).to eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml')))
      end
    end

    describe "get_config_path(:predicate_mappings)" do
      it "should use the config_options[:config_path] if it exists" do
        expect(subject).to receive(:config_options).and_return({:predicate_mappings_config_path => "/path/to/predicate_mappings.yml"})
        expect(File).to receive(:file?).with("/path/to/predicate_mappings.yml").and_return(true)
        expect(subject.get_config_path(:predicate_mappings)).to eql("/path/to/predicate_mappings.yml")
      end

      it "should look in Rails.root/config/predicate_mappings.yml if it exists and no predicate_mappings_config_path passed in" do
        expect(subject).to receive(:config_options).and_return({})
        stub_rails(:root => "/rails/root")
        expect(File).to receive(:file?).with("/rails/root/config/predicate_mappings.yml").and_return(true)
        expect(subject.get_config_path(:predicate_mappings)).to eql("/rails/root/config/predicate_mappings.yml")
        unstub_rails
      end

      it "should look in ./config/predicate_mappings.yml if neither rails.root nor :predicate_mappings_config_path are set" do
        expect(subject).to receive(:config_options).and_return({})
        allow(Dir).to receive(:getwd).and_return("/current/working/directory")
        expect(File).to receive(:file?).with("/current/working/directory/config/predicate_mappings.yml").and_return(true)
        expect(subject.get_config_path(:predicate_mappings)).to eql("/current/working/directory/config/predicate_mappings.yml")
      end

      it "should return default predicate_mappings.yml that ships with active-fedora if none of the above" do
        expect(subject).to receive(:config_options).and_return({})
        expect(Dir).to receive(:getwd).and_return("/current/working/directory")
        expect(File).to receive(:file?).with("/current/working/directory/config/predicate_mappings.yml").and_return(false)
        expect(File).to receive(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','predicate_mappings.yml'))).and_return(true)
        expect(ActiveFedora::Base.logger).to receive(:warn).with("Using the default predicate_mappings.yml that comes with active-fedora.  If you want to override this, pass the path to predicate_mappings.yml to ActiveFedora - ie. ActiveFedora.init(:predicate_mappings_config_path => '/path/to/predicate_mappings.yml') - or set Rails.root and put predicate_mappings.yml into \#{Rails.root}/config.")
        expect(subject.get_config_path(:predicate_mappings)).to eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','predicate_mappings.yml')))
      end
    end

    describe "get_config_path(:solr)" do
      it "should return the solr_config_path if set in config_options hash" do
        allow(subject).to receive(:config_options).and_return(:solr_config_path => "/path/to/solr.yml")
        expect(File).to receive(:file?).with("/path/to/solr.yml").and_return(true)
        expect(subject.get_config_path(:solr)).to eql("/path/to/solr.yml")
      end

      it "should return the solr.yml file in the same directory as the fedora.yml if it exists" do
        expect(subject).to receive(:path).and_return("/path/to/fedora/config/fedora.yml")
        expect(File).to receive(:file?).with("/path/to/fedora/config/solr.yml").and_return(true)
        expect(subject.get_config_path(:solr)).to eql("/path/to/fedora/config/solr.yml")
      end

      context "no solr.yml in same directory as fedora.yml and fedora.yml does not contain solr url" do

        before :each do
          allow(subject).to receive(:config_options).and_return({})
          expect(subject).to receive(:path).and_return("/path/to/fedora/config/fedora.yml")
          expect(File).to receive(:file?).with("/path/to/fedora/config/solr.yml").and_return(false)
        end
        after :each do
          unstub_rails
        end

        it "should not raise an error if there is not a solr.yml in the same directory as the fedora.yml and the fedora.yml has a solr url defined and look in rails.root" do
          stub_rails(:root=>"/rails/root")
          expect(File).to receive(:file?).with("/rails/root/config/solr.yml").and_return(true)
          expect(subject.get_config_path(:solr)).to eql("/rails/root/config/solr.yml")
        end

        it "should look in ./config/solr.yml if no rails root" do
          allow(Dir).to receive(:getwd).and_return("/current/working/directory")
          expect(File).to receive(:file?).with("/current/working/directory/config/solr.yml").and_return(true)
          expect(subject.get_config_path(:solr)).to eql("/current/working/directory/config/solr.yml")
        end

        it "should return the default solr.yml file that ships with active-fedora if no other option is set" do
          allow(Dir).to receive(:getwd).and_return("/current/working/directory")
          expect(File).to receive(:file?).with("/current/working/directory/config/solr.yml").and_return(false)
          expect(File).to receive(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml'))).and_return(true)
          expect(ActiveFedora::Base.logger).to receive(:warn).with("Using the default solr.yml that comes with active-fedora.  If you want to override this, pass the path to solr.yml to ActiveFedora - ie. ActiveFedora.init(:solr_config_path => '/path/to/solr.yml') - or set Rails.root and put solr.yml into \#{Rails.root}/config.")
          expect(subject.get_config_path(:solr)).to eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml')))
        end
      end

    end

    describe "load_fedora_config" do
      before(:each) do
        subject.reset!
      end
      it "should load the file specified in fedora_config_path" do
        allow(subject).to receive(:load_solrizer_config)
        expect(subject).to receive(:get_config_path).with(:fedora).and_return("/path/to/fedora.yml")
        expect(subject).to receive(:load_solr_config)
        expect(IO).to receive(:read).with("/path/to/fedora.yml").and_return("development:\n url: http://devfedora:8983\ntest:\n  url: http://myfedora:8080")
        expect(subject.load_fedora_config).to eq(:url=>"http://myfedora:8080")
        expect(subject.fedora_config).to eq(:url=>"http://myfedora:8080")
      end

      it "should allow sharding" do
        allow(subject).to receive(:load_solrizer_config)
        expect(subject).to receive(:get_config_path).with(:fedora).and_return("/path/to/fedora.yml")
        expect(subject).to receive(:load_solr_config)
        expect(IO).to receive(:read).with("/path/to/fedora.yml").and_return("development:\n  url: http://devfedora:8983\ntest:\n- url: http://myfedora:8080\n- url: http://myfedora:8081")
        expect(subject.load_fedora_config).to eq [{:url=>"http://myfedora:8080"}, {:url=>"http://myfedora:8081"}]
        expect(subject.fedora_config).to eq [{:url=>"http://myfedora:8080"}, {:url=>"http://myfedora:8081"}]
      end

      it "should parse the file using ERb" do
        allow(subject).to receive(:load_solrizer_config)
        expect(subject).to receive(:get_config_path).with(:fedora).and_return("/path/to/fedora.yml")
        expect(subject).to receive(:load_solr_config)
        expect(IO).to receive(:read).with("/path/to/fedora.yml").and_return("development:\n  url: http://devfedora:<%= 8983 %>\ntest:\n  url: http://myfedora:<%= 8081 %>")
        expect(subject.load_fedora_config).to eq(:url=>"http://myfedora:8081")
        expect(subject.fedora_config).to eq(:url=>"http://myfedora:8081")
      end
    end

    describe "load_solr_config" do
      before(:each) do
        subject.reset!
      end
      it "should load the file specified in solr_config_path" do
        allow(subject).to receive(:load_solrizer_config)
        expect(subject).to receive(:get_config_path).with(:solr).and_return("/path/to/solr.yml")
        expect(subject).to receive(:load_fedora_config)
        expect(IO).to receive(:read).with("/path/to/solr.yml").and_return("development:\n  default:\n    url: http://devsolr:8983\ntest:\n  default:\n    url: http://mysolr:8080")
        expect(subject.load_solr_config).to eq(:url=>"http://mysolr:8080")
        expect(subject.solr_config).to eq(:url=>"http://mysolr:8080")
      end

      it "should parse the file using ERb" do
        allow(subject).to receive(:load_solrizer_config)
        expect(subject).to receive(:get_config_path).with(:solr).and_return("/path/to/solr.yml")
        expect(subject).to receive(:load_fedora_config)
        expect(IO).to receive(:read).with("/path/to/solr.yml").and_return("development:\n  default:\n    url: http://devsolr:<%= 8983 %>\ntest:\n  default:\n    url: http://mysolr:<%= 8081 %>")
        expect(subject.load_solr_config).to eq(:url=>"http://mysolr:8081")
        expect(subject.solr_config).to eq(:url=>"http://mysolr:8081")
      end
    end

    describe "load_configs" do
      describe "when config is not loaded" do
        before do
          subject.instance_variable_set :@config_loaded, nil
        end
        it "should load the fedora and solr configs" do
          expect(subject).to_not be_config_loaded
          subject.load_configs
          expect(subject).to be_config_loaded
        end
      end
      describe "when config is loaded" do
        before do
          subject.instance_variable_set :@config_loaded, true
        end
        it "should load the fedora and solr configs" do
          expect(subject).to receive(:load_config).never
          expect(subject).to be_config_loaded
          subject.load_configs
          expect(subject).to be_config_loaded
        end
      end
    end

    describe "check_fedora_path_for_solr" do
      it "should find the solr.yml file and return it if it exists" do
        expect(subject).to receive(:path).and_return("/path/to/fedora/fedora.yml")
        expect(File).to receive(:file?).with("/path/to/fedora/solr.yml").and_return(true)
        expect(subject.check_fedora_path_for_solr).to eq "/path/to/fedora/solr.yml"
      end
      it "should return nil if the solr.yml file is not there" do
        expect(subject).to receive(:path).and_return("/path/to/fedora/fedora.yml")
        expect(File).to receive(:file?).with("/path/to/fedora/solr.yml").and_return(false)
        expect(subject.check_fedora_path_for_solr).to be_nil
      end
    end
  end

  describe "setting the environment and loading configuration" do

    before(:all) do
      @fake_rails_root = File.expand_path(File.dirname(__FILE__) + '/../fixtures/rails_root')
    end


    after(:all) do
      config_file = File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml")
      environment = "test"
      ActiveFedora.init(:environment=>environment, :fedora_config_path=>config_file)
    end

    it "can tell its config paths" do
      subject.init
      expect(subject).to respond_to(:solr_config_path)
    end

    it "loads a config from the current working directory as a second choice" do
      allow(subject).to receive(:load_solrizer_config)
      allow(Dir).to receive(:getwd).and_return(@fake_rails_root)
      subject.init
      expect(subject.get_config_path(:fedora)).to eql("#{@fake_rails_root}/config/fedora.yml")
      expect(subject.solr_config_path).to eql("#{@fake_rails_root}/config/solr.yml")
    end

    it "loads the config that ships with this gem as a last choice" do
      allow(Dir).to receive(:getwd).and_return("/fake/path")
      allow(subject).to receive(:load_solrizer_config)
      expect(ActiveFedora::Base.logger).to receive(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml') - or set Rails.root and put fedora.yml into \#{Rails.root}/config.").exactly(3).times
      subject.init
      expected_config = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config"))
      expect(subject.get_config_path(:fedora)).to eql(expected_config+'/fedora.yml')
      expect(subject.solr_config_path).to eql(expected_config+'/solr.yml')
    end
    it "raises an error if you pass in a string" do
      expect(lambda{ subject.init("#{@fake_rails_root}/config/fake_fedora.yml") }).to raise_exception(ArgumentError)
    end
    it "raises an error if you pass in a non-existant config file" do
      expect(lambda{ subject.init(:fedora_config_path=>"really_fake_fedora.yml") }).to raise_exception(ActiveFedora::ConfigurationError)
    end

    describe "within Rails" do
      before do
        stub_rails(:root=>File.dirname(__FILE__) + '/../fixtures/rails_root')
      end

      after do
        unstub_rails
      end

      it "loads a config from Rails.root as a first choice" do
        allow(subject).to receive(:load_solrizer_config)
        subject.init
        expect(subject.get_config_path(:fedora)).to eql("#{Rails.root}/config/fedora.yml")
        expect(subject.solr_config_path).to eql("#{Rails.root}/config/solr.yml")
      end

      it "can tell what environment it is set to run in" do
        stub_rails(:env=>"development")
        subject.init
        expect(ActiveFedora.environment).to eql("development")
      end

    end
  end

  ##########################

  describe ".build_predicate_config_path" do
    it "should return the path to the default config/predicate_mappings.yml if no valid path is given" do
      expect(subject.send(:build_predicate_config_path)).to eq default_predicate_mapping_file
    end
  end

  describe ".predicate_config" do
    before do
      subject.instance_variable_set :@config_loaded, nil
    end
    it "should return the default mapping if it has not been initialized" do
      expect(subject.predicate_config()).to eq Psych.load(File.read(default_predicate_mapping_file))
    end
  end

  describe ".valid_predicate_mapping" do
    it "should return true if the predicate mapping has the appropriate keys and value types" do
      expect(subject.send(:valid_predicate_mapping?, default_predicate_mapping_file)).to be true
    end
    it "should return false if the mapping is missing the :default_namespace" do
      mock_yaml({:default_namespace0=>"my_namespace", :predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      expect(subject.send(:valid_predicate_mapping?, "/path/to/predicate_mappings.yml")).to be false
    end
    it "should return false if the :default_namespace is not a string" do
      mock_yaml({:default_namespace=>{:foo=>"bar"}, :predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      expect(subject.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml")).to be false
    end
    it "should return false if the :predicate_mappings key is missing" do
      mock_yaml({:default_namespace=>"a string"},"/path/to/predicate_mappings.yml")
      expect(subject.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml")).to be false
    end
    it "should return false if the :predicate_mappings key is not a hash" do
      mock_yaml({:default_namespace=>"a string",:predicate_mapping=>"another string"},"/path/to/predicate_mappings.yml")
      expect(subject.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml")).to be false
    end

  end

end
