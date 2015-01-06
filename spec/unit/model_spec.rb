require 'spec_helper'

class SpecModelBasic < ActiveFedora::Base
end

describe ActiveFedora::Model do

  describe '.solr_query_handler' do
    after do
      SpecModelBasic.solr_query_handler = 'standard'  # reset to default
    end
    it "should have a default" do
      expect(SpecModelBasic.solr_query_handler).to eq('standard')
    end
    it "should be settable" do
      SpecModelBasic.solr_query_handler = 'search'
      expect(SpecModelBasic.solr_query_handler).to eq('search')
    end
  end

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

describe ActiveFedora::Model do

  before :each do
    module SpecModel
      class CamelCased
        include ActiveFedora::Model
      end
    end
  end

  describe "URI translation" do
    it "to_class_uri correct" do
      expect(SpecModel::CamelCased.to_class_uri).to eq 'info:fedora/afmodel:SpecModel_CamelCased'
    end
  end

  describe "URI translation" do
    before :each do
      allow(SpecModel::CamelCased).to receive(:pid_namespace).and_return("test-cModel")
    end
    it "with the namespace declared in the model" do
      expect(SpecModel::CamelCased.to_class_uri).to eq 'info:fedora/test-cModel:SpecModel_CamelCased'
    end
  end

  describe "URI translation" do
    before :each do
      allow(SpecModel::CamelCased).to receive(:pid_suffix).and_return("-TEST-SUFFIX")
    end
    it "with the suffix declared in the model" do
      expect(SpecModel::CamelCased.to_class_uri).to eq 'info:fedora/afmodel:SpecModel_CamelCased-TEST-SUFFIX'
    end
  end

end
