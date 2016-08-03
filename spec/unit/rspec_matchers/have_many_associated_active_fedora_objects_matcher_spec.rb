require "spec_helper"
require 'ostruct'
require "active_fedora/rspec_matchers/have_many_associated_active_fedora_objects_matcher"

describe RSpec::Matchers, ".have_many_associated_active_fedora_objects" do
  let(:open_struct) { OpenStruct.new(id: id) }
  let(:id) { 123 }
  let(:object1) { Object.new }
  let(:object2) { Object.new }
  let(:object3) { Object.new }
  let(:association) { :association }

  it 'matches when association is properly stored in fedora' do
    expect(open_struct.class).to receive(:find).with(id).and_return(open_struct)
    expect(open_struct).to receive(association).and_return([object1, object2])
    expect(open_struct).to have_many_associated_active_fedora_objects(association).with_objects([object1, object2])
  end

  it 'does not match when association is different' do
    expect(open_struct.class).to receive(:find).with(id).and_return(open_struct)
    expect(open_struct).to receive(association).and_return([object1, object3])
    expect {
      expect(open_struct).to have_many_associated_active_fedora_objects(association).with_objects([object1, object2])
    }.to raise_error RSpec::Expectations::ExpectationNotMetError,
                     /expected #{open_struct.class} ID=#{id} association: #{association.inspect}/
  end

  it 'requires :with_objects option' do
    expect {
      expect(open_struct).to have_many_associated_active_fedora_objects(association)
    }.to(
      raise_error(
        ArgumentError,
        "expect(subject).to have_many_associated_active_fedora_objects(<association_name>).with_objects(<objects[]>)"
      )
    )
  end
end
