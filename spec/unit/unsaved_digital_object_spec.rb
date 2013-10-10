require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  
  describe "an unsaved instance" do
    before do
      @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'bar') 
    end
    it "should have ownerId property" do
      @obj.ownerId = 'fooo'
      @obj.ownerId.should == 'fooo'
    end

    it "should have state" do
      @obj.ownerId = 'D'
      @obj.ownerId.should == 'D'
    end

    it "should not have a default pid" do
      @obj.pid.should be_nil
    end
    it "should be able to set the pid" do
      @obj.pid = "my:new_object"
      @obj.pid.should == "my:new_object"
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
      @saved_obj.should be_kind_of ActiveFedora::DigitalObject
    end
    it "should set the ownerId property" do
      @saved_obj.ownerId.should == 'fooo'
    end
    it "should set the label property" do
      @saved_obj.label.should == 'my label'
    end
  end

end
