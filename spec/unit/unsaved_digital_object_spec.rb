require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do

  describe "an unsaved instance" do
    before do
      @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'bar')
    end
    it "should have ownerId property" do
      @obj.ownerId = 'fooo'
      expect(@obj.ownerId).to eq('fooo')
    end

    it "should have a default pid" do
      expect(@obj.pid).to eq("__DO_NOT_USE__")
    end
    it "should be able to set the pid" do
      @obj.pid = "my:new_object"
      expect(@obj.pid).to eq("my:new_object")
    end
  end


  describe "#save" do
    before :all do
      obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'bar')
      obj.label = 'my label'
      obj.ownerId = 'fooo'
      @saved_obj = obj.save
    end
    it "should be a digital object" do
      expect(@saved_obj).to be_kind_of ActiveFedora::DigitalObject
    end
    it "should set the ownerId property" do
      expect(@saved_obj.ownerId).to eq('fooo')
    end
    it "should set the label property" do
      expect(@saved_obj.label).to eq('my label')
    end
  end

end
