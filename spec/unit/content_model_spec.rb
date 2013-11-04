require 'spec_helper'

describe ActiveFedora::ContentModel do
  
  before(:all) do
    class BaseModel < ActiveFedora::Base
    end
    
    class SampleModel < BaseModel
    end

    class GenericContent < ActiveFedora::Base
    end
    
    module Sample
      class NamespacedModel < ActiveFedora::Base
      end
    end
  end
  
  before(:each) do
    stub_get('__nextid__')
    ActiveFedora::Base.stub(:assign_pid).and_return("__nextid__")
    Rubydora::Repository.any_instance.stub(:client).and_return(@mock_client)
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
  
  describe '.best_model_for' do
    it 'should be the input model if no relationships' do
      mock_object = BaseModel.new
      mock_object.should_receive(:relationships).with(:has_model).and_return([])
      expect(ActiveFedora::ContentModel.best_model_for(mock_object)).to eq BaseModel
    end

    it 'should be based on inheritance hierarchy' do
      mock_object = ActiveFedora::Base.new
      mock_object.should_receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", 'info:fedora/afmodel:SampleModel', 'info:fedora/afmodel:BaseModel'])
      expect(ActiveFedora::ContentModel.best_model_for(mock_object)).to eq SampleModel
    end

    it 'should find the deepest descendant of the on inheritance hierarchy' do
      mock_object = BaseModel.new
      mock_object.should_receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", 'info:fedora/afmodel:SampleModel', 'info:fedora/afmodel:BaseModel'])
      expect(ActiveFedora::ContentModel.best_model_for(mock_object)).to eq SampleModel
    end
  end
  
  describe "models_asserted_by" do
    it "should return an array of all of the content models asserted by the given object" do
      mock_object = double("ActiveFedora Object")
      mock_object.should_receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"])
      ActiveFedora::ContentModel.models_asserted_by(mock_object).should == ["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"]
    end
    it "should return an empty array if the object doesn't have a RELS-EXT datastream" do
      mock_object = double("ActiveFedora Object")
      mock_object.should_receive(:relationships).with(:has_model).and_return([])
      ActiveFedora::ContentModel.models_asserted_by(mock_object).should == []
    end
  end
  
  describe "known_models_asserted_by" do
    it "should figure out the applicable models to load" do
      mock_object = double("ActiveFedora Object")
      mock_object.should_receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"])
      ActiveFedora::ContentModel.known_models_for(mock_object).should == [SampleModel]
    end
    it "should support namespaced models" do
      pending "This is harder than it looks."
      mock_object = double("ActiveFedora Object")
      mock_object.should_receive(:relationships).with(:has_model).and_return(["info:fedora/afmodel:Sample_NamespacedModel"])
      ActiveFedora::ContentModel.known_models_for(mock_object).should == [Sample::NamespacedModel]
    end
    it "should default to using ActiveFedora::Base as the model" do
      mock_object = double("ActiveFedora Object")
      mock_object.should_receive(:relationships).with(:has_model).and_return(["info:fedora/afmodel:NonDefinedModel"])
      ActiveFedora::ContentModel.known_models_for(mock_object).should == [ActiveFedora::Base]
    end
    it "should still work even if the object doesn't have a RELS-EXT datastream" do
      mock_object = double("ActiveFedora Object")
      mock_object.should_receive(:relationships).with(:has_model).and_return([])
      ActiveFedora::ContentModel.known_models_for(mock_object).should == [ActiveFedora::Base]
    end
  end
  
  describe "uri_to_model_class" do
    it "should return an ActiveFedora Model class corresponding to the given uri if a valid model can be found" do
      ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:SampleModel").should == SampleModel
      ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:NonDefinedModel").should == false
      ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:String").should == false
      ActiveFedora::ContentModel.uri_to_model_class("info:fedora/hydra-cModel:genericContent").should == GenericContent
    end
  end

end
