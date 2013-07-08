require 'spec_helper'

require 'active_fedora'
require 'active_fedora/model'
require "rexml/document"
include ActiveFedora::Model

describe 'bugs' do
  before do
    class FooHistory < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
      end
    end
    @test_object = FooHistory.new
    @test_object.save
  end
  after do
    @test_object.delete
    Object.send(:remove_const, :FooHistory)
  end

  it 'should raise ActiveFedora::ObjectNotFoundError when find("")' do
    expect {
      FooHistory.find('')
    }.to raise_error(ActiveFedora::ObjectNotFoundError)
  end

  it "should not clobber everything when setting a value" do
    @test_object.someData.fubar=['initial']
    @test_object.save!

    x = FooHistory.find(@test_object.pid)
    x.someData.fubar = ["replacement"] # set a new value
    x.save!


    x = FooHistory.find(@test_object.pid)
    x.someData.fubar.should == ["replacement"] # recall the value
    x.save
  end
end
