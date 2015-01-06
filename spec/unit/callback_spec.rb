require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class CallbackStub < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      delegate :fubar, :to=>'someData'
      delegate :swank, :to=>'someData'

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
    expect_any_instance_of(CallbackStub).to receive(:a_init)
    expect_any_instance_of(CallbackStub).to receive :b_create
    expect_any_instance_of(CallbackStub).to receive :a_create
    expect_any_instance_of(CallbackStub).to receive(:b_save)
    expect_any_instance_of(CallbackStub).to receive(:a_save)
    cb = CallbackStub.new :pid => 'test:123'
    cb.save
end
 it "Should have after_initialize, before_save,after_save, before_create, after_create, after_update, before_update, before_destroy" do
    expect_any_instance_of(CallbackStub).to receive(:a_init)
    expect_any_instance_of(CallbackStub).to receive(:b_save)
    expect_any_instance_of(CallbackStub).to receive(:a_save)
    expect_any_instance_of(CallbackStub).to receive(:a_find)
    expect_any_instance_of(CallbackStub).to receive(:b_update)
    expect_any_instance_of(CallbackStub).to receive(:a_update)
    expect_any_instance_of(CallbackStub).to receive(:do_stuff)

    cb2 = CallbackStub.find('test:123')
    cb2.save

    cb2.destroy
  end
end
