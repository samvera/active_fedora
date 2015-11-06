require 'spec_helper'

module SpecModel
  class Basic < ActiveFedora::Base
    class_attribute :callback_counter
    before_destroy :inc_counter

    def inc_counter
      self.class.callback_counter += 1
    end
  end
end

describe ActiveFedora::Base do

  let!(:model1) { SpecModel::Basic.create! }
  let!(:model2) { SpecModel::Basic.create! }

  before :each do
    SpecModel::Basic.callback_counter = 0
  end

  describe '.destroy_all' do
    it 'should remove both and run callbacks' do
      model1
      model2
      SpecModel::Basic.count.should == 2
      SpecModel::Basic.callback_counter.should == 0
      SpecModel::Basic.destroy_all
      SpecModel::Basic.count.should == 0
      SpecModel::Basic.callback_counter.should == 2
    end

    describe 'when a model is missing' do
      let(:model3) { SpecModel::Basic.create! }
      after { model3.delete }
      it 'should be able to skip a missing model' do
        model1.should_receive(:destroy).and_call_original
        model2.should_receive(:destroy).and_call_original
        model3.should_receive(:destroy).and_raise(ActiveFedora::ObjectNotFoundError)
        ActiveFedora::Relation.any_instance.should_receive(:to_a).and_return([model1, model3, model2])
        ActiveFedora::Relation.logger.should_receive(:error).with("When trying to destroy #{model3.pid}, encountered an ObjectNotFoundError. Solr may be out of sync with Fedora")
        SpecModel::Basic.destroy_all
        SpecModel::Basic.count.should == 1
      end
    end
  end

  describe '.delete_all' do
    it 'should remove both and not run callbacks' do
      SpecModel::Basic.delete_all
      SpecModel::Basic.count.should == 0
      SpecModel::Basic.callback_counter.should == 0
    end
  end
end
