require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end
  
  describe '.save' do

    it "should add hasModel relationship that points to the CModel if @new_object" do
      @test_object.stubs(:update_index)
      @test_object.expects(:refresh)
      @test_object.save
    end
  end

end
