require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  
  describe "an unsaved instance" do
    subject { ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'bar') }

    it { should be_new_record}

    it "should have ownerId property" do
      subject.ownerId = 'fooo'
      subject.ownerId.should == 'fooo'
    end

    it "should have state" do
      subject.ownerId = 'D'
      subject.ownerId.should == 'D'
    end

    it "should not have a default pid" do
      subject.pid.should be_nil
    end
    it "should be able to set the pid" do
      subject.pid = "my:new_object"
      subject.pid.should == "my:new_object"
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
