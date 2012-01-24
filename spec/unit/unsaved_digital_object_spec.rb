require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  
  it "should have ownerId property" do
    @obj = ActiveFedora::UnsavedDigitalObject.new(String, 'bar') 
    @obj.ownerId = 'fooo'
    @obj.ownerId.should == 'fooo'
  end

  describe "#save" do
    before :all do
      obj = ActiveFedora::UnsavedDigitalObject.new(String, 'bar') 
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
