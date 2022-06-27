# frozen_string_literal: true
require 'spec_helper'

describe ActiveFedora::Scoping::Named do
  before(:all) do
    class TestClass < ActiveFedora::Base; end
    class OtherClass < ActiveFedora::Base; end
  end
  after(:all) do
    Object.send(:remove_const, :TestClass)
    Object.send(:remove_const, :OtherClass)
  end

  let!(:test_instance) { TestClass.create! }
  after { test_instance.delete }

  describe "#all" do
    it "returns an array of instances of the calling Class" do
      result = TestClass.all.to_a
      expect(result).to be_instance_of(Array)
      # this test is meaningless if the array length is zero
      expect(result).to_not be_empty
      result.each do |obj|
        expect(obj.class).to eq TestClass
      end
    end
  end

  describe '#find' do
    describe "a valid id without cast" do
      subject { ActiveFedora::Base.find(test_instance.id) }
      it { is_expected.to be_instance_of TestClass }
    end
    describe "a valid id with cast of false" do
      subject { ActiveFedora::Base.find(test_instance.id, cast: false) }
      it { is_expected.to be_instance_of ActiveFedora::Base }
    end
    describe "a valid id without cast on a model extending Base" do
      subject { TestClass.find(test_instance.id) }
      it { is_expected.to be_instance_of TestClass }
    end
    it "a valid id on an incompatible class raises ModelMismatch" do
      expect { OtherClass.find(test_instance.id) }.to raise_error(ActiveFedora::ModelMismatch)
    end
    it "invalid id raises ObjectNotFoundError" do
      expect { TestClass.find('some_unused_identifier') }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end
  end
end
