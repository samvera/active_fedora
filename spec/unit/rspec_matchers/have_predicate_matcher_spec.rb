require "spec_helper"
require 'ostruct'
require "active_fedora/rspec_matchers/have_predicate_matcher"

describe RSpec::Matchers, "have_predicate_matcher" do
  subject { OpenStruct.new(:id => id )}
  let(:id) { 123 }
  let(:object1) { Object.new }
  let(:object2) { Object.new }
  let(:object3) { Object.new }
  let(:predicate) { :predicate }

  it 'should match when relationship is "what we have in Fedora"' do
    expect(subject.class).to receive(:find).with(id).and_return(subject)
    expect(subject).to receive(:relationships).with(predicate).and_return([object1,object2])
    expect(subject).to have_predicate(predicate).with_objects([object1, object2])
  end

  it 'should not match when relationship is different' do
    expect(subject.class).to receive(:find).with(id).and_return(subject)
    expect(subject).to receive(:relationships).with(predicate).and_return([object1,object3])
    expect {
      expect(subject).to have_predicate(predicate).with_objects([object1, object2])
    }.to (
      raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /expected #{subject.class} ID=#{id} relationship: #{predicate.inspect}/
      )
    )
  end

  it 'should require :with_objects option' do
    expect {
      expect(subject).to have_predicate(predicate)
    }.to(
      raise_error(
        ArgumentError,
          "expect(subject).to have_predicate(<predicate>).with_objects(<objects[]>)"
      )
    )
  end
end
