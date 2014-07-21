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
      subject { SpecNode.new.send(:create_needs_index?) }
      it { should be true }
    end

    describe "#update_needs_index?" do
      subject { SpecNode.new.send(:update_needs_index?) }
      it { should be true }
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

  describe "destroy" do
    subject { ActiveFedora::Base.create! }
    it "should not clear the pid" do
      subject.destroy
      expect(subject.pid).not_to be_nil
    end
  end

  describe "save" do
    subject { ActiveFedora::Base.new }
    context "when called with option :update_index=>false" do
      context "on a new record" do
        it "should not update the index" do
          expect(subject).to receive(:persist).with(false)
          subject.save(update_index: false)
        end
      end
      context "on a persisted record" do
        before do
          allow(subject).to receive(:new_record?) { false }
          allow_any_instance_of(Ldp::Orm).to receive(:save!) { true }
        end
        it "should not update the index" do
          expect(subject).to receive(:persist).with(false)
          subject.save(update_index: false)
        end        
      end
    end
    context "when called with option :update_index=>true" do
      context "on create" do
        before { allow(subject).to receive(:create_needs_index?) { false } }
        it "should not override `create_needs_index?'" do
          expect(subject).to receive(:persist).with(false)
          subject.save(update_index: true)
        end
      end
      context "on update" do
        before do
          allow(subject).to receive(:new_record?) { false }
          allow_any_instance_of(Ldp::Orm).to receive(:save!) { true }
          allow(subject).to receive(:update_needs_index?) { false }
        end
        it "should not override `update_needs_index?'" do
          expect(subject).to receive(:persist).with(false)
          subject.save(update_index: true)
        end
      end
    end
  end
end
