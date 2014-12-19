require 'spec_helper'

class SpecModelBasic < ActiveFedora::Base
end
module SpecModel
  class CamelCased
    include ActiveFedora::Model
  end
end

describe ActiveFedora::Model do
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  before :each do
    @cc = SpecModel::CamelCased.new
  end

  describe '.solr_query_handler' do
    after do
      # reset to default
      SpecModelBasic.solr_query_handler = 'standard'
    end
    it "should have a default" do
      SpecModelBasic.solr_query_handler.should == 'standard'
    end
    it "should be settable" do
      SpecModelBasic.solr_query_handler = 'search'
      SpecModelBasic.solr_query_handler.should == 'search'
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

  describe ".classname_from_uri" do
    it "should turn an afmodel URI into a Model class name" do
      ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:SpecModel_CamelCased').should == ['SpecModel::CamelCased', 'afmodel']
    end
    it "should not change plurality" do
      ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:MyMetadata').should == ['MyMetadata', 'afmodel']
    end
    it "should capitalize the first letter" do
      ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:image').should == ['Image', 'afmodel']
    end
  end

end
