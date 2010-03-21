require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'active_fedora/model'
require "rexml/document"
require 'ftools'
require 'mocha'


describe ActiveFedora::Model do
  
  before(:all) do
    module SpecModel
      class Basic
        include ActiveFedora::Model
      end
    end
    @test_property = ActiveFedora::Property.new("foo_model","test_property", :text)
  end
  
  before(:each) do 
    Fedora::Repository.instance.stubs(:nextid).returns('_nextid_')
    @test_instance = SpecModel::Basic.new
    @property = stub("myproperty", :name => "mock_prop", :instance_variable_name => "@mock_prop")
    SpecModel::Basic.extend(ActiveFedora::Model)
    SpecModel::Basic.create_property_getter(@property)
    @obj = SpecModel::Basic.new
  end
  
  after(:all) do
    #Object.send(:remove_const, :SpecModel)
  end
  
  it 'should provide #attribute_set and #attribute_get' do
    SpecModel::Basic.should respond_to(:attribute_set)
    SpecModel::Basic.should respond_to(:attribute_get) 
  end
  
  describe "#attribute_set" do
    it "should look up the property's ivar name from properties hash" do
      pending
      SpecModel::Basic.expects(:properties).with(@test_property.name)
      SpecModel::Basic.expects(:set_instance_variable).with(@test_property.instance_variable_name, "new value")
      SpecModel::Basic.attribute_set(@test_property.name, "new value")
    end
  end
  
  describe "#attribute_get" do
    it "should look up the property's ivar name from properties hash" do
      pending
      SpecModel::Basic.expects(:properties).with(@test_property.name)
      SpecModel::Basic.expects(:get_instance_variable).with(@test_property.instance_variable_name)
      SpecModel::Basic.attribute_get(@test_property.name, "new value")
    end
  end
  
  it 'should provide #create_property_getter' do
    SpecModel::Basic.should respond_to(:create_property_getter)
  end
  
  describe '#create_property_getter' do
    it 'should add getter to the model' do
      @obj.should respond_to(@property.name)
    end
    
    it 'should use attribute_get in custom getter method' do
      @obj.expects(:attribute_get).with(@property.name)
      @obj.send @property.name
    end
    
  end
  
  it 'should provide #create_property_setter' do
    SpecModel::Basic.should respond_to(:create_property_setter)
  end
  
  describe '#create_property_setter' do
    
    before(:each) do
      @property = stub("myproperty", :name => "mock_prop", :instance_variable_name => "@mock_prop")
      SpecModel::Basic.create_property_setter(@property)
      @obj = SpecModel::Basic.new
    end
    
    it 'should add setter to the model' do
      @obj.should respond_to("#{@property.name}=")
    end
    
    it 'should use attribute_set in custom setter method' do
      @obj.expects(:attribute_set).with(@property.name, "sample value")
      @obj.send "#{@property.name}=", "sample value" 
    end
      
  end
  
  it 'should provide #find' do
    SpecModel::Basic.should respond_to(:find)
  end
  
  describe '#find' do
    
    it "(:all) should query solr for all objects with :active_fedora_model_s of self.class" do
      mock_solr = mock("SolrConnection")
      mock_result = mock("MockResult")
      mock_result.expects(:hits).returns([{"id" => "changeme:30"}, {"id" => "changeme:22"}])
      mock_solr.expects(:query).with('active_fedora_model_s:SpecModel\:\:Basic').returns(mock_result)
      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock_solr))
      Fedora::Repository.instance.expects(:find_model).with("changeme:30", SpecModel::Basic).returns("Fake Object")
      Fedora::Repository.instance.expects(:find_model).with("changeme:22", SpecModel::Basic).returns("Fake Object")
      SpecModel::Basic.find(:all)
    end
    
    it "(String) should query solr for an object with the given id and return that object" do
      mock_solr = mock("SolrConnection")
      mock_result = mock("MockResult")
      mock_result.expects(:hits).returns([{"id" => "changeme:30"}])
      mock_solr.expects(:query).with('id:changeme\:30').returns(mock_result)
      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock_solr))
      Fedora::Repository.instance.expects(:find_model).with("changeme:30", SpecModel::Basic).returns("Fake Object")
    
      SpecModel::Basic.find("changeme:30").should == "Fake Object"
    end
    
    it 'should not call #new' do
      mock_solr = mock("SolrConnection")
      mock_result = mock("MockResult")
      mock_result.expects(:hits).returns([{"id" => "changeme:30"}])
      mock_solr.expects(:query).with('id:changeme\:30').returns(mock_result)
      Fedora::Repository.instance.expects(:find_model).with("changeme:30", SpecModel::Basic).returns("fake object")

      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock_solr))
    
      res = SpecModel::Basic.find("changeme:30")
    end
    
    describe"(:pid => xxx)" do 
      it "should pull the inner object from fedora if it already exists in fedora" do
        pending
        Fedora::Repository.instance.expects(:save).never
        mock_obj = mock("Fedora Object")
        Fedora::Repository.instance.expects(:find_objects).returns([mock_obj])
        ActiveFedora::Base.new(:pid=>"test:1").inner_object.should equal(mock_obj)
      end
      it "should save the inner_object to fedora if it does not already exist" do
        pending
        Fedora::Repository.instance.expects(:save)
        Fedora::Repository.instance.expects(:find_objects).returns([])
        ActiveFedora::Base.new(:pid=>"test:1")
      end
    end
    
  end
  
  
  it 'should provide #find_by_solr' do
    SpecModel::Basic.should respond_to(:find)
  end
  
  describe '#find_by_solr' do
    it "(:all) should query solr for all objects with :active_fedora_model_s of self.class and return a Solr result" do
      mock_solr = mock("SolrConnection")
      mock_response = mock("SolrResponse")
      mock_solr.expects(:query).with('active_fedora_model_s:SpecModel\:\:Basic', {}).returns(mock_response)
      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock_solr))
    
      SpecModel::Basic.find_by_solr(:all).should equal(mock_response)
    end
    it "(String) should query solr for an object with the given id and return the Solr Result" do
      mock_solr = mock("SolrConnection")
      mock_response = mock("SolrResponse")
      mock_solr.expects(:query).with('id:changeme\:30', {}).returns(mock_response)
      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock_solr))
    
      SpecModel::Basic.find_by_solr("changeme:30").should equal(mock_response)
    end
  end
  
  describe "load_instance" do
    it "should use Repository.find_model to instantiate an object" do
      mock_repo = mock("repo")
      mock_repo.expects(:find_model).with("_PID_", SpecModel::Basic)
      Fedora::Repository.expects(:instance).returns(mock_repo) 
      SpecModel::Basic.load_instance("_PID_")
    end
  end
end
