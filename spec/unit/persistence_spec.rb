require 'spec_helper'

describe ActiveFedora::Persistence do
  context "internal methods" do
    before :all do
      class SpecNode
        include ActiveFedora::Persistence
      end
    end
    after :all do
      Object.send(:remove_const, :SpecNode)
    end

    subject { SpecNode.new }

    describe "#create_needs_index?" do
      it "should be true" do
        subject.send(:create_needs_index?).should be_true
      end
    end

    describe "#update_needs_index?" do
      it "should be true" do
        subject.send(:update_needs_index?).should be_true
      end
    end
  end

  describe "an unsaved object" do
    subject { ActiveFedora::Base.new }
    it "should be deleteable (nop) and return the object" do
      expect(subject.delete).to eq subject
    end
  end

  describe "a saved object" do
    subject { ActiveFedora::Base.create! }
    describe "that is deleted" do
      before do
        subject.delete
      end
      it "should be frozen" do
        expect(subject).to be_frozen
      end
    end
  end
end
