require File.join( File.dirname(__FILE__), "..", "spec_helper" )

require 'active_fedora'
require 'active_fedora/model'
require "rexml/document"
require 'ftools'
require 'mocha'

include ActiveFedora::Model
include Mocha::Standalone

describe 'bugs' do
class FooHistory < ActiveFedora::Base
  has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
    m.field "fubar", :string
    m.field "swank", :text
  end
  has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText" do |m|
    m.field "fubar", :text
  end
end

  before(:each) do
    #Fedora::Repository.instance.stubs(:nextid).returns("foo:pid")
    @test_object = FooHistory.new
    @test_object.save
  end
  after(:each) do
    @test_object.delete
  end
  it "should not clobber everything when setting a value" do
    @test_object.datastreams["someData"].fubar_values.should == []
    @test_object.datastreams["someData"].should_not be_nil
    @test_object.datastreams["someData"].fubar_values=['bar']
    @test_object.datastreams["someData"].fubar_values.should == ['bar']
    @test_object.save

    @test_object.pid.should_not be_nil

    x = *FooHistory.find(@test_object.pid)
    x.datastreams["someData"].fubar_values.should == ['bar']
    x.datastreams['someData'].dirty?.should == false
    x.datastreams['someData'].fubar_values = ["meh"]
    x.datastreams['someData'].fubar_values.should == ["meh"]
    x.datastreams['someData'].dirty?.should == true
    x.save
    x = *FooHistory.find(@test_object.pid)
    x.datastreams['someData'].fubar_values.should == ["meh"]
    x.save
  end
  it "should update the index, even if there is no metadata" do
    pending
    oh = FooHistory.new
    oh.save
  end

end
