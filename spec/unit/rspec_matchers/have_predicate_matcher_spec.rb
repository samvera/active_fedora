require "spec_helper"
require 'ostruct'
require "active_fedora/rspec_matchers/have_predicate_matcher"

describe RSpec::Matchers, ".have_predicate" do
  let(:open_struct) { OpenStruct.new(id: id) }
  let(:id) { 123 }
  let(:object1) { Object.new }
  let(:object2) { Object.new }
  let(:object3) { Object.new }
  let(:predicate) { :predicate }

  it 'matches when relationship is "what we have in Fedora"' do
    expect(open_struct.class).to receive(:find).with(id).and_return(open_struct)
    expect(open_struct).to receive(:relationships).with(predicate).and_return([object1, object2])
    expect(open_struct).to have_predicate(predicate).with_objects([object1, object2])
  end

  it 'does not match when relationship is different' do
    expect(open_struct.class).to receive(:find).with(id).and_return(open_struct)
    expect(open_struct).to receive(:relationships).with(predicate).and_return([object1, object3])
    expect {
      expect(open_struct).to have_predicate(predicate).with_objects([object1, object2])
    }.to raise_error RSpec::Expectations::ExpectationNotMetError,
                     /expected #{open_struct.class} ID=#{id} relationship: #{predicate.inspect}/
  end

  it 'requires :with_objects option' do
    expect {
      expect(open_struct).to have_predicate(predicate)
    }.to(
      raise_error(
        ArgumentError,
        "expect(subject).to have_predicate(<predicate>).with_objects(<objects[]>)"
      )
    )
  end
end
