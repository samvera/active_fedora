require 'spec_helper'

describe ActiveFedora::Model do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end
    end
    @model_query = "has_model_s:#{solr_uri("info:fedora/afmodel:SpecModel_Basic")}"
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  describe '.solr_query_handler' do
    after do
      # reset to default
      SpecModel::Basic.solr_query_handler = 'standard'
    end
    it "should have a default" do
      expect(SpecModel::Basic.solr_query_handler).to eq('standard')
    end
    it "should be settable" do
      SpecModel::Basic.solr_query_handler = 'search'
      expect(SpecModel::Basic.solr_query_handler).to eq('search')
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
  
    describe ".classname_from_uri" do 
      it "should turn an afmodel URI into a Model class name" do
        expect(ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:SpecModel_CamelCased')).to eq(['SpecModel::CamelCased', 'afmodel'])
      end
      it "should not change plurality" do
        expect(ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:MyMetadata')).to eq(['MyMetadata', 'afmodel'])
      end
      it "should capitalize the first letter" do
        expect(ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:image')).to eq(['Image', 'afmodel'])
      end
    end
  end
  
end
