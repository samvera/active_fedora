require 'spec_helper'

RSpec.describe ActiveFedora::Orders::Reflection do
  subject { described_class.new(macro, name, scope, options, active_fedora) }
  let(:macro) { :orders }
  let(:name) { "ordered_member_proxies" }
  let(:options) { {} }
  let(:scope) { nil }
  let(:active_fedora) { double("active_fedora") }

  describe "#klass" do
    it "should be a proxy" do
      expect(subject.klass).to eq ActiveFedora::Orders::ListNode
    end
  end

  describe "#class_name" do
    it "should be a list node" do
      expect(subject.class_name).to eq "ActiveFedora::Orders::ListNode"
    end
  end
end
