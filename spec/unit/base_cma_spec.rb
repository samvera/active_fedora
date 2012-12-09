require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end
  
  describe '.save' do

    it "should add hasModel relationship that points to the CModel if @new_object" do
      @test_object.stub(:update_index)
      @test_object.should_receive(:refresh)
      @test_object.save
    end
  end

end
