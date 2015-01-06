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
      expect(subject.send(:create_needs_index?)).to be_truthy
    end
  end

  describe "#update_needs_index?" do
      it "should be true" do
        expect(subject.send(:update_needs_index?)).to be_truthy
      end
  end


end
