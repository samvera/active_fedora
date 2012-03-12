require 'spec_helper'
#require 'spec/samples/models/hydrangea_article'

include ActiveFedora::Model
include Mocha::API

describe ActiveFedora::Model do
  
  
  before(:each) do 
    module ModelIntegrationSpec
      
      class Base < ActiveFedora::Base
        include ActiveFedora::Model
        def self.pid_namespace
          "foo"
        end
      end
      class Basic < Base
      end
    end

    @test_instance = ModelIntegrationSpec::Basic.new
    @test_instance.save
    
  end
  
  after(:each) do
    @test_instance.delete
    Object.send(:remove_const, :ModelIntegrationSpec)
  end
  
  describe '#find' do
    describe "with :all" do
      it "should return an array of instances of the calling Class" do
        result = ModelIntegrationSpec::Basic.find(:all)
        result.should be_instance_of(Array)
        # this test is meaningless if the array length is zero
        result.length.should > 0
        result.each do |obj|
          obj.class.should == ModelIntegrationSpec::Basic
        end
      end
    end
    describe "#find with a valid pid" do
      subject { ActiveFedora::Base.find('hydrangea:fixture_mods_article1') }
      it { should be_instance_of HydrangeaArticle}
    end
  end

  
  describe '#load_instance' do
    it "should return an object of the given Model whose inner object is nil" do
      ActiveSupport::Deprecation.expects(:warn).with("load_instance is deprecated.  Use find instead")
      result = ModelIntegrationSpec::Basic.load_instance(@test_instance.pid)
      result.class.should == ModelIntegrationSpec::Basic
      result.inner_object.new?.should be_false
    end
  end
  
end
