require 'spec_helper'

describe ActiveFedora::Persistence do
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
    describe "when metadata is dirty" do
      before do
        subject.send(:metadata_is_dirty=, true)
      end
      it "should be true" do
        subject.send(:update_needs_index?).should be_true
      end
    end

    describe "when metadata is not dirty" do
      it "should be false" do
        subject.send(:update_needs_index?).should be_false
      end
    end
  end


end
