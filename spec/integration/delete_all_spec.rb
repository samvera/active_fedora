require 'spec_helper'

module SpecModelD
  class Basic < ActiveFedora::Base
    class_attribute :callback_counter
    before_destroy :inc_counter

    def inc_counter
      self.class.callback_counter += 1
    end
  end
end

describe ActiveFedora::Base do

  let!(:model1) { SpecModelD::Basic.create! }
  let!(:model2) { SpecModelD::Basic.create! }

  before :each do
    SpecModelD::Basic.callback_counter = 0
  end

  describe '.destroy_all' do
    it 'should remove both and run callbacks' do
      model1
      model2
      expect(SpecModelD::Basic.count).to eq(2)
      expect(SpecModelD::Basic.callback_counter).to eq(0)
      SpecModelD::Basic.destroy_all
      expect(SpecModelD::Basic.count).to eq(0)
      expect(SpecModelD::Basic.callback_counter).to eq(2)
    end

    describe 'when a model is missing' do
      let(:model3) { SpecModelD::Basic.create! }
      after { model3.delete }
      it 'should be able to skip a missing model' do
        expect(model1).to receive(:destroy).and_call_original
        expect(model2).to receive(:destroy).and_call_original
        expect(model3).to receive(:destroy).and_raise(ActiveFedora::ObjectNotFoundError)
        expect_any_instance_of(ActiveFedora::Relation).to receive(:to_a).and_return([model1, model3, model2])
        expect(ActiveFedora::Relation.logger).to receive(:error).with("When trying to destroy #{model3.pid}, encountered an ObjectNotFoundError. Solr may be out of sync with Fedora")
        SpecModelD::Basic.destroy_all
        expect(SpecModelD::Basic.count).to eq(1)
      end
    end
  end

  describe '.delete_all' do
    it 'should remove both and not run callbacks' do
      SpecModelD::Basic.delete_all
      expect(SpecModelD::Basic.count).to eq(0)
      expect(SpecModelD::Basic.callback_counter).to eq(0)
    end
  end
end
