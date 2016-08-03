require 'spec_helper'

RSpec.describe ActiveFedora::Aggregation::ListSource do
  subject(:list_source) { described_class.new }

  describe "#head" do
    it "is nil by default" do
      expect(list_source.head).to eq nil
    end

    it "is settable" do
      list_source.head = RDF::URI("test.org")

      expect(list_source.head_id.first).to eq RDF::URI("test.org")
    end

    it "maps to IANA.first" do
      expect(list_source.class.properties["head"].predicate).to eq ::RDF::Vocab::IANA["first"]
    end
  end

  describe "#order_will_change!" do
    it "marks it as changed" do
      expect(list_source).not_to be_changed
      list_source.order_will_change!
      expect(list_source).to be_changed
      expect(list_source.ordered_self).to be_changed
    end
  end

  describe "#tail" do
    it "is nil by default" do
      expect(list_source.tail).to eq nil
    end

    it "is settable" do
      list_source.tail = RDF::URI("test.org")

      expect(list_source.tail_id.first).to eq RDF::URI("test.org")
    end

    it "maps to IANA.last" do
      expect(list_source.class.properties["tail"].predicate).to eq ::RDF::Vocab::IANA["last"]
    end
  end

  describe "#changed?" do
    context "when nothing has changed" do
      it "is false" do
        expect(list_source).not_to be_changed
      end
    end
    context "when the ordered list is changed" do
      it "is true" do
        allow(list_source.ordered_self).to receive(:changed?).and_return(true)

        expect(list_source).to be_changed
      end
    end
    context "when the ordered list is not changed" do
      it "is false" do
        allow(list_source.ordered_self).to receive(:changed?).and_return(false)

        expect(list_source).not_to be_changed
      end
    end
  end

  describe "#save" do
    context "when nothing has changed" do
      it "does not persist ordered_self" do
        allow(list_source.ordered_self).to receive(:to_graph)

        list_source.save

        expect(list_source.ordered_self).not_to have_received(:to_graph)
      end
    end
    context "when attributes have changed, but not ordered list" do
      it "does not persist ordered self" do
        allow(list_source.ordered_self).to receive(:to_graph)
        list_source.nodes += [RDF::URI("http://test.org")]

        list_source.save

        expect(list_source.ordered_self).not_to have_received(:to_graph)
      end
    end
    context "when ordered list has changed" do
      it "persists it" do
        allow(list_source.ordered_self).to receive(:to_graph).and_call_original
        allow(list_source.ordered_self).to receive(:changed?).and_return(true)

        list_source.save

        expect(list_source.ordered_self).to have_received(:to_graph)
      end
    end
  end

  describe "#serializable_hash" do
    it "does not serialize nodes" do
      list_source.nodes += [RDF::URI("http://test.org")]

      expect(list_source.serializable_hash).not_to have_key "nodes"
    end
    it "does not serialize head" do
      list_source.head = RDF::URI("http://test.org")

      expect(list_source.serializable_hash).not_to have_key "head"
    end
    it "does not serialize tail" do
      list_source.tail = RDF::URI("http://test.org")

      expect(list_source.serializable_hash).not_to have_key "tail"
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
      list_source.ordered_self.append_target m, proxy_in: proxy_in
      expect(list_source.to_solr).to include ordered_targets_ssim: [m.id], proxy_in_ssi: "banana"
    end
  end
end
