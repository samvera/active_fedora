require 'spec_helper'

describe ActiveFedora::Attributes::Serializers do
  subject { ActiveFedora::Base }
  describe "serialize to integer" do
    it "should cast to integer" do
      subject.coerce_to_integer("0").should == 0
      subject.coerce_to_integer("01").should == 1
      subject.coerce_to_integer("seven").should == 0 # same as "seven".to_i => 0
      subject.coerce_to_integer("007seven").should == 7 # same as "007seven".to_i => 7
      subject.coerce_to_integer("").should be_nil
      subject.coerce_to_integer(nil).should be_nil
      subject.coerce_to_integer("", :default=>7).should == 7
      subject.coerce_to_integer(nil, :default=>7).should == 7
      subject.coerce_to_integer("9", :default=>7).should == 9
    end
  end

  describe "serialize to date" do
    it "should cast to date" do
      subject.coerce_to_date("30/10/2010").should == Date.parse('2010-10-30') # ruby interprets this as DD/MM/YYYY
      subject.coerce_to_date("2010-01-31").should == Date.parse('2010-01-31')
    end
    it "should handle invalid dates" do
      subject.coerce_to_date("0").should == nil #
      subject.coerce_to_date("01/15/2010").should == nil # ruby interprets this as DD/MM/YYYY
      subject.coerce_to_date("2010-31-01").should == nil
    end
    it "should work with a blank string" do
      subject.coerce_to_date("").should == nil
      subject.coerce_to_date("", :default=>:today).should be_kind_of Date
      subject.coerce_to_date("", :default=>Date.parse('2010-01-31')).should == Date.parse('2010-01-31')
    end
    it "should work when nil is passed in" do
      subject.coerce_to_date(nil).should == nil
      subject.coerce_to_date(nil, :default=>:today).should be_kind_of Date
      subject.coerce_to_date(nil, :default=>Date.parse('2010-01-31')).should == Date.parse('2010-01-31')
    end
  end
  describe "serialize to boolean" do
    it "should cast to bool" do
      subject.coerce_to_boolean("true").should be_true
      subject.coerce_to_boolean("false").should be_false
      subject.coerce_to_boolean("faoo").should be_false
      subject.coerce_to_boolean("").should be_false
      subject.coerce_to_boolean("", :default=>true).should be_true
      subject.coerce_to_boolean("", :default=>false).should be_false
      subject.coerce_to_boolean("x", :default=>true).should be_false
      subject.coerce_to_boolean("x", :default=>false).should be_false
      subject.coerce_to_boolean(nil, :default=>true).should be_true
      subject.coerce_to_boolean(nil, :default=>false).should be_false
    end
  end

  describe "deserialize_dates_from_form" do
    before do
      class Foo < ActiveFedora::Base
        attr_accessor :birthday
      end
    end
    after do
      Object.send(:remove_const, :Foo)
    end
    subject { Foo.new }
    it "should deserialize dates" do
      subject.attributes = {'birthday(1i)' =>'2012', 'birthday(2i)' =>'10', 'birthday(3i)' => '31'}
      subject.birthday.should == '2012-10-31'
    end
  end

end
