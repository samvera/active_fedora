require File.join( File.dirname(__FILE__), "../spec_helper" )
require 'equivalent-xml'

# For testing Module-level methods like ActiveFedora.init

describe ActiveFedora do
  
  describe "initialization methods" do
    
    describe "environment" do
      it "should use config_options[:environment] if set" do
        ActiveFedora.expects(:config_options).at_least_once.returns(:environment=>"ballyhoo")
        ActiveFedora.environment.should eql("ballyhoo")
      end

      it "should use Rails.env if no config_options and Rails.env is set" do
        stub_rails(:env => "bedbugs")
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.environment.should eql("bedbugs")
        unstub_rails
      end

      it "should use ENV['environment'] if neither config_options nor Rails.env are set" do
        ENV['environment'] = "wichita"
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.environment.should eql("wichita")
        ENV['environment']='test'
      end

      it "should use ENV['RAILS_ENV'] and log a warning if none of the above are set" do
        ENV['environment']=nil
        ENV['RAILS_ENV'] = "rails_env"
        logger.expects(:warn)
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.environment.should eql("rails_env")
        ENV['environment']='test'
      end

      it "should raise an exception if none of the above are present" do
        ENV['environment']=nil
        ENV['RAILS_ENV'] = nil
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        lambda { ActiveFedora.environment }.should raise_exception
        ENV['environment']="test"
      end
    end

    describe "get_config_path(:fedora)" do
      it "should use the config_options[:config_path] if it exists" do
        ActiveFedora.expects(:config_options).at_least_once.returns({:fedora_config_path => "/path/to/fedora.yml"})
        File.expects(:file?).with("/path/to/fedora.yml").returns(true)
        ActiveFedora.get_config_path(:fedora).should eql("/path/to/fedora.yml")
      end

      it "should look in Rails.root/config/fedora.yml if it exists and no fedora_config_path passed in" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        stub_rails(:root => "/rails/root")
        File.expects(:file?).with("/rails/root/config/fedora.yml").returns(true)
        ActiveFedora.get_config_path(:fedora).should eql("/rails/root/config/fedora.yml")
        unstub_rails
      end

      it "should look in ./config/fedora.yml if neither rails.root nor :fedora_config_path are set" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
        File.expects(:file?).with("/current/working/directory/config/fedora.yml").returns(true)
        ActiveFedora.get_config_path(:fedora).should eql("/current/working/directory/config/fedora.yml")
      end

      it "should return default fedora.yml that ships with active-fedora if none of the above" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
        File.expects(:file?).with("/current/working/directory/config/fedora.yml").returns(false)
        File.expects(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml'))).returns(true)
        ActiveFedora.get_config_path(:fedora).should eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml')))
      end
    end

    describe "get_config_path(:solr)" do
      it "should return the solr_config_path if set in config_options hash" do
        ActiveFedora.expects(:config_options).at_least_once.returns({:solr_config_path => "/path/to/solr.yml"})
        File.expects(:file?).with("/path/to/solr.yml").returns(true)
        ActiveFedora.get_config_path(:solr).should eql("/path/to/solr.yml")
      end
      
      it "should return the solr.yml file in the same directory as the fedora.yml if it exists" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.expects(:fedora_config_path).returns("/path/to/fedora/config/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(true)
        ActiveFedora.get_config_path(:solr).should eql("/path/to/fedora/config/solr.yml")
      end
      
      it "should raise an error if there is not a solr.yml in the same directory as the fedora.yml and the fedora.yml has a solr url defined" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.expects(:fedora_config_path).returns("/path/to/fedora/config/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(false)
        ActiveFedora.expects(:fedora_config).returns({"test"=>{"solr"=>{"url"=>"http://some_url"}}})
        lambda { ActiveFedora.get_config_path(:solr) }.should raise_exception
      end

      context "no solr.yml in same directory as fedora.yml and fedora.yml does not contain solr url" do

        before :each do
          ActiveFedora.expects(:config_options).at_least_once.returns({})
          ActiveFedora.expects(:fedora_config_path).returns("/path/to/fedora/config/fedora.yml")
          File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(false)
          ActiveFedora.expects(:fedora_config).returns({"test"=>{"url"=>"http://some_url"}})
        end
        after :each do
          unstub_rails
        end

        it "should not raise an error if there is not a solr.yml in the same directory as the fedora.yml and the fedora.yml has a solr url defined and look in rails.root" do
          stub_rails(:root=>"/rails/root")
          File.expects(:file?).with("/rails/root/config/solr.yml").returns(true)
          ActiveFedora.get_config_path(:solr).should eql("/rails/root/config/solr.yml")
        end

        it "should look in ./config/solr.yml if no rails root" do
          Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
          File.expects(:file?).with("/current/working/directory/config/solr.yml").returns(true)
          ActiveFedora.get_config_path(:solr).should eql("/current/working/directory/config/solr.yml")
        end

        it "should return the default solr.yml file that ships with active-fedora if no other option is set" do
          Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
          File.expects(:file?).with("/current/working/directory/config/solr.yml").returns(false)
          File.expects(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml'))).returns(true)
          ActiveFedora.get_config_path(:solr).should eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml')))
        end
      end

    end


    describe "#determine url" do
      it "should support config['environment']['fedora']['url'] if config_type is fedora" do
        config = {"test"=> {"fedora"=>{"url"=>"http://fedoraAdmin:fedorAdmin@oldstyle_url:8983/fedora"}}}
        ActiveFedora.determine_url("fedora",config).should eql("http://fedoraAdmin:fedorAdmin@oldstyle_url:8983/fedora")
      end

      it "should support config['environment']['url'] if config_type is fedora" do
        config = {"test"=> {"url"=>"http://fedoraAdmin:fedorAdmin@oldstyle_url:8983/fedora"}}
        ActiveFedora.determine_url("fedora",config).should eql("http://fedoraAdmin:fedorAdmin@oldstyle_url:8983/fedora")
      end

      it "should call #get_solr_url to determine the solr url if config_type is solr" do
        config = {"test"=>{"default" => "http://default.solr:8983"}}
        ActiveFedora.expects(:get_solr_url).with(config["test"]).returns("http://default.solr:8983")
        ActiveFedora.determine_url("solr",config).should eql("http://default.solr:8983")
      end
    end

    describe "load_config" do
      it "should load the file specified in fedora_config_path" do
        ActiveFedora.expects(:fedora_config_path).returns("/path/to/fedora.yml")
        File.expects(:open).with("/path/to/fedora.yml").returns("test:\n  url: http://myfedora:8080")
        ActiveFedora.load_config(:fedora).should eql({:url=>"http://myfedora:8080","test"=>{"url"=>"http://myfedora:8080"}})
        ActiveFedora.fedora_config.should eql({:url=>"http://myfedora:8080","test"=>{"url"=>"http://myfedora:8080"}})
      end
      it "should load the file specified in solr_config_path" do
        ActiveFedora.expects(:solr_config_path).returns("/path/to/solr.yml")
        File.expects(:open).with("/path/to/solr.yml").returns("development:\n  default:\n    url: http://devsolr:8983\ntest:\n  default:\n    url: http://mysolr:8080")
        ActiveFedora.load_config(:solr).should eql({:url=>"http://mysolr:8080","development"=>{"default"=>{"url"=>"http://devsolr:8983"}}, "test"=>{"default"=>{"url"=>"http://mysolr:8080"}}})
        ActiveFedora.solr_config.should eql({:url=>"http://mysolr:8080","development"=>{"default"=>{"url"=>"http://devsolr:8983"}}, "test"=>{"default"=>{"url"=>"http://mysolr:8080"}}})
      end
    end

    describe "load_configs" do
      it "should load the fedora and solr configs" do
        ActiveFedora.expects(:load_config).with(:fedora)
        ActiveFedora.expects(:load_config).with(:solr)
        ActiveFedora.load_configs
      end
    end

    describe "register_solr_and_fedora" do
      it "should regiser instances with the appropriate urls" do
        ActiveFedora.expects(:solr_config).at_least_once.returns({:url=>"http://megasolr:8983"})
        ActiveFedora.expects(:fedora_config).at_least_once.returns({:url=>"http://megafedora:8983"})
        ActiveFedora.register_fedora_and_solr
        ActiveFedora.solr.conn.url.to_s.should eql("http://megasolr:8983")
        ActiveFedora.fedora.fedora_url.to_s.should eql("http://megafedora:8983")
      end
    end

    describe "check_fedora_path_for_solr" do
      it "should find the solr.yml file and return it if it exists" do
        ActiveFedora.expects(:fedora_config_path).returns("/path/to/fedora/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/solr.yml").returns(true)
        ActiveFedora.check_fedora_path_for_solr.should == "/path/to/fedora/solr.yml"
      end
      it "should return nil if the solr.yml file is not there" do
        ActiveFedora.expects(:fedora_config_path).returns("/path/to/fedora/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/solr.yml").returns(false)
        ActiveFedora.check_fedora_path_for_solr.should be_nil
      end
    end
  end



  ###########################
  
  describe "setting the environment and loading configuration" do
    
    before(:all) do
      @fake_rails_root = File.expand_path(File.dirname(__FILE__) + '/../fixtures/rails_root')
    end
    
    after(:all) do
      ActiveFedora.init(File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml"))
    end
  
    it "can tell its config paths" do
      ActiveFedora.init
      ActiveFedora.should respond_to(:fedora_config_path)
      ActiveFedora.should respond_to(:solr_config_path)
    end
    it "loads a config from the current working directory as a second choice" do
      Dir.stubs(:getwd).returns(@fake_rails_root)
      ActiveFedora.init
      ActiveFedora.fedora_config_path.should eql("#{@fake_rails_root}/config/fedora.yml")
      ActiveFedora.solr_config_path.should eql("#{@fake_rails_root}/config/solr.yml")
    end
    it "loads the config that ships with this gem as a last choice" do
      Dir.stubs(:getwd).returns("/fake/path")
      ActiveFedora.init
      expected_config = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config"))
      ActiveFedora.fedora_config_path.should eql(expected_config+'/fedora.yml')
      ActiveFedora.solr_config_path.should eql(expected_config+'/solr.yml')
    end
    it "overrides any other config file when a file is passed in explicitly" do
      ActiveFedora.init("#{@fake_rails_root}/config/fake_fedora.yml")
      ActiveFedora.fedora_config_path.should eql("#{@fake_rails_root}/config/fake_fedora.yml")
#ActiveFedora.config_path.should eql("#{@fake_rails_root}/config/fake_fedora.yml")
    end
    it "raises an error if you pass in a non-existant config file" do
      lambda{ ActiveFedora.init("really_fake_fedora.yml") }.should raise_exception(ActiveFedoraConfigurationException)
    end
    
    describe "within Rails" do
      before(:all) do        
        stub_rails(:root=>File.dirname(__FILE__) + '/../fixtures/rails_root')
      end

      after(:all) do
        unstub_rails
      end
      
      it "loads a config from Rails.root as a first choice" do
        ActiveFedora.init
        ActiveFedora.fedora_config_path.should eql("#{Rails.root}/config/fedora.yml")
        ActiveFedora.solr_config_path.should eql("#{Rails.root}/config/solr.yml")
      end
      
      it "can tell what environment it is set to run in" do
        stub_rails(:env=>"development")
        ActiveFedora.init
        ActiveFedora.environment.should eql("development")
      end
      
    end
  end
  
  ##########################
  
  describe ".push_models_to_fedora" do
    it "should push the model definition for each of the ActiveFedora models into Fedora CModel objects" do
      pending
      # find all of the models 
      # create a cmodel for each model with the appropriate pid
      # push the model definition into the cmodel's datastream (ie. dsname: oral_history.rb vs dsname: ruby)
    end
  end

  describe ".build_predicate_config_path" do
    it "should return the path to the default config/predicate_mappings.yml if no valid path is given" do
      ActiveFedora.send(:build_predicate_config_path, nil).should == default_predicate_mapping_file
    end

    it "should return the path to the default config/predicate_mappings.yml if specified config file not found" do
      File.expects(:exist?).with("/path/to/predicate_mappings.yml").returns(false)
      File.expects(:exist?).with(default_predicate_mapping_file).returns(true)
      ActiveFedora.send(:build_predicate_config_path,"/path/to").should == default_predicate_mapping_file
    end

    it "should return the path to the specified config_path if it exists" do
      File.expects(:exist?).with("/path/to/predicate_mappings.yml").returns(true)
      ActiveFedora.expects(:valid_predicate_mapping?).returns(true)
      ActiveFedora.send(:build_predicate_config_path,"/path/to").should == "/path/to/predicate_mappings.yml"
    end    
  end

  describe ".predicate_config" do
    it "should return the default mapping if it has not been initialized" do
      ActiveFedora.instance_variable_set("@predicate_config_path",nil)
      ActiveFedora.predicate_config().should == default_predicate_mapping_file
    end
    it "should return the path that was set at initialization" do
      pending()
      File.expects(:exist?).with("/path/to/my/files/predicate_mappings.yml").returns(true)
      mock_file = mock("fedora.yml")
      File.expects(:open).returns(mock_file)
      YAML.expects(:load).returns({"test"=>{"solr"=>{"url"=>"http://127.0.0.1:8983/solr/development"}, "fedora"=>{"url"=>"http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"}}})
      ActiveFedora.init("/path/to/my/files/fedora.yml")
      ActiveFedora.predicate_config.should == "/path/to/my/files/predicate_mappings.yml"
    end
  end

  describe ".valid_predicate_mapping" do
    it "should return true if the predicate mapping has the appropriate keys and value types" do
      ActiveFedora.send(:valid_predicate_mapping?,default_predicate_mapping_file).should be_true
    end
    it "should return false if the mapping is missing the :default_namespace" do
      mock_yaml({:default_namespace0=>"my_namespace",:predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :default_namespace is not a string" do
      mock_yaml({:default_namespace=>{:foo=>"bar"}, :predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :predicate_mappings key is missing" do
      mock_yaml({:default_namespace=>"a string"},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :predicate_mappings key is not a hash" do
      mock_yaml({:default_namespace=>"a string",:predicate_mapping=>"another string"},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end

  end

  describe ".init" do
    
    after(:all) do
      # Restore to default fedora configs
      ActiveFedora.init(File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml"))

    end

    describe "outside of rails" do
      it "should load the default packaged config/fedora.yml file if no explicit config path is passed" do
        ActiveFedora.init()
        ActiveFedora.fedora.fedora_url.to_s.should == "http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
      end
      it "should load the passed config if explicit config passed in" do
        ActiveFedora.init('./spec/fixtures/rails_root/config/fedora.yml')
        ActiveFedora.fedora.fedora_url.to_s.should == "http://fedoraAdmin:fedoraAdmin@testhost.com:8983/fedora"
      end
    end

    describe "within rails" do

      after(:all) do
        unstub_rails
      end

      describe "versions prior to 3.0" do
        describe "with explicit config path passed in" do
          it "should load the specified config path" do
            fedora_config="test:\n  fedora:\n    url: http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
            solr_config = "test:\n  default:\n    url: http://foosolr:8983"

            fedora_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/fedora.yml"))
            solr_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/solr.yml"))
            pred_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/predicate_mappings.yml"))
            
            File.stubs(:open).with(fedora_config_path).returns(fedora_config)
            File.stubs(:open).with(solr_config_path).returns(solr_config)

            ActiveFedora.expects(:build_predicate_config_path)

            ActiveFedora.init(:fedora_config_path=>fedora_config_path,:solr_config_path=>solr_config_path)
            ActiveFedora.solr.class.should == ActiveFedora::SolrService
            ActiveFedora.fedora.class.should == Fedora::Repository
          end
        end

        describe "with no explicit config path" do
          it "should look for the file in the path defined at Rails.root" do
            stub_rails(:root=>File.join(File.dirname(__FILE__),"../fixtures/rails_root"))
            ActiveFedora.init()
            ActiveFedora.solr.class.should == ActiveFedora::SolrService
            ActiveFedora.fedora.class.should == Fedora::Repository
            ActiveFedora.fedora.fedora_url.to_s.should == "http://fedoraAdmin:fedoraAdmin@testhost.com:8983/fedora"
          end
          it "should load the default file if no config is found at Rails.root" do
            stub_rails(:root=>File.join(File.dirname(__FILE__),"../fixtures/bad/path/to/rails_root"))
            ActiveFedora.init()
            ActiveFedora.solr.class.should == ActiveFedora::SolrService
            ActiveFedora.fedora.class.should == Fedora::Repository
            ActiveFedora.fedora.fedora_url.to_s.should == "http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
          end
        end
      end
    end
  end
end

def mock_yaml(hash, path)
  mock_file = mock(path.split("/")[-1])
  File.stubs(:exist?).with(path).returns(true)
  File.expects(:open).with(path).returns(mock_file)
  YAML.expects(:load).returns(hash)
end

def default_predicate_mapping_file
  File.expand_path(File.join(File.dirname(__FILE__),"..","..","config","predicate_mappings.yml"))
end

def stub_rails(opts={})
  Object.const_set("Rails",Class)
  Rails.send(:undef_method,:env) if Rails.respond_to?(:env)
  Rails.send(:undef_method,:root) if Rails.respond_to?(:root)
  opts.each { |k,v| Rails.send(:define_method,k){ return v } }
end

def unstub_rails
  Object.send(:remove_const,:Rails) if defined?(Rails)
end
    
def stub_blacklight(opts={})
  Object.const_set("Blacklight",Class)
  Blacklight.send(:undef_method,:solr_config) if Blacklight.respond_to?(:solr_config)
  if opts[:solr_config]
    Blacklight.send(:define_method,:solr_config) do
      opts[:solr_config]
    end
  end
end

def unstub_blacklight
  Object.send(:remove_const,:Blacklight) if defined?(Blacklight)
end

def setup_pretest_env
  ENV['RAILS_ENV']='test'
  ENV['environment']='test'
end
