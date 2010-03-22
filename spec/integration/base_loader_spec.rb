require File.join( File.dirname(__FILE__), "..", "spec_helper" )
require 'active_fedora'
require 'active_fedora/base'
require 'active_fedora/metadata_datastream'
require 'ruby-debug'

# Load Sample OralHistory Model
require File.join( File.dirname(__FILE__), "..","samples","oral_history_sample_model" )


describe ActiveFedora::Base do
  
  before(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end

  before(:each) do
    @test_object = OralHistorySampleModel.new
    @test_object.save
  end
  
  after(:each) do
    @test_object.delete
  end
  
  describe "deserialize" do
    it "should return an object whose inner_object is not marked as new.  The datastreams should only be marked new if the model expects a datastream that doesn't exist yet in fedora" do
      #mocko = mock("object")
      #ActiveFedora::Base.expects(:new).returns(mocko)
      @test_object.datastreams["sensitive_passages"].delete
      doc = REXML::Document.new(@test_object.inner_object.object_xml, :ignore_whitespace_nodes=>:all)
      result = OralHistorySampleModel.deserialize(doc)
      result.new_object?.should be_false
      result.datastreams_in_memory.should have_key("dublin_core")
      result.datastreams_in_memory.should have_key("properties")
      result.datastreams_in_memory.each do |name,ds|
        ds.new_object?.should be_false unless name == "sensitive_passages"
      end
      result.datastreams_in_memory["sensitive_passages"].new_object?.should be_true
    end
  end
  describe "load_instance" do
    it "should retain all datastream attributes pulled from fedora" do
      # raw_object = Fedora::Repository.instance.find_objects("pid=#{@test_object.pid}").first
      raw_object = ActiveFedora::Base.new(:pid=>@test_object.pid, :new_object=>false)
      loaded = OralHistorySampleModel.load_instance(@test_object.pid)
      raw_datastreams = raw_object.datastreams
      loaded_datastreams = loaded.datastreams
      raw_datastreams.each_pair do |k,v|
        v.attributes.each_pair do |attr_name, attr_value|
          loaded_datastreams[k].attributes.should have_key(attr_name)
          loaded_datastreams[k].attributes[attr_name].should == attr_value
        end
      end
    end
  end

end