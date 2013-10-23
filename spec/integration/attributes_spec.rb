require 'spec_helper'

describe "delegating attributes" do
  before :all do
    class TitledObject < ActiveFedora::Base
      has_metadata 'foo', type: ActiveFedora::SimpleDatastream do |m|
        m.field "title", :string
      end
      has_attributes :title, datastream: 'foo', multiple: false
    end
  end
  after :all do
    Object.send(:remove_const, :TitledObject)
  end

  describe "save" do
    subject do
      obj = TitledObject.create 
      obj.title = "Hydra for Dummies"
      obj.save
      obj
    end
    it "should keep a list of changes after a successful save" do
      subject.previous_changes.should_not be_empty
      subject.previous_changes.keys.should include("title")
    end
    it "should clean out changes" do
      subject.title_changed?.should be_false
      subject.changes.should be_empty
    end
  end
end

