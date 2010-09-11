require File.join( File.dirname(__FILE__), "..", "spec_helper" )

require 'active_fedora'
require 'active_fedora/model'
require "rexml/document"
require 'ftools'
require 'mocha'

include ActiveFedora::Model
include Mocha::Standalone

describe ActiveFedora::Model do
  
  
  before(:each) do 
    module SpecModel
      
      class BasicInt < ActiveFedora::Base
        #include ActiveFedora::Model
      end
      
    end
    @test_instance = SpecModel::BasicInt.new
    @test_instance.save
    
  end
  
  after(:each) do
    @test_instance.delete
    Object.send(:remove_const, :SpecModel)
  end
  
  describe '#find' do
    it "should return an array of instances of the calling Class" do
      pending
      result = SpecModel::BasicInt.find(:all)
      result.should be_instance_of(Array)
      result.each do |obj|
        obj.class.should == SpecModel::BasicInt
      end
    end
  end
  
  describe '#find_model' do
    
    it "should return an object of the given Model whose inner object is nil" do
      #result = SpecModel::BasicInt.find_model(@test_instance.pid, SpecModel::BasicInt)
      result = Fedora::Repository.instance.find_model(@test_instance.pid, SpecModel::BasicInt)
      result.class.should == SpecModel::BasicInt
      result.inner_object.new_object?.should be_false
    end
  end
  
end
