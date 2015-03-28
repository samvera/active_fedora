require 'spec_helper'

describe "persisting objects" do
  before :all do
    class MockAFBaseRelationship < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"foo" do |m|
        m.field "name", :string
      end
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :name, datastream: 'foo', multiple: false
      end
      validates :name, presence: true
    end
  end
  after :all do
    Object.send(:remove_const, :MockAFBaseRelationship)
  end

  describe "#create!" do
    it "should validate" do
      expect { MockAFBaseRelationship.create!}.to raise_error ActiveFedora::RecordInvalid, "Validation failed: Name can't be blank"
    end
  end
end
