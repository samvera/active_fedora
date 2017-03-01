require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class CallbackStub < ActiveFedora::Base
      after_initialize :a_init
      before_save :b_save
      after_save :a_save
      before_create :b_create
      after_create :a_create
      before_update :b_update
      after_update :a_update
      after_find :a_find

      before_destroy :do_stuff

      def do_stuff
        :noop
      end
    end
  end
  after do
    @cb.destroy if @cb && @cb.persisted? # this only is called if the test failed to run all the way through.
    Object.send(:remove_const, :CallbackStub)
  end

  it "has after_initialize, before_save, after_save, before_create, after_create" do
    allow_any_instance_of(CallbackStub).to receive(:a_init)
    allow_any_instance_of(CallbackStub).to receive :b_create
    allow_any_instance_of(CallbackStub).to receive :a_create
    allow_any_instance_of(CallbackStub).to receive(:b_save)
    allow_any_instance_of(CallbackStub).to receive(:a_save)
    @cb = CallbackStub.new
    @cb.save
  end

  it "has after_initialize, before_save, after_save, before_create, after_create, after_update, before_update, before_destroy" do
    allow_any_instance_of(CallbackStub).to receive(:a_init)
    allow_any_instance_of(CallbackStub).to receive(:b_create)
    allow_any_instance_of(CallbackStub).to receive(:a_create)
    allow_any_instance_of(CallbackStub).to receive(:b_save)
    allow_any_instance_of(CallbackStub).to receive(:a_save)
    @cb = CallbackStub.new
    @cb.save
    allow_any_instance_of(CallbackStub).to receive(:a_init)
    allow_any_instance_of(CallbackStub).to receive(:b_save)
    allow_any_instance_of(CallbackStub).to receive(:a_save)
    allow_any_instance_of(CallbackStub).to receive(:a_find)
    allow_any_instance_of(CallbackStub).to receive(:b_update)
    allow_any_instance_of(CallbackStub).to receive(:a_update)
    allow_any_instance_of(CallbackStub).to receive(:do_stuff)

    @cb = CallbackStub.find(@cb.id)
    @cb.save!

    @cb.destroy
  end
end
