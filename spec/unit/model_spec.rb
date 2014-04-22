require 'spec_helper'

describe ActiveFedora::Model do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end
    end
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
      SpecModel::Basic.solr_query_handler.should == 'standard'
    end
    it "should be settable" do
      SpecModel::Basic.solr_query_handler = 'search'
      SpecModel::Basic.solr_query_handler.should == 'search'
    end
  end
end
