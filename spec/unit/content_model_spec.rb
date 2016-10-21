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
      expect(mock_object).to receive(:relationships).with(:has_model).and_return([])
      expect(ActiveFedora::ContentModel.best_model_for(mock_object)).to be_nil
    end

    it 'should be based on inheritance hierarchy' do
      mock_object = ActiveFedora::Base.new
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", 'info:fedora/afmodel:SampleModel', 'info:fedora/afmodel:BaseModel'])
      expect(ActiveFedora::ContentModel.best_model_for(mock_object)).to eq SampleModel
    end

    it 'should find the deepest descendant of the on inheritance hierarchy' do
      mock_object = BaseModel.new
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", 'info:fedora/afmodel:SampleModel', 'info:fedora/afmodel:BaseModel'])
      expect(ActiveFedora::ContentModel.best_model_for(mock_object)).to eq SampleModel
    end
  end
  
  describe "models_asserted_by" do
    it "should return an array of all of the content models asserted by the given object" do
      mock_object = double("ActiveFedora Object")
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"])
      expect(ActiveFedora::ContentModel.models_asserted_by(mock_object)).to eq(["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"])
    end
    it "should return an empty array if the object doesn't have a RELS-EXT datastream" do
      mock_object = double("ActiveFedora Object")
      expect(mock_object).to receive(:relationships).with(:has_model).and_return([])
      expect(ActiveFedora::ContentModel.models_asserted_by(mock_object)).to eq([])
    end
  end
  
  describe "known_models_asserted_by" do
    it "should figure out the applicable models to load" do
      mock_object = double("ActiveFedora Object")
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(["info:fedora/fedora-system:ServiceDefinition-3.0", "info:fedora/afmodel:SampleModel", "info:fedora/afmodel:NonDefinedModel"])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([SampleModel])
    end
    it "should support namespaced models" do
      mock_object = double("ActiveFedora Object")
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(["info:fedora/afmodel:Sample_NamespacedModel"])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([Sample::NamespacedModel])
    end
    it "should default to using ActiveFedora::Base as the model" do
      mock_object = double("ActiveFedora Object")
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(["info:fedora/afmodel:NonDefinedModel"])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([ActiveFedora::Base])
    end
    it "should still work even if the object doesn't have a RELS-EXT datastream" do
      mock_object = double("ActiveFedora Object")
      expect(mock_object).to receive(:relationships).with(:has_model).and_return([])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([ActiveFedora::Base])
    end
  end
  
  describe "uri_to_model_class" do
    it "should return an ActiveFedora Model class corresponding to the given uri if a valid model can be found" do
      expect(ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:SampleModel")).to eq(SampleModel)
      expect(ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:NonDefinedModel")).to eq(false)
      expect(ActiveFedora::ContentModel.uri_to_model_class("info:fedora/afmodel:String")).to eq(false)
      expect(ActiveFedora::ContentModel.uri_to_model_class("info:fedora/hydra-cModel:genericContent")).to eq(GenericContent)
    end
  end

end
