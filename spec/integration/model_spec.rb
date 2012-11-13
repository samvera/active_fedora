require 'spec_helper'

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
    describe "#find with a valid pid with cast" do
      subject { ActiveFedora::Base.find('hydrangea:fixture_mods_article1', :cast=>true) }
      it { should be_instance_of HydrangeaArticle}
    end
    describe "#find with a valid pid without cast" do
      subject { ActiveFedora::Base.find('hydrangea:fixture_mods_article1') }
      it { should be_instance_of ActiveFedora::Base}
    end
  end

  describe "#load_instance_from_solr" do
    describe "with a valid pid" do
      subject { ActiveFedora::Base.load_instance_from_solr('hydrangea:fixture_mods_article1') }
      it { should be_instance_of HydrangeaArticle}
    end
    describe "with metadata datastrem spec" do
      subject { ActiveFedora::Base.load_instance_from_solr('hydrangea:fixture_mods_article1') }
      it "should create an xml datastream" do
        subject.datastreams['properties'].should be_kind_of ActiveFedora::SimpleDatastream
      end
    end
  end
end
