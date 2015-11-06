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
    allow(ActiveFedora::Base).to receive(:assign_pid).and_return('__nextid__')
    allow_any_instance_of(Rubydora::Repository).to receive(:client).and_return(@mock_client)
    @test_cmodel = ActiveFedora::ContentModel.new
  end

  it 'should provide #new' do
    expect(ActiveFedora::ContentModel).to respond_to(:new)
  end

  describe '#new' do
    it 'should create a kind of ActiveFedora::Base object' do
      expect(@test_cmodel).to be_kind_of(ActiveFedora::Base)
    end
    it 'should set pid_suffix to empty string unless overriden in options hash' do
      expect(@test_cmodel.pid_suffix).to eq('')
      boo_model = ActiveFedora::ContentModel.new(:pid_suffix => 'boo')
      expect(boo_model.pid_suffix).to eq('boo')
    end
    it 'should set namespace to cmodel unless overriden in options hash' do
      expect(@test_cmodel.namespace).to eq('afmodel')
      boo_model = ActiveFedora::ContentModel.new(:namespace => 'boo')
      expect(boo_model.namespace).to eq('boo')
    end
  end

  it 'should provide @pid_suffix' do
    expect(@test_cmodel).to respond_to(:pid_suffix)
    expect(@test_cmodel).to respond_to(:pid_suffix=)
  end


  describe 'models_asserted_by' do
    it 'should return an array of all of the content models asserted by the given object' do
      mock_object = double('ActiveFedora Object')
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(['info:fedora/fedora-system:ServiceDefinition-3.0', 'info:fedora/afmodel:SampleModel', 'info:fedora/afmodel:NonDefinedModel'])
      expect(ActiveFedora::ContentModel.models_asserted_by(mock_object)).to eq(['info:fedora/fedora-system:ServiceDefinition-3.0', 'info:fedora/afmodel:SampleModel', 'info:fedora/afmodel:NonDefinedModel'])
    end
    it "should return an empty array if the object doesn't have a RELS-EXT datastream" do
      mock_object = double('ActiveFedora Object')
      expect(mock_object).to receive(:relationships).with(:has_model).and_return([])
      expect(ActiveFedora::ContentModel.models_asserted_by(mock_object)).to eq([])
    end
  end

  describe 'known_models_asserted_by' do
    it 'should figure out the applicable models to load' do
      mock_object = double('ActiveFedora Object')
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(['info:fedora/fedora-system:ServiceDefinition-3.0', 'info:fedora/afmodel:SampleModel', 'info:fedora/afmodel:NonDefinedModel'])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([SampleModel])
    end
    it 'should support namespaced models' do
      skip 'This is harder than it looks.'
      mock_object = double('ActiveFedora Object')
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(['info:fedora/afmodel:Sample_NamespacedModel'])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([Sample::NamespacedModel])
    end
    it 'should default to using ActiveFedora::Base as the model' do
      mock_object = double('ActiveFedora Object')
      expect(mock_object).to receive(:relationships).with(:has_model).and_return(['info:fedora/afmodel:NonDefinedModel'])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([ActiveFedora::Base])
    end
    it "should still work even if the object doesn't have a RELS-EXT datastream" do
      mock_object = double('ActiveFedora Object')
      expect(mock_object).to receive(:relationships).with(:has_model).and_return([])
      expect(ActiveFedora::ContentModel.known_models_for(mock_object)).to eq([ActiveFedora::Base])
    end
  end

  describe 'uri_to_model_class' do
    it 'should return an ActiveFedora Model class corresponding to the given uri if a valid model can be found' do
      expect(ActiveFedora::ContentModel.uri_to_model_class('info:fedora/afmodel:SampleModel')).to eq(SampleModel)
      expect(ActiveFedora::ContentModel.uri_to_model_class('info:fedora/afmodel:NonDefinedModel')).to eq(false)
      expect(ActiveFedora::ContentModel.uri_to_model_class('info:fedora/afmodel:String')).to eq(false)
      expect(ActiveFedora::ContentModel.uri_to_model_class('info:fedora/hydra-cModel:genericContent')).to eq(GenericContent)
    end
  end

end
