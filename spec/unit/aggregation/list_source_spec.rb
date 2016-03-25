require 'spec_helper'

RSpec.describe ActiveFedora::Aggregation::ListSource do
  subject { described_class.new }
  
  describe "#head" do
    it "should be nil by default" do
      expect(subject.head).to eq nil
    end

    it "is settable" do
      subject.head = RDF::URI("test.org")

      expect(subject.head_id.first).to eq RDF::URI("test.org")
    end

    it "maps to IANA.first" do
      expect(subject.class.properties["head"].predicate).to eq ::RDF::Vocab::IANA["first"]
    end
  end

  describe "#order_will_change!" do
    it "marks it as changed" do
      expect(subject).not_to be_changed
      subject.order_will_change!
      expect(subject).to be_changed
      expect(subject.ordered_self).to be_changed
    end
  end

  describe "#tail" do
    it "should be nil by default" do
      expect(subject.tail).to eq nil
    end

    it "is settable" do
      subject.tail = RDF::URI("test.org")

      expect(subject.tail_id.first).to eq RDF::URI("test.org")
    end

    it "maps to IANA.last" do
      expect(subject.class.properties["tail"].predicate).to eq ::RDF::Vocab::IANA["last"]
    end
  end

  describe "#changed?" do
    context "when nothing has changed" do
      it "is false" do
        expect(subject).not_to be_changed
      end
    end
    context "when the ordered list is changed" do
      it "is true" do
        allow(subject.ordered_self).to receive(:changed?).and_return(true)

        expect(subject).to be_changed
      end
    end
    context "when the ordered list is not changed" do
      it "is false" do
        allow(subject.ordered_self).to receive(:changed?).and_return(false)

        expect(subject).not_to be_changed
      end
    end
  end

  describe "#save" do
    context "when nothing has changed" do
      it "does not persist ordered_self" do
        allow(subject.ordered_self).to receive(:to_graph)

        subject.save

        expect(subject.ordered_self).not_to have_received(:to_graph)
      end
    end
    context "when attributes have changed, but not ordered list" do
      it "does not persist ordered self" do
        allow(subject.ordered_self).to receive(:to_graph)
        subject.nodes += [RDF::URI("http://test.org")]

        subject.save

        expect(subject.ordered_self).not_to have_received(:to_graph)
      end
    end
    context "when ordered list has changed" do
      it "should persist it" do
        allow(subject.ordered_self).to receive(:to_graph).and_call_original
        allow(subject.ordered_self).to receive(:changed?).and_return(true)

        subject.save

        expect(subject.ordered_self).to have_received(:to_graph)
      end
    end
  end

  describe "#serializable_hash" do
    it "does not serialize nodes" do
      subject.nodes += [RDF::URI("http://test.org")]

      expect(subject.serializable_hash).not_to have_key "nodes"
    end
    it "does not serialize head" do
      subject.head = RDF::URI("http://test.org")

      expect(subject.serializable_hash).not_to have_key "head"
    end
    it "does not serialize tail" do
      subject.tail = RDF::URI("http://test.org")

      expect(subject.serializable_hash).not_to have_key "tail"
    end
  end

  describe "#to_solr" do
    before do
      class Member < ActiveFedora::Base
      end
    end
    after do
      Object.send(:remove_const, :Member)
    end
    it "can index" do
      m = Member.create
      proxy_in = RDF::URI(ActiveFedora::Base.translate_id_to_uri.call("banana"))
      subject.ordered_self.append_target m, proxy_in: proxy_in
      expect(subject.to_solr).to include (
        {
          ordered_targets_ssim: [m.id],
          proxy_in_ssi: "banana"
        }
      )
    end
  end
end
