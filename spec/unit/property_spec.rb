require 'spec_helper'

require 'active_fedora'
require 'active_fedora/model'

describe ActiveFedora::Property do
  
  before(:each) do
    @test_property = ActiveFedora::Property.new(double("model_stub"),"file_name", :string)
  end
  
  it 'should provide .new' do
    expect(ActiveFedora::Property).to respond_to(:new)
  end

  it 'should provide .name' do
    expect(ActiveFedora::Property).to respond_to(:name)
  end

  
  it 'should provide .instance_variable_name' do
    expect(@test_property).to respond_to(:instance_variable_name)
  end

  describe '.instance_variable_name' do
    it 'should return the value of the name attribute with an @ appended' do
      expect(@test_property.instance_variable_name).to eql("@#{@test_property.name}")
    end
  end
  
end
