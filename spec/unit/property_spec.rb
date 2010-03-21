require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'active_fedora/model'
require 'mocha'
include Mocha::Standalone

describe ActiveFedora::Property do
  
  before(:all) do
    @test_property = ActiveFedora::Property.new(stub("model_stub"),"file_name", :string)
  end
  
  it 'should provide .new' do
    ActiveFedora::Property.should respond_to(:new)
  end

  describe '.new' do
    
    it 'should use assertions to check types of incoming args'
    
    # This could rely on property_set and in turn serialize to a 'properties' metadata datastream...
    it 'should add corresponding field to the properties datastream'
      
    it 'should add field to repository indexer (ie. solr)'
  end
  
  it 'should provide .name' do
    ActiveFedora::Property.should respond_to(:name)
  end

  describe '.name' do
    it 'should return the value of the name attribute' do
      
    end
  end
  
  it 'should provide .instance_variable_name' do
    #ActiveFedora::Property.should respond_to(:instance_variable_name)
    
    @test_property.should respond_to(:instance_variable_name)
  end

  describe '.instance_variable_name' do
    it 'should return the value of the name attribute with an @ appended' do
      @test_property.instance_variable_name.should eql("@#{@test_property.name}")
    end
  end
  
end
