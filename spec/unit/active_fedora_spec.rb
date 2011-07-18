require File.join( File.dirname(__FILE__), "../spec_helper" )

# For testing Module-level methods like ActiveFedora.init

describe ActiveFedora do
  
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

      before(:all) do
        Object.const_set("Rails",String)
      end

      after(:all) do
        if Rails == String
          Object.send(:remove_const,:Rails)
        end
      end

      describe "versions prior to 3.0" do
        describe "with explicit config path passed in" do
          it "should load the specified config path" do
            config_hash={"test"=>{"fedora"=>{"url"=>"http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"},"solr"=>{"url"=>"http://127.0.0.1:8983/solr/test/"}}}
            config_path = File.expand_path(File.join(File.dirname(__FILE__),"config"))
            mock_yaml(config_hash,File.join(config_path,"fedora.yml"))
            File.expects(:exist?).with(File.join(config_path,"predicate_mappings.yml")).returns(true)
            ActiveFedora.expects(:valid_predicate_mapping?).returns(true)
            ActiveFedora.init(File.join(config_path,"fedora.yml"))
            ActiveFedora.solr.class.should == ActiveFedora::SolrService
            ActiveFedora.fedora.class.should == Fedora::Repository
          end
        end

        describe "with no explicit config path" do
          it "should look for the file in the path defined at Rails.root" do
            Rails.expects(:root).returns(File.join(File.dirname(__FILE__),"../fixtures/rails_root"))
            ActiveFedora.init()
            ActiveFedora.solr.class.should == ActiveFedora::SolrService
            ActiveFedora.fedora.class.should == Fedora::Repository
            ActiveFedora.fedora.fedora_url.to_s.should == "http://fedoraAdmin:fedoraAdmin@testhost.com:8983/fedora"
          end
          it "should load the default file if no config is found at Rails.root" do
            Rails.expects(:root).returns(File.join(File.dirname(__FILE__),"../fixtures/bad/path/to/rails_root"))
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
