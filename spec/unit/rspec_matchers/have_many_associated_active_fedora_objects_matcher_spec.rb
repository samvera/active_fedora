require "spec_helper"
require 'ostruct'
require "active_fedora/rspec_matchers/have_many_associated_active_fedora_objects_matcher"

describe RSpec::Matchers, "have_many_associated_active_fedora_objects_matcher" do
  subject { OpenStruct.new(:pid => pid )}
  let(:pid) { 123 }
  let(:object1) { Object.new }
  let(:object2) { Object.new }
  let(:object3) { Object.new }
  let(:association) { :association }

  it 'should match when association is properly stored in fedora' do
    subject.class.should_receive(:find).with(pid).and_return(subject)
    subject.should_receive(association).and_return([object1,object2])
    subject.should have_many_associated_active_fedora_objects(association).with_objects([object1, object2])
  end

  it 'should not match when association is different' do
    subject.class.should_receive(:find).with(pid).and_return(subject)
    subject.should_receive(association).and_return([object1,object3])
    lambda {
      subject.should have_many_associated_active_fedora_objects(association).with_objects([object1, object2])
    }.should (
      raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /expected #{subject.class} PID=#{pid} association: #{association.inspect}/
      )
    )
  end

  it 'should require :with_objects option' do
    lambda {
      subject.should have_many_associated_active_fedora_objects(association)
    }.should(
      raise_error(
        ArgumentError,
        "subject.should have_many_associated_active_fedora_objects(<association_name>).with_objects(<objects[]>)"
      )
    )
  end
end
