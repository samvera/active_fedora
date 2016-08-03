require 'spec_helper'

describe ActiveFedora::Persistence do
  describe '#new_record?' do
    context 'with an new object' do
      subject(:persistence) { ActiveFedora::Base.new }
      it { is_expected.to be_new_record }
    end

    context 'with an destroyed object' do
      subject(:persistence) { ActiveFedora::Base.create }
      before { persistence.delete }
      it { is_expected.not_to be_new_record }
    end
  end

  describe '.delete' do
    context 'with an unsaved object' do
      subject(:persistence) { ActiveFedora::Base.new }
      before { persistence.delete }
      it { is_expected.to eq persistence }
    end

    context 'with a saved object' do
      subject(:persistence) { ActiveFedora::Base.create! }
      before { persistence.delete }
      it { is_expected.to be_frozen }
    end
  end

  describe '.create' do
    context 'when a block is provided' do
      it 'passes the block to initialize' do
        expect_any_instance_of(ActiveFedora::Base).to receive(:save)
        expect { |b| ActiveFedora::Base.create(&b) }.to yield_with_args(an_instance_of(ActiveFedora::Base))
      end
    end

    context "when trying to create it again" do
      let(:object) { ActiveFedora::Base.create! }

      it "raises an error" do
        expect { ActiveFedora::Base.create(id: object.id) }.to raise_error(ActiveFedora::IllegalOperation, "Attempting to recreate existing ldp_source: `#{object.uri}'")
      end
    end
  end

  describe '.destroy' do
    subject(:persistence) { ActiveFedora::Base.create! }
    context 'with no options' do
      before { persistence.destroy }
      it 'does not clear the id' do
        expect(persistence.id).not_to be_nil
      end
    end

    context 'with option eradicate: true' do
      it 'deletes the tombstone' do
        expect(persistence.class).to receive(:eradicate).with(persistence.id).and_return(true)
        persistence.destroy(eradicate: true)
      end
    end
  end

  describe "save" do
    subject(:persistence) { ActiveFedora::Base.new }

    context "when called with option update_index: false" do
      context "on a new record" do
        it "does not update the index" do
          expect(persistence).to_not receive(:update_index)
          persistence.save(update_index: false)
        end
      end

      context "on a persisted record" do
        before do
          allow(persistence).to receive(:new_record?) { false }
          allow_any_instance_of(Ldp::Orm).to receive(:save) { true }
          allow(persistence).to receive(:update_modified_date)
        end

        it "does not update the index" do
          expect(persistence).to_not receive(:update_index)
          persistence.save(update_index: false)
        end
      end
    end

    context "when called with option :update_index=>true" do
      context "on create" do
        before { allow(persistence).to receive(:create_needs_index?) { false } }

        it "does not override `create_needs_index?'" do
          expect(persistence).to_not receive(:update_index)
          persistence.save(update_index: true)
        end
      end

      context "on update" do
        before do
          allow(persistence).to receive(:new_record?) { false }
          allow_any_instance_of(Ldp::Orm).to receive(:save) { true }
          allow(persistence).to receive(:update_needs_index?) { false }
          allow(persistence).to receive(:update_modified_date)
        end

        it "does not override `update_needs_index?'" do
          expect(persistence).to_not receive(:update_index)
          persistence.save(update_index: true)
        end
      end
    end
  end
end
