require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  it "should have ownerId property" do
    @obj = ActiveFedora::UnsavedDigitalObject.new(String, 'bar') 
    @obj.ownerId = 'fooo'
    @obj.ownerId.should == 'fooo'
  end

  describe "#save" do
    it "should set the ownerId property" do
      @obj = ActiveFedora::UnsavedDigitalObject.new(String, 'bar') 
      @obj.ownerId = 'fooo'
      saved_obj = @obj.save
      saved_obj.should be_kind_of ActiveFedora::DigitalObject
      saved_obj.ownerId.should == 'fooo'
    end
  end

end
