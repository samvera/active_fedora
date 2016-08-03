require 'spec_helper'

describe "Checking fixity" do
  before(:all) do
    class MockAFBase < ActiveFedora::Base
      has_subresource "data", autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
  end

  subject do
    obj = MockAFBase.create
    obj.data.content = "some content"
    obj.save
    obj.data.check_fixity
  end

  context "with a valid resource" do
    it { is_expected.to be true }
  end
  context "when no uri has been set" do
    subject(:file) { ActiveFedora::File.new }
    it "raises an error" do
      expect { file.check_fixity }.to raise_error(ArgumentError, "You must provide a uri")
    end
  end
  context "with missing resource" do
    subject(:file) { ActiveFedora::File.new(ActiveFedora::Base.id_to_uri('123')) }
    it "raises an error" do
      expect { file.check_fixity }.to raise_error(Ldp::NotFound)
    end
  end
end
