require 'spec_helper'

describe "persisting objects" do
  describe "#create!" do
    before do
      class MockAFBaseRelationship < ActiveFedora::Base
        has_metadata type: ActiveFedora::SimpleDatastream, name: "foo" do |m|
          m.field "name", :string
        end
        property :name, delegate_to: 'foo', multiple: false
        validates :name, presence: true
      end
    end

    after do
      Object.send(:remove_const, :MockAFBaseRelationship)
    end

    it "validates" do
      expect { MockAFBaseRelationship.create! }.to raise_error ActiveFedora::RecordInvalid, "Validation failed: Name can't be blank"
    end
  end
end
