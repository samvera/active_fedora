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
      ActiveFedora::FileConfigurator.any_instance.expects(:reset!)
      ActiveFedora::FileConfigurator.new
    end 
  end

  describe "#config_options" do
    before do
      subject.reset!
    end
    it "should be an empty hash" do
      subject.config_options.should == {}
    end
  end

  describe "#fedora_config" do
    before do
      subject.reset!
    end
    it "should trigger configuration to load" do
      subject.fedora_config.should == {"url"=>"http://127.0.0.1:8983/fedora-test", "password"=>"fedoraAdmin", "user"=>"fedoraAdmin"}
    end 
  end
  describe "#solr_config" do
    before do
      subject.reset!
    end
    it "should trigger configuration to load" do
      subject.solr_config.should == {:url=>"http://localhost:8983/solr/test"}
    end 
  end

  describe "#reset!" do
    before { subject.reset! }
    it "should clear @fedora_config" do
      subject.instance_variable_get(:@fedora_config).should == {} 
    end
    it "should clear @solr_config" do
      subject.instance_variable_get(:@solr_config).should == {} 
    end
    it "should clear @config_options" do
      subject.instance_variable_get(:@config_options).should == {}
    end
  end

  describe "initialization methods" do
    
    describe "get_config_path(:fedora)" do
      it "should use the config_options[:config_path] if it exists" do
        subject.expects(:config_options).at_least_once.returns({:fedora_config_path => "/path/to/fedora.yml"})
        File.expects(:file?).with("/path/to/fedora.yml").returns(true)
        subject.get_config_path(:fedora).should eql("/path/to/fedora.yml")
      end

      it "should look in Rails.root/config/fedora.yml if it exists and no fedora_config_path passed in" do
        subject.expects(:config_options).at_least_once.returns({})
        stub_rails(:root => "/rails/root")
        File.expects(:file?).with("/rails/root/config/fedora.yml").returns(true)
        subject.get_config_path(:fedora).should eql("/rails/root/config/fedora.yml")
        unstub_rails
      end

      it "should look in ./config/fedora.yml if neither rails.root nor :fedora_config_path are set" do
        subject.expects(:config_options).at_least_once.returns({})
        Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
        File.expects(:file?).with("/current/working/directory/config/fedora.yml").returns(true)
        subject.get_config_path(:fedora).should eql("/current/working/directory/config/fedora.yml")
      end

      it "should return default fedora.yml that ships with active-fedora if none of the above" do
        subject.expects(:config_options).at_least_once.returns({})
        Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
        File.expects(:file?).with("/current/working/directory/config/fedora.yml").returns(false)
        File.expects(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml'))).returns(true)
        logger.expects(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml') - or set Rails.root and put fedora.yml into \#{Rails.root}/config.")
        subject.get_config_path(:fedora).should eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml')))
      end
    end

    describe "get_config_path(:solr)" do
      it "should return the solr_config_path if set in config_options hash" do
        subject.expects(:config_options).at_least_once.returns({:solr_config_path => "/path/to/solr.yml"})
        File.expects(:file?).with("/path/to/solr.yml").returns(true)
        subject.get_config_path(:solr).should eql("/path/to/solr.yml")
      end
      
      it "should return the solr.yml file in the same directory as the fedora.yml if it exists" do
        subject.expects(:path).returns("/path/to/fedora/config/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(true)
        subject.get_config_path(:solr).should eql("/path/to/fedora/config/solr.yml")
      end
      
      context "no solr.yml in same directory as fedora.yml and fedora.yml does not contain solr url" do

        before :each do
          subject.expects(:config_options).at_least_once.returns({})
          subject.expects(:path).returns("/path/to/fedora/config/fedora.yml")
          File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(false)
        end
        after :each do
          unstub_rails
        end

        it "should not raise an error if there is not a solr.yml in the same directory as the fedora.yml and the fedora.yml has a solr url defined and look in rails.root" do
          stub_rails(:root=>"/rails/root")
          File.expects(:file?).with("/rails/root/config/solr.yml").returns(true)
          subject.get_config_path(:solr).should eql("/rails/root/config/solr.yml")
        end

        it "should look in ./config/solr.yml if no rails root" do
          Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
          File.expects(:file?).with("/current/working/directory/config/solr.yml").returns(true)
          subject.get_config_path(:solr).should eql("/current/working/directory/config/solr.yml")
        end

        it "should return the default solr.yml file that ships with active-fedora if no other option is set" do
          Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
          File.expects(:file?).with("/current/working/directory/config/solr.yml").returns(false)
          File.expects(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml'))).returns(true)
          logger.expects(:warn).with("Using the default solr.yml that comes with active-fedora.  If you want to override this, pass the path to solr.yml to ActiveFedora - ie. ActiveFedora.init(:solr_config_path => '/path/to/solr.yml') - or set Rails.root and put solr.yml into \#{Rails.root}/config.")
          subject.get_config_path(:solr).should eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml')))
        end
      end

    end

    describe "load_solr_config" do
      it "should load the file specified in solr_config_path" do
        subject.expects(:get_config_path).with(:solr).returns("/path/to/solr.yml")
        subject.expects(:load_fedora_config)
        File.expects(:open).with("/path/to/solr.yml").returns("development:\n  default:\n    url: http://devsolr:8983\ntest:\n  default:\n    url: http://mysolr:8080")
        subject.load_solr_config.should == {:url=>"http://mysolr:8080"}
        subject.solr_config.should == {:url=>"http://mysolr:8080"}
      end
    end

    describe "load_configs" do
      describe "when config is not loaded" do
        before do
          subject.instance_variable_set :@config_loaded, nil
        end
        it "should load the fedora and solr configs" do
          subject.config_loaded?.should be_false
          subject.load_configs
          subject.config_loaded?.should be_true
        end
      end
      describe "when config is loaded" do
        before do
          subject.instance_variable_set :@config_loaded, true
        end
        it "should load the fedora and solr configs" do
          subject.expects(:load_config).never
          subject.config_loaded?.should be_true
          subject.load_configs
          subject.config_loaded?.should be_true
        end
      end
    end

    describe "check_fedora_path_for_solr" do
      it "should find the solr.yml file and return it if it exists" do
        subject.expects(:path).returns("/path/to/fedora/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/solr.yml").returns(true)
        subject.check_fedora_path_for_solr.should == "/path/to/fedora/solr.yml"
      end
      it "should return nil if the solr.yml file is not there" do
        subject.expects(:path).returns("/path/to/fedora/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/solr.yml").returns(false)
        subject.check_fedora_path_for_solr.should be_nil
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
      subject.should respond_to(:solr_config_path)
    end
    it "loads a config from the current working directory as a second choice" do
      Dir.stubs(:getwd).returns(@fake_rails_root)
      subject.init
      subject.get_config_path(:fedora).should eql("#{@fake_rails_root}/config/fedora.yml")
      subject.solr_config_path.should eql("#{@fake_rails_root}/config/solr.yml")
    end
    it "loads the config that ships with this gem as a last choice" do
      Dir.stubs(:getwd).returns("/fake/path")
      logger.expects(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml') - or set Rails.root and put fedora.yml into \#{Rails.root}/config.").times(3)
      subject.init
      expected_config = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config"))
      subject.get_config_path(:fedora).should eql(expected_config+'/fedora.yml')
      subject.solr_config_path.should eql(expected_config+'/solr.yml')
    end
    it "raises an error if you pass in a string" do
      lambda{ subject.init("#{@fake_rails_root}/config/fake_fedora.yml") }.should raise_exception(ArgumentError)
    end
    it "raises an error if you pass in a non-existant config file" do
      lambda{ subject.init(:fedora_config_path=>"really_fake_fedora.yml") }.should raise_exception(ActiveFedora::ConfigurationError)
    end
    
    describe "within Rails" do
      before(:all) do        
        stub_rails(:root=>File.dirname(__FILE__) + '/../fixtures/rails_root')
      end

      after(:all) do
        unstub_rails
      end
      
      it "loads a config from Rails.root as a first choice" do
        subject.init
        subject.get_config_path(:fedora).should eql("#{Rails.root}/config/fedora.yml")
        subject.solr_config_path.should eql("#{Rails.root}/config/solr.yml")
      end
      
      it "can tell what environment it is set to run in" do
        stub_rails(:env=>"development")
        subject.init
        ActiveFedora.environment.should eql("development")
      end
      
    end
  end
  
  ##########################
  
  describe ".build_predicate_config_path" do
    it "should return the path to the default config/predicate_mappings.yml if no valid path is given" do
      subject.send(:build_predicate_config_path, nil).should == default_predicate_mapping_file
    end

    it "should return the path to the default config/predicate_mappings.yml if specified config file not found" do
      File.expects(:exist?).with("/path/to/predicate_mappings.yml").returns(false)
      File.expects(:exist?).with(default_predicate_mapping_file).returns(true)
      subject.send(:build_predicate_config_path,"/path/to").should == default_predicate_mapping_file
    end

    it "should return the path to the specified config_path if it exists" do
      File.expects(:exist?).with("/path/to/predicate_mappings.yml").returns(true)
      subject.expects(:valid_predicate_mapping?).returns(true)
      subject.send(:build_predicate_config_path,"/path/to").should == "/path/to/predicate_mappings.yml"
    end    
  end

  describe ".predicate_config" do
    before do
      subject.instance_variable_set :@config_loaded, nil
    end
    it "should return the default mapping if it has not been initialized" do
      subject.predicate_config().should == YAML.load(File.read(default_predicate_mapping_file))
    end
  end

  describe ".valid_predicate_mapping" do
    it "should return true if the predicate mapping has the appropriate keys and value types" do
      subject.send(:valid_predicate_mapping?,default_predicate_mapping_file).should be_true
    end
    it "should return false if the mapping is missing the :default_namespace" do
      mock_yaml({:default_namespace0=>"my_namespace",:predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      subject.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :default_namespace is not a string" do
      mock_yaml({:default_namespace=>{:foo=>"bar"}, :predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      subject.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :predicate_mappings key is missing" do
      mock_yaml({:default_namespace=>"a string"},"/path/to/predicate_mappings.yml")
      subject.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :predicate_mappings key is not a hash" do
      mock_yaml({:default_namespace=>"a string",:predicate_mapping=>"another string"},"/path/to/predicate_mappings.yml")
      subject.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end

  end

end
