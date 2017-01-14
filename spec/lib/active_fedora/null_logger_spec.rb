require 'spec_helper'

RSpec.describe ActiveFedora::NullLogger do
  [:debug?, :info?, :warn?, :error?, :fatal?].each do |method_name|
    describe "##{method_name}" do
      subject { described_class.new.public_send(method_name) }
      it { is_expected.to be_falsey }
    end
  end
end
