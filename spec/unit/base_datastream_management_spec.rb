require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end
  
  describe '.add_datastream' do
    it "should not call Datastream.save" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'ds_to_add')
      ds.should_receive(:save).never
      @test_object.add_datastream(ds)
    end
    it "should add the datastream to the datastreams_in_memory array" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'ds_to_add')
      @test_object.datastreams.should_not have_key(ds.dsid)
      @test_object.add_datastream(ds)
      @test_object.datastreams.should have_key(ds.dsid)
    end
    it "should auto-assign dsids using auto-incremented integers if dsid is nil or an empty string" do 
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, nil)
      ds.dsid.should == 'DS1'
      @test_object.add_datastream(ds).should == 'DS1'
      ds_emptystringid = ActiveFedora::Datastream.new(@test_object.inner_object, '')
      @test_object.add_datastream(ds_emptystringid).should == 'DS2'
    end
    it "should accept a prefix option and apply it to automatically assigned dsids" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, nil, :prefix=> "FOO")
      ds.dsid.should == 'FOO1'
    end
  end
end
