require 'spec_helper'

require 'active_fedora'
require 'active_fedora/model'

describe ActiveFedora::Property do

  before :each do
    mstub = double('model_stub')
    @test_property = ActiveFedora::Property.new(mstub, 'file_name', :string)
  end

  it 'should provide .new and .name' do
    expect(ActiveFedora::Property).to respond_to(:new)
    expect(ActiveFedora::Property).to respond_to(:name)
  end

  describe '.instance_variable_name' do
    it 'should return the value of the name attribute with an @ appended' do
      expect(@test_property).to respond_to(:instance_variable_name)
      expect(@test_property.instance_variable_name).to eql("@#{@test_property.name}")
    end
  end

end
