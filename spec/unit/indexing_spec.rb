require 'spec_helper'

describe ActiveFedora::Indexing do
  context "internal methods" do
    before :all do
      class SpecNode
        include ActiveFedora::Indexing
      end
    end
    after :all do
      Object.send(:remove_const, :SpecNode)
    end

    subject { SpecNode.new }

    describe "#create_needs_index?" do
      subject { SpecNode.new.send(:create_needs_index?) }
      it { should be true }
    end

    describe "#update_needs_index?" do
      subject { SpecNode.new.send(:update_needs_index?) }
      it { should be true }
    end
  end
end
