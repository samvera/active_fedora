require 'spec_helper'

describe "delegating properties" do
  describe "that have a reader and writer" do
    before :all do
      class TitledObject < ActiveFedora::Base
        has_metadata 'foo', type: ActiveFedora::SimpleDatastream do |m|
          m.field "title", :string
        end
        delegate :title, to: 'foo', multiple: false
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

  describe "that only have a writer" do
    before :all do
      class TestDatastream < ActiveFedora::NtriplesRDFDatastream
        # accepts_nested_attributes_for :title, would generate a method like this:
        def title_attributes=(attributes)
        end
      end
      class TitledObject < ActiveFedora::Base
        has_metadata 'foo', type: TestDatastream
        delegate :title_attributes, to: 'foo', multiple: false
      end
    end
    after :all do
      Object.send(:remove_const, :TitledObject)
      Object.send(:remove_const, :TestDatastream)
    end

    subject { TitledObject.new }

    it "Should delegate the method" do
      subject.title_attributes = {'0' => {'title' => 'Hello'}}
    end

  end
end
