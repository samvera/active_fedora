require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'mocha'


describe ActiveFedora::ContentModel do
  
  before(:all) do
    class SampleModel < ActiveFedora::Base
    end
  end
  
  before(:each) do
    Fedora::Repository.instance.stubs(:nextid).returns("_nextid_")
    @test_cmodel = ActiveFedora::ContentModel.new
  end
  
  it "should provide #new" do
    ActiveFedora::ContentModel.should respond_to(:new)
  end
  
  describe "#new" do
    it "should create a kind of ActiveFedora::Base object" do
      @test_cmodel.should be_kind_of(ActiveFedora::Base)
    end
    it "should set pid_suffix to empty string unless overriden in options hash" do
      @test_cmodel.pid_suffix.should == ""
      boo_model = ActiveFedora::ContentModel.new(:pid_suffix => "boo")
      boo_model.pid_suffix.should == "boo"
    end
    it "should set namespace to cmodel unless overriden in options hash" do
      @test_cmodel.namespace.should == "afmodel"
      boo_model = ActiveFedora::ContentModel.new(:namespace => "boo")
      boo_model.namespace.should == "boo"
    end
  end
  
  it "should provide @pid_suffix" do
    @test_cmodel.should respond_to(:pid_suffix)
    @test_cmodel.should respond_to(:pid_suffix=)
  end
  
  it 'should provide #pid_from_ruby_class' do
    ActiveFedora::ContentModel.should respond_to(:pid_from_ruby_class)
  end
  
  describe "#pid_from_ruby_class" do
    it "should construct pids" do
     ActiveFedora::ContentModel.pid_from_ruby_class(@test_cmodel.class).should == "afmodel:ActiveFedora_ContentModel"
     ActiveFedora::ContentModel.pid_from_ruby_class(@test_cmodel.class, :namespace => "foo", :pid_suffix => "BarBar").should == "foo:ActiveFedora_ContentModelBarBar"
    end
  end
  
  describe "models_asserted_by" do
    it "should return an array of all of the content models asserted by the given object" do
      mock_object = mock("ActiveFedora Object")
      mock_object.expects(:relationships).returns( :self=>{:has_model=>["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"]} )
      ActiveFedora::ContentModel.models_asserted_by(mock_object).should == ["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"]
    end
    it "should return an empty array if the object doesn't have a RELS-EXT datastream" do
      mock_object = mock("ActiveFedora Object")
      mock_object.expects(:relationships).returns( :self=>{} )
      ActiveFedora::ContentModel.models_asserted_by(mock_object).should == []
    end
  end
  
  describe "known_models_asserted_by" do
    it "should figure out the applicable models to load" do
      mock_object = mock("ActiveFedora Object")
      mock_object.expects(:relationships).returns( :self=>{:has_model=>["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"]} )
      ActiveFedora::ContentModel.known_models_for(mock_object).should == [SampleModel]
    end
    it "should default to using ActiveFedora::Base as the model" do
      mock_object = mock("ActiveFedora Object")
      mock_object.expects(:relationships).returns( :self=>{:has_model=>["info:fedora/afmodel:NonDefinedModel"]} )
      ActiveFedora::ContentModel.known_models_for(mock_object).should == [ActiveFedora::Base]
    end
    it "should still work even if the object doesn't have a RELS-EXT datastream" do
      mock_object = mock("ActiveFedora Object")
      mock_object.expects(:relationships).returns( :self=>{} )
      ActiveFedora::ContentModel.known_models_for(mock_object).should == [ActiveFedora::Base]
    end
  end
  
  describe "uri_to_ruby_class" do
    it "should return ruby class corresponding to the given uri if a valid class can be found" do
      ActiveFedora::ContentModel.uri_to_ruby_class("info:fedora/afmodel:SampleModel").should == SampleModel
      ActiveFedora::ContentModel.uri_to_ruby_class("info:fedora/afmodel:NonDefinedModel").should == false
      ActiveFedora::ContentModel.uri_to_ruby_class("info:fedora/afmodel:String").should == String
    end
  end
  
  describe "uri_to_model_class" do
    it "should return an ActiveFedora Model class corresponding to the given uri if a valid model can be found" do
      ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:SampleModel").should == SampleModel
      ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:NonDefinedModel").should == false
      ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:String").should == false
    end
  end

end
