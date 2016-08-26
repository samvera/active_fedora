require 'spec_helper'

describe ActiveFedora::Property do
  before do
    @test_property = described_class.new(instance_double(ActiveFedora::Base), "file_name", :string)
  end

  it 'provides .new' do
    expect(described_class).to respond_to(:new)
  end

  it 'provides .name' do
    expect(described_class).to respond_to(:name)
  end

  it 'provides .instance_variable_name' do
    expect(@test_property).to respond_to(:instance_variable_name)
  end

  describe '.instance_variable_name' do
    it 'returns the value of the name attribute with an @ appended' do
      expect(@test_property.instance_variable_name).to eql("@#{@test_property.name}")
    end
  end
end
