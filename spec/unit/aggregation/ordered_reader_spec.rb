require 'spec_helper'

RSpec.describe ActiveFedora::Aggregation::OrderedReader do
  subject(:ordered_reader) { described_class.new(root) }
  let(:root) { instance_double(ActiveFedora::Aggregation::ListSource) }

  describe "#each" do
    it "iterates a linked list" do
      head = build_node
      tail = build_node(prev_node: head)
      allow(head).to receive(:next).and_return(tail)
      allow(root).to receive(:head).and_return(head)
      expect(ordered_reader.to_a).to eq [head, tail]
    end
    it "only goes as deep as necessary" do
      head = build_node
      tail = build_node(prev_node: head)
      allow(head).to receive(:next).and_return(tail)
      allow(root).to receive(:head).and_return(head)
      expect(ordered_reader.first).to eq head
      expect(head).not_to have_received(:next)
    end
    context "when the prev is wrong" do
      it "fixes it up" do
        head = build_node
        bad_node = build_node
        tail = build_node(prev_node: bad_node)
        allow(head).to receive(:next).and_return(tail)
        allow(root).to receive(:head).and_return(head)
        allow(tail).to receive(:prev=)
        expect(ordered_reader.to_a).to eq [head, tail]
        expect(tail).to have_received(:prev=).with(head)
      end
    end
  end

  def build_node(prev_node: nil, next_node: nil)
    node = instance_double(ActiveFedora::Orders::ListNode)
    allow(node).to receive(:next).and_return(next_node)
    allow(node).to receive(:prev).and_return(prev_node)
    node
  end
end
