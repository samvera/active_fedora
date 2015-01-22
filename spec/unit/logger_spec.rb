require 'spec_helper'

describe ActiveFedora::Base do
  let(:logger1) { double(debug?: false) }

  before do
    @initial_logger = ActiveFedora::Base.logger
    ActiveFedora::Base.logger = logger1
  end

  after do
    ActiveFedora::Base.logger = @initial_logger
  end

  it "Allows loggers to be set" do
    expect(logger1).to receive(:warn).with("Hey")
    ActiveFedora::Base.new.logger.warn "Hey"

  end
end
