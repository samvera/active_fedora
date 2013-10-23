require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class ValidationStub < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      has_attributes :fubar, datastream: 'someData', multiple: true
      has_attributes :swank, datastream: 'someData', multiple: false

      validates_presence_of :fubar
      validates_length_of :swank, :minimum=>5
      
    end
  end

  subject { ValidationStub.new }

  after :all do
    Object.send(:remove_const, :ValidationStub)
  end

  describe "a valid object" do
    before do
      subject.attributes={ fubar:'here', swank:'long enough'}
    end
    
    it { should be_valid}
  end
  describe "an invalid object" do
    before do
      subject.attributes={ swank:'smal'}
    end
    it "should have errors" do
      subject.should_not be_valid
      subject.errors[:fubar].should == ["can't be blank"]
      subject.errors[:swank].should == ["is too short (minimum is 5 characters)"]
    end
  end

  describe "required terms" do
    it "should be required" do
       subject.required?(:fubar).should be_true
       subject.required?(:swank).should be_false
    end
  end

end
