require 'spec_helper'

describe ActiveFedora::Persistence do

  describe "an unsaved object" do
    subject { ActiveFedora::Base.new }
    it "should be deleteable (nop) and return the object" do
      expect(subject.delete).to eq subject
    end
  end

  describe ".create" do
    context "when a block is provided" do
      it "should pass the block to initialize" do
        expect_any_instance_of(ActiveFedora::Base).to receive(:save)
        expect { |b| ActiveFedora::Base.create(&b) }.to yield_with_args(an_instance_of ActiveFedora::Base)
      end
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
    it "should not clear the id" do
      subject.destroy
      expect(subject.id).not_to be_nil
    end
  end

  describe "save" do
    subject { ActiveFedora::Base.new }

    context "when called with option update_index: false" do
      context "on a new record" do
        it "should not update the index" do
          expect(subject).to_not receive(:update_index)
          subject.save(update_index: false)
        end
      end

      context "on a persisted record" do
        before do
          allow(subject).to receive(:new_record?) { false }
          allow_any_instance_of(Ldp::Orm).to receive(:save) { true }
          allow(subject).to receive(:update_modified_date)
        end

        it "should not update the index" do
          expect(subject).to_not receive(:update_index)
          subject.save(update_index: false)
        end
      end
    end

    context "when called with option :update_index=>true" do
      context "on create" do
        before { allow(subject).to receive(:create_needs_index?) { false } }

        it "should not override `create_needs_index?'" do
          expect(subject).to_not receive(:update_index)
          subject.save(update_index: true)
        end
      end

      context "on update" do
        before do
          allow(subject).to receive(:new_record?) { false }
          allow_any_instance_of(Ldp::Orm).to receive(:save) { true }
          allow(subject).to receive(:update_needs_index?) { false }
          allow(subject).to receive(:update_modified_date)
        end

        it "should not override `update_needs_index?'" do
          expect(subject).to_not receive(:update_index)
          subject.save(update_index: true)
        end
      end
    end
  end
end
