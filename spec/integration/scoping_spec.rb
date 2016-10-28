require 'spec_helper'

describe ActiveFedora::Scoping::Named do
  before do
    class TestClass < ActiveFedora::Base
    end
  end
  let!(:test_instance) { TestClass.create! }

  after do
    test_instance.delete
    Object.send(:remove_const, :TestClass)
  end

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
    describe "#find with a valid id without cast" do
      subject { ActiveFedora::Base.find(test_instance.id) }
      it { is_expected.to be_instance_of TestClass }
    end
    describe "#find with a valid id with cast of false" do
      subject { ActiveFedora::Base.find(test_instance.id, cast: false) }
      it { is_expected.to be_instance_of ActiveFedora::Base }
    end

    describe "#find with a valid id without cast on a model extending Base" do
      subject { TestClass.find(test_instance.id) }
      it { is_expected.to be_instance_of TestClass }
    end
  end
end
