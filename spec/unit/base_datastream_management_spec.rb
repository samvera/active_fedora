require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
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
      expect(ds.dsid).to eq('DS1')
      expect(@test_object.add_datastream(ds)).to eq('DS1')
      ds_emptystringid = ActiveFedora::Datastream.new(@test_object.inner_object, '')
      expect(@test_object.add_datastream(ds_emptystringid)).to eq('DS2')
    end
    it "should accept a prefix option and apply it to automatically assigned dsids" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, nil, :prefix=> "FOO")
      expect(ds.dsid).to eq('FOO1')
    end
  end
end
