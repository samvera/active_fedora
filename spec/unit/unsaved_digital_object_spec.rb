require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  
  describe "an unsaved instance" do
    subject { ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'bar') }

    it { is_expected.to be_new_record}

    it "should have ownerId property" do
      subject.ownerId = 'fooo'
      expect(subject.ownerId).to eq('fooo')
    end

    it "should have state" do
      subject.ownerId = 'D'
      expect(subject.ownerId).to eq('D')
    end

    it "should not have a default pid" do
      expect(subject.pid).to be_nil
    end
    it "should be able to set the pid" do
      subject.pid = "my:new_object"
      expect(subject.pid).to eq("my:new_object")
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
