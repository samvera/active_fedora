require 'spec_helper'

describe ActiveFedora::Base do
  before do
    @test_object = described_class.new
  end

  describe '.save' do
    it "adds hasModel relationship that points to the CModel if @new_object" do
      allow(@test_object).to receive(:update_index)
      expect(@test_object).to receive(:refresh)
      @test_object.save
    end
  end
end
