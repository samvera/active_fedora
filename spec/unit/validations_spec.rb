require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class ValidationStub < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      delegate :fubar, :to=>'someData'
      delegate :swank, :to=>'someData'

      validates_presence_of :fubar
      validates_length_of :swank, :minimum=>5
      
    end
  end
  after :all do
    Object.send(:remove_const, :ValidationStub)
  end

  describe "a valid object" do
    before do
      @obj = ValidationStub.new(:fubar=>'here', :swank=>'long enough')
    end
    
    it "should be valid" do
      @obj.should_not be_valid
    end
  end
  describe "an invalid object" do
    before do
      @obj = ValidationStub.new(:swank=>'smal')
    end
    
    it "should be invalid" do
      @obj.should_not be_valid
      @obj.errors[:fubar].should == ["can't be blank"]
      @obj.errors[:swank].should == ["is too short (minimum is 5 characters)"]
    end
  end

end
