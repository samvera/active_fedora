require 'spec_helper'

RSpec.describe ActiveFedora::Reflection::OrdersReflection do
  let(:orders_reflection) { described_class.new(name, scope, options, active_fedora) }
  let(:macro) { :orders }
  let(:name) { "ordered_member_proxies" }
  let(:options) { {} }
  let(:scope) { nil }
  let(:active_fedora) { instance_double(ActiveFedora::Base) }

  describe "#klass" do
    it "is a proxy" do
      expect(orders_reflection.klass).to eq ActiveFedora::Orders::ListNode
    end
  end

  describe "#class_name" do
    it "is a list node" do
      expect(orders_reflection.class_name).to eq "ActiveFedora::Orders::ListNode"
    end
  end
end
