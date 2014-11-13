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
  context "when no uri has been set" do
    subject { ActiveFedora::File.new }
    it "should raise an error" do
      expect { subject.check_fixity }.to raise_error(ArgumentError, "You must provide a uri")
    end
  end
  context "with missing resource" do
    subject { ActiveFedora::File.new(ActiveFedora::Base.id_to_uri('123')) }
    it "should raise an error" do
      expect { subject.check_fixity }.to raise_error(Ldp::NotFound)
    end
  end

end
