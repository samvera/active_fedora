require 'spec_helper'

describe ActiveFedora::Base do

  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  describe '.attach_file' do
    it "should not call File.save" do
      ds = ActiveFedora::File.new(@test_object, 'ds_to_add')
      expect(ds).to receive(:save).never
      @test_object.attach_file(ds)
    end
    it "should add the datastream to the datastreams_in_memory array" do
      ds = ActiveFedora::File.new(@test_object, 'ds_to_add')
      expect(@test_object.attached_files).to_not have_key(ds.dsid)
      @test_object.attach_file(ds)
      expect(@test_object.attached_files).to have_key(ds.dsid)
    end
    it "should auto-assign dsids using auto-incremented integers if dsid is nil or an empty string" do
      ds = ActiveFedora::File.new(@test_object, nil)
      expect(ds.dsid).to eq 'DS1'
      expect(@test_object.attach_file(ds)).to eq 'DS1'
      ds_emptystringid = ActiveFedora::File.new(@test_object, '')
      expect(@test_object.attach_file(ds_emptystringid)).to eq 'DS2'
    end
    it "should accept a prefix option and apply it to automatically assigned dsids" do
      ds = ActiveFedora::File.new(@test_object, nil, :prefix=> "FOO")
      expect(ds.dsid).to eq 'FOO1'
    end
  end
end
