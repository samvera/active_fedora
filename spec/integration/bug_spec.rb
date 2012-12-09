require 'spec_helper'

require 'active_fedora'
require 'active_fedora/model'
require "rexml/document"
include ActiveFedora::Model

describe 'bugs' do
  before :all do
    class FooHistory < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText" do |m|
        m.field "fubar", :text
      end
    end
  end
  after :all do
    Object.send(:remove_const, :FooHistory)
  end

  before(:each) do
    @test_object = FooHistory.new
    @test_object.save
  end
  after(:each) do
    @test_object.delete
  end
  it "should not clobber everything when setting a value" do
    ds = @test_object.datastreams["someData"]
    ds.fubar.should == []
    ds.should_not be_nil
    ds.fubar=['bar']
    ds.fubar.should == ['bar']
    @test_object.save

    @test_object.pid.should_not be_nil

    x = FooHistory.find(@test_object.pid)
    ds2 = x.datastreams["someData"]
    ds2.fubar.should == ['bar']
    ds2.fubar = ["meh"]
    ds2.fubar.should == ["meh"]
    x.save
    x = FooHistory.find(@test_object.pid)
    x.datastreams['someData'].fubar.should == ["meh"]
    x.save
  end
end
