require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class CallbackStub < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      has_attributes :fubar, :swank, datastream: 'someData', multiple: true

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
  after :all do
    Object.send(:remove_const, :CallbackStub)
  end

  it "Should have after_initialize, before_save,after_save, before_create, after_create, after_update, before_update, before_destroy" do
    CallbackStub.any_instance.should_receive(:a_init)
    CallbackStub.any_instance.should_receive :b_create
    CallbackStub.any_instance.should_receive :a_create
    CallbackStub.any_instance.should_receive(:b_save)
    CallbackStub.any_instance.should_receive(:a_save)
    cb = CallbackStub.new :pid => 'test:123'
    cb.save
end
 it "Should have after_initialize, before_save,after_save, before_create, after_create, after_update, before_update, before_destroy" do
    CallbackStub.any_instance.should_receive(:a_init)
    CallbackStub.any_instance.should_receive(:b_save)
    CallbackStub.any_instance.should_receive(:a_save)
    CallbackStub.any_instance.should_receive(:a_find)
    CallbackStub.any_instance.should_receive(:b_update)
    CallbackStub.any_instance.should_receive(:a_update)
    CallbackStub.any_instance.should_receive(:do_stuff)

    cb2 = CallbackStub.find('test:123')
    cb2.save

    cb2.destroy
  end
end
