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
  
  describe '.best_model_for' do
    it 'should be nil if no relationships' do
      mock_object = BaseModel.new
      mock_object.should_receive(:relationships).with(:has_model).and_return([])
      expect(ActiveFedora::ContentModel.best_model_for(mock_object)).to be_nil
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
