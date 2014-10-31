require "spec_helper"
require 'ostruct'
require "active_fedora/rspec_matchers/have_many_associated_active_fedora_objects_matcher"

describe RSpec::Matchers, "have_many_associated_active_fedora_objects_matcher" do
  subject { OpenStruct.new(:id => id )}
  let(:id) { 123 }
  let(:object1) { Object.new }
  let(:object2) { Object.new }
  let(:object3) { Object.new }
  let(:association) { :association }

  it 'should match when association is properly stored in fedora' do
    expect(subject.class).to receive(:find).with(id).and_return(subject)
    expect(subject).to receive(association).and_return([object1,object2])
    expect(subject).to have_many_associated_active_fedora_objects(association).with_objects([object1, object2])
  end

  it 'should not match when association is different' do
    expect(subject.class).to receive(:find).with(id).and_return(subject)
    expect(subject).to receive(association).and_return([object1,object3])
    expect {
      expect(subject).to have_many_associated_active_fedora_objects(association).with_objects([object1, object2])
    }.to (
      raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /expected #{subject.class} ID=#{id} association: #{association.inspect}/
      )
    )
  end

  it 'should require :with_objects option' do
    expect {
      expect(subject).to have_many_associated_active_fedora_objects(association)
    }.to(
      raise_error(
        ArgumentError,
          "expect(subject).to have_many_associated_active_fedora_objects(<association_name>).with_objects(<objects[]>)"
      )
    )
  end
end
