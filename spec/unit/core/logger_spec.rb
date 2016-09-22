require 'spec_helper'

describe ActiveFedora::NullLogger do
  before { ActiveFedora::Base.logger = described_class.new }
  describe "::logger" do
    let(:logger) { ActiveFedora::Base.logger }
    it "when calling the logger" do
      expect(logger.warn("warning!")).to be_nil
    end
  end

  describe "#logger" do
    let(:logger) { ActiveFedora::Base.new.logger }
    it "when calling the logger" do
      expect(logger.warn("warning!")).to be_nil
    end
  end
end
