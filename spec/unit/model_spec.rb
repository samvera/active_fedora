require 'spec_helper'

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
    ActiveFedora::Base.stubs(:assign_pid).returns('_nextid_')
    @test_instance = SpecModel::Basic.new
    @property = stub("myproperty", :name => "mock_prop", :instance_variable_name => "@mock_prop")
    SpecModel::Basic.extend(ActiveFedora::Model)
    SpecModel::Basic.create_property_getter(@property)
    @obj = SpecModel::Basic.new
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  it 'should provide #attribute_set and #attribute_get' do
    SpecModel::Basic.should respond_to(:attribute_set)
    SpecModel::Basic.should respond_to(:attribute_get) 
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
  
  describe '#find' do
    it "(:all) should query solr for all objects with :active_fedora_model_s of self.class" do
      ActiveFedora::SolrService.expects(:query).with('has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic', :rows=>1001).returns([{"id" => "changeme:30"}, {"id" => "changeme:22"}])
      SpecModel::Basic.expects(:find_one).with("changeme:30").returns("Fake Object1")
      SpecModel::Basic.expects(:find_one).with("changeme:22").returns("Fake Object2")
      SpecModel::Basic.find(:all, :rows=>1001).should == ["Fake Object1", "Fake Object2"]
    end
    it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
      ActiveFedora::ContentModel.expects(:known_models_for).returns([SpecModel::Basic])
      SpecModel::Basic.any_instance.expects(:init_with).returns(mock("Model", :adapt_to=>SpecModel::Basic ))
      ActiveFedora::DigitalObject.expects(:find).returns(stub("inner obj", :'new?'=>false))
      SpecModel::Basic.find("_PID_")
    end
    it "should raise an exception if it is not found" do
      SpecModel::Basic.expects(:connection_for_pid).with("_PID_")
      lambda {SpecModel::Basic.find("_PID_")}.should raise_error ActiveFedora::ObjectNotFoundError
    end
  end

  describe '#count' do
    
    it "should return a count" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.expects(:query).with('has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic', :rows=>0, :raw=>true).returns(mock_result)
      SpecModel::Basic.count.should == 7
    end
    it "should allow conditions" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.expects(:query).with('has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic AND foo:bar', :rows=>0, :raw=>true).returns(mock_result)
      SpecModel::Basic.count(:conditions=>'foo:bar').should == 7
    end
  end
  
  
  it 'should provide #find_by_solr' do
    SpecModel::Basic.should respond_to(:find)
  end
  
  describe '#find_by_solr' do
    it "(:all) should query solr for all objects with :active_fedora_model_s of self.class and return a Solr result" do
      mock_response = mock("SolrResponse")
      ActiveFedora::SolrService.expects(:query).with('active_fedora_model_s:SpecModel\:\:Basic', {}).returns(mock_response)
    
      SpecModel::Basic.find_by_solr(:all).should equal(mock_response)
    end
    it "(String) should query solr for an object with the given id and return the Solr Result" do
      mock_response = mock("SolrResponse")
      ActiveFedora::SolrService.expects(:query).with('id:changeme\:30', {}).returns(mock_response)
    
      SpecModel::Basic.find_by_solr("changeme:30").should equal(mock_response)
    end
  end
  
  describe "load_instance" do
    it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
      ActiveSupport::Deprecation.expects(:warn).with("load_instance is deprecated.  Use find instead")
      SpecModel::Basic.expects(:find).with("_PID_")
      SpecModel::Basic.load_instance("_PID_")
    end
  end
  
  describe "URI translation" do
    before :all do
      module SpecModel
        class CamelCased
          include ActiveFedora::Model
        end
      end

    end
    
    after :all do
      SpecModel.send(:remove_const, :CamelCased)
    end
    subject {SpecModel::CamelCased}
    
    its(:to_class_uri) {should == 'info:fedora/afmodel:SpecModel_CamelCased' }
  
    context "with the namespace declared in the model" do
      before do
        subject.stubs(:pid_namespace).returns("test-cModel")
      end
      its(:to_class_uri) {should == 'info:fedora/test-cModel:SpecModel_CamelCased' }
    end
    context "with the suffix declared in the model" do
      before do
        subject.stubs(:pid_suffix).returns("-TEST-SUFFIX")
      end
      its(:to_class_uri) {should == 'info:fedora/afmodel:SpecModel_CamelCased-TEST-SUFFIX' }
    end
  
    
    it "should turn an afmodel URI into a Model class name" do
      ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:SpecModel_CamelCased').should == ['SpecModel::CamelCased', 'afmodel']
    end
  end
  
end
