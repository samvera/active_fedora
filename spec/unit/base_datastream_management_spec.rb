require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end
  
  describe '.generate_dsid' do
    it "should return a dsid that is not currently in use" do
      dsids = Hash["DS1"=>1, "DS2"=>1]
      @test_object.should_receive(:datastreams).and_return(dsids)
      generated_id = @test_object.generate_dsid
      generated_id.should_not be_nil
      generated_id.should == "DS3"
    end
    it "should accept a prefix argument, default to using DS as prefix" do
      @test_object.generate_dsid("FOO").should == "FOO1"  
    end

    it "if delete a datastream it should still use next index for a prefix" do
      dsids = Hash["DS2"=>1]
      @test_object.should_receive(:datastreams).and_return(dsids)
      generated_id = @test_object.generate_dsid
      generated_id.should_not be_nil
      generated_id.should == "DS3"
    end
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
      ds.dsid.should == nil
      ds_emptystringid = ActiveFedora::Datastream.new(@test_object.inner_object, '')
      @test_object.stub(:generate_dsid => 'foo')
     # ds.should_receive(:dsid=).with("foo")
      @test_object.add_datastream(ds).should == 'foo'
      @test_object.add_datastream(ds_emptystringid).should == 'foo'
    end
    it "should accept a prefix option and apply it to automatically assigned dsids" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, nil)
      ds.dsid.should == nil
      @test_object.stub(:generate_dsid => "FOO")
      @test_object.add_datastream(ds, :prefix => "FOO").should == 'FOO'
    end
  end
end
