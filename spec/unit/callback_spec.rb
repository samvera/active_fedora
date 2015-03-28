require 'spec_helper'

describe ActiveFedora::Base do
  before :each do
    begin
      ActiveFedora::Base.find('test:123').delete
    rescue
    end

    class CallbackStub < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :fubar, :swank, datastream: 'someData', multiple: true
      end

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
  after :each do
    @cb.destroy if @cb && @cb.persisted?# this only is called if the test failed to run all the way through.
    Object.send(:remove_const, :CallbackStub)
  end

  it "Should have after_initialize, before_save,after_save, before_create, after_create, after_update, before_update, before_destroy" do
    allow_any_instance_of(CallbackStub).to receive(:a_init)
    allow_any_instance_of(CallbackStub).to receive :b_create
    allow_any_instance_of(CallbackStub).to receive :a_create
    allow_any_instance_of(CallbackStub).to receive(:b_save)
    allow_any_instance_of(CallbackStub).to receive(:a_save)
    @cb = CallbackStub.new 'test:123'
    @cb.save
  end

  it "Should have after_initialize, before_save,after_save, before_create, after_create, after_update, before_update, before_destroy" do
    allow_any_instance_of(CallbackStub).to receive(:a_init)
    allow_any_instance_of(CallbackStub).to receive(:b_create)
    allow_any_instance_of(CallbackStub).to receive(:a_create)
    allow_any_instance_of(CallbackStub).to receive(:b_save)
    allow_any_instance_of(CallbackStub).to receive(:a_save)
    @cb = CallbackStub.new 'test:123'
    @cb.save
    allow_any_instance_of(CallbackStub).to receive(:a_init)
    allow_any_instance_of(CallbackStub).to receive(:b_save)
    allow_any_instance_of(CallbackStub).to receive(:a_save)
    allow_any_instance_of(CallbackStub).to receive(:a_find)
    allow_any_instance_of(CallbackStub).to receive(:b_update)
    allow_any_instance_of(CallbackStub).to receive(:a_update)
    allow_any_instance_of(CallbackStub).to receive(:do_stuff)

    @cb = CallbackStub.find('test:123')
    @cb.save!

    @cb.destroy

  end
end
