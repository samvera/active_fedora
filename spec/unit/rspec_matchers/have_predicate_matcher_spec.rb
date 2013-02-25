require "spec_helper"
require 'ostruct'
require "active_fedora/rspec_matchers/have_predicate_matcher"

describe RSpec::Matchers, "have_predicate_matcher" do
  subject { OpenStruct.new(:pid => pid )}
  let(:pid) { 123 }
  let(:object1) { Object.new }
  let(:object2) { Object.new }
  let(:object3) { Object.new }
  let(:predicate) { :predicate }

  it 'should match when relationship is "what we have in Fedora"' do
    subject.class.should_receive(:find).with(pid).and_return(subject)
    subject.should_receive(:relationships).with(predicate).and_return([object1,object2])
    subject.should have_predicate(predicate).with_objects([object1, object2])
  end

  it 'should not match when relationship is different' do
    subject.class.should_receive(:find).with(pid).and_return(subject)
    subject.should_receive(:relationships).with(predicate).and_return([object1,object3])
    lambda {
      subject.should have_predicate(predicate).with_objects([object1, object2])
    }.should (
      raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /expected #{subject.class} PID=#{pid} relationship: #{predicate.inspect}/
      )
    )
  end

  it 'should require :with_objects option' do
    lambda {
      subject.should have_predicate(predicate)
    }.should(
      raise_error(
        ArgumentError,
        "subject.should have_predicate(<predicate>).with_objects(<objects[]>)"
      )
    )
  end
end
