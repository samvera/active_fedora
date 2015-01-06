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
    expect(ds.fubar).to eq([])
    expect(ds).not_to be_nil
    ds.fubar=['bar']
    expect(ds.fubar).to eq(['bar'])
    @test_object.save

    expect(@test_object.pid).not_to be_nil

    x = FooHistory.find(@test_object.pid)
    ds2 = x.datastreams["someData"]
    expect(ds2.fubar).to eq(['bar'])
    ds2.fubar = ["meh"]
    expect(ds2.fubar).to eq(["meh"])
    x.save
    x = FooHistory.find(@test_object.pid)
    expect(x.datastreams['someData'].fubar).to eq(["meh"])
    x.save
  end
end
