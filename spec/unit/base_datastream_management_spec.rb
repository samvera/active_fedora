require 'spec_helper'

describe ActiveFedora::Base do

  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  describe '.generate_dsid' do
    it "should return a dsid that is not currently in use" do
      dsids = Hash["DS1"=>1, "DS2"=>1]
      expect(@test_object).to receive(:datastreams).and_return(dsids)
      generated_id = @test_object.generate_dsid
      expect(generated_id).not_to be_nil
      expect(generated_id).to eq("DS3")
    end
    it "should accept a prefix argument, default to using DS as prefix" do
      expect(@test_object.generate_dsid("FOO")).to eq("FOO1")
    end

    it "if delete a datastream it should still use next index for a prefix" do
      dsids = Hash["DS2"=>1]
      expect(@test_object).to receive(:datastreams).and_return(dsids)
      generated_id = @test_object.generate_dsid
      expect(generated_id).not_to be_nil
      expect(generated_id).to eq("DS3")
    end
  end
  describe '.add_datastream' do
    it "should not call Datastream.save" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'ds_to_add')
      expect(ds).to receive(:save).never
      @test_object.add_datastream(ds)
    end
    it "should add the datastream to the datastreams_in_memory array" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'ds_to_add')
      expect(@test_object.datastreams).not_to have_key(ds.dsid)
      @test_object.add_datastream(ds)
      expect(@test_object.datastreams).to have_key(ds.dsid)
    end
    it "should auto-assign dsids using auto-incremented integers if dsid is nil or an empty string" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, nil)
      expect(ds.dsid).to eq(nil)
      ds_emptystringid = ActiveFedora::Datastream.new(@test_object.inner_object, '')
      @test_object.stub(:generate_dsid => 'foo')
     # ds.should_receive(:dsid=).with("foo")
      expect(@test_object.add_datastream(ds)).to eq('foo')
      expect(@test_object.add_datastream(ds_emptystringid)).to eq('foo')
    end
    it "should accept a prefix option and apply it to automatically assigned dsids" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, nil)
      expect(ds.dsid).to eq(nil)
      @test_object.stub(:generate_dsid => "FOO")
      expect(@test_object.add_datastream(ds, :prefix => "FOO")).to eq('FOO')
    end
  end
end
