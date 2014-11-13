require 'spec_helper'

describe "Checking fixity" do

  before(:all) do
    class MockAFBase < ActiveFedora::Base
      contains "data", autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
  end

  subject do
    obj = MockAFBase.create
    obj.data.content = "some content"
    obj.save
    obj.data
  end

  context "with a valid resource" do
    it "should return true for a successful fixity check" do
      expect(subject.check_fixity).to be true
    end
  end
  context "with missing resource" do
    let(:parent) { ActiveFedora::Base.new(id: '1234') }
    subject { ActiveFedora::File.new(parent, 'abcd') }
    it "should raise an error" do
      expect { subject.check_fixity }.to raise_error(Ldp::NotFound)
    end
  end

end
