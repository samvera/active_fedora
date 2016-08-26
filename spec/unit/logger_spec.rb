require 'spec_helper'

describe ActiveFedora::Base do
  let(:logger1) { instance_double(::Logger, debug?: false) }

  before do
    @initial_logger = described_class.logger
    described_class.logger = logger1
  end

  after do
    described_class.logger = @initial_logger
  end

  it "Allows loggers to be set" do
    expect(logger1).to receive(:warn).with("Hey")
    described_class.new.logger.warn "Hey"
  end
end
