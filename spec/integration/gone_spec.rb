require 'spec_helper'

describe ActiveFedora::Base do
  before(:all) do
    class ResurrectionModel < ActiveFedora::Base
      after_destroy :eradicate
    end
  end

  after(:all) do
    Object.send(:remove_const, :ResurrectionModel)
  end

  context "when an object is has already been deleted" do
    let(:ghost) do
      obj = described_class.create
      obj.destroy
      obj.id
    end
    it "is gone" do
      expect(described_class.gone?(ghost)).to be true
    end
  end

  context "when the id has never been used" do
    let(:id) { "abc123" }
    it "is not gone" do
      expect(described_class.gone?(id)).to be false
    end
  end

  context "when the id is in use" do
    let(:active) do
      obj = described_class.create
      obj.id
    end
    it "is not gone" do
      expect(described_class.gone?(active)).to be false
    end
  end
end
