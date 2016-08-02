require 'spec_helper'

RSpec.describe ActiveFedora::Orders::OrderedList do
  let(:ordered_list) { described_class.new(graph, head_uri, tail_uri) }

  let(:graph) { ActiveTriples::Resource.new(RDF::URI("stuff")) }
  let(:head_uri) { nil }
  let(:tail_uri) { nil }
  describe "#last" do
    context "with no nodes" do
      it "is nil" do
        expect(ordered_list.last).to eq nil
      end
    end
    context "with one node" do
      it "is that node" do
        member = instance_double(ActiveFedora::Base)
        ordered_list.append_target member

        expect(ordered_list.last.target).to eq member
      end
    end
    context "with two nodes" do
      it "is the last node" do
        member = instance_double(ActiveFedora::Base)
        member_2 = instance_double(ActiveFedora::Base)
        ordered_list.append_target member
        ordered_list.append_target member_2

        expect(ordered_list.last.target).to eq member_2
      end
    end
  end

  describe "#order_will_change!" do
    it "marks it as changed" do
      expect(ordered_list).not_to be_changed
      ordered_list.order_will_change!
      expect(ordered_list).to be_changed
    end
  end

  describe "#target_ids" do
    context "from a graph" do
      let(:head_uri) { RDF::URI.new("parent#bla") }
      let(:tail_uri) { RDF::URI.new("parent#bla") }
      it "returns the IDs without building the object" do
        node_subject = RDF::URI.new("parent#bla")
        member_uri = RDF::URI.new(ActiveFedora::Base.translate_id_to_uri.call("member1"))
        parent_uri = RDF::URI.new("parent")
        graph << [node_subject, RDF::Vocab::ORE.proxyFor, member_uri]
        graph << [node_subject, RDF::Vocab::ORE.proxyIn, parent_uri]
        allow(ActiveFedora::Base).to receive(:from_uri)

        expect(ordered_list.target_ids).to eq ["member1"]
        expect(ActiveFedora::Base).not_to have_received(:from_uri)
      end
    end
    context "from a built up list" do
      it "returns the IDs" do
        member = instance_double(ActiveFedora::Base, id: "member1")
        ordered_list.append_target member

        expect(ordered_list.target_ids).to eq ["member1"]
      end
    end
  end

  describe "#proxy_in" do
    context "when there's one proxy in" do
      it "returns it" do
        member = instance_double(ActiveFedora::Base)
        ordered_list.append_target member, proxy_in: RDF::URI("http://tar.dis")

        expect(ordered_list.proxy_in).to eq RDF::URI("http://tar.dis")
      end
    end
    context "when the proxy in is an AF::Base object" do
      it "returns the ID" do
        member = instance_double(ActiveFedora::Base)
        owner = instance_double(ActiveFedora::Base, id: "member1")
        ordered_list.append_target member, proxy_in: owner

        expect(ordered_list.proxy_in).to eq "member1"
      end
    end
    context "when there's two proxy ins" do
      it "returns the first and throws a warning" do
        member = instance_double(ActiveFedora::Base)
        ordered_list.append_target member, proxy_in: RDF::URI("http://tar.dis")
        ordered_list.append_target member, proxy_in: RDF::URI("http://tar.di")
        ActiveFedora::Base.logger = Logger.new(STDERR)
        allow(ActiveFedora::Base.logger).to receive(:warn)

        expect(ordered_list.proxy_in).to eq RDF::URI("http://tar.dis")
        expect(ActiveFedora::Base.logger).to have_received(:warn).with("WARNING: List contains nodes aggregated under different URIs. Returning only the first.")
      end
    end
  end

  describe "#[]" do
    context "with no nodes" do
      it "is always nil" do
        expect(ordered_list[0]).to eq nil
      end
    end
    context "with two nodes" do
      let(:member) { instance_double(ActiveFedora::Base) }
      let(:member_2) { instance_double(ActiveFedora::Base) }
      before do
        ordered_list.append_target member
        ordered_list.append_target member_2
      end
      it "can return the first" do
        expect(ordered_list[0].target).to eq member
      end
      it "can return the last" do
        expect(ordered_list[1].target).to eq member_2
      end
      it "returns nil for out of bounds values" do
        expect(ordered_list[3]).to eq nil
      end
    end
  end
  describe "#first" do
    context "with no nodes" do
      it "is nil" do
        expect(ordered_list.first).to eq nil
      end
    end
    context "with a node" do
      it "returns that node" do
        member = instance_double(ActiveFedora::Base)
        ordered_list.append_target member
        expect(ordered_list.first.target).to eq member
        expect(ordered_list).to be_changed
      end
    end
    context "with an item from the graph" do
      let(:head_uri) { RDF::URI.new("parent#bla") }
      let(:tail_uri) { RDF::URI.new("parent#bla") }
      it "builds the node" do
        node_subject = RDF::URI.new("parent#bla")
        member_uri = RDF::URI.new("member1")
        parent_uri = RDF::URI.new("parent")
        graph << [node_subject, RDF::Vocab::ORE.proxyFor, member_uri]
        graph << [node_subject, RDF::Vocab::ORE.proxyIn, parent_uri]
        expect(ordered_list.first.proxy_for).to eq member_uri
        expect(ordered_list.first.proxy_for).to be_kind_of RDF::URI
        expect(ordered_list.first.proxy_in).to eq parent_uri
        expect(ordered_list.first).not_to eq nil
      end
      it "is changed by a delete" do
        node_subject = RDF::URI.new("parent#bla")
        member_uri = RDF::URI.new("member1")
        parent_uri = RDF::URI.new("parent")
        graph << [node_subject, RDF::Vocab::ORE.proxyFor, member_uri]
        graph << [node_subject, RDF::Vocab::ORE.proxyIn, parent_uri]

        expect(ordered_list).not_to be_changed
        ordered_list.delete_at(0)
        expect(ordered_list).to be_changed
      end
      context "with multiple nodes" do
        let(:tail_uri) { RDF::URI.new("parent#bla2") }
        it "can build multiple nodes" do
          node_subject = RDF::URI.new("parent#bla")
          node_2_subject = RDF::URI.new("parent#bla2")
          member_uri = RDF::URI.new("member1")
          parent_uri = RDF::URI.new("parent")
          graph << [node_subject, RDF::Vocab::ORE.proxyFor, member_uri]
          graph << [node_subject, RDF::Vocab::ORE.proxyIn, parent_uri]
          graph << [node_subject, RDF::Vocab::IANA.next, node_2_subject]
          graph << [node_2_subject, RDF::Vocab::IANA.prev, node_subject]
          graph << [node_2_subject, RDF::Vocab::ORE.proxyFor, member_uri]
          graph << [node_2_subject, RDF::Vocab::ORE.proxyIn, parent_uri]
          expect(ordered_list.length).to eq 2
          expect(ordered_list.tail.prev.prev).to eq ordered_list.head.next
          expect(ordered_list.map(&:target).map(&:rdf_subject)).to eq [member_uri, member_uri]
          expect(ordered_list).not_to be_changed
        end
      end
    end
  end

  describe "#append_target" do
    it "appends multiple targets" do
      member = instance_double(ActiveFedora::Base)
      proxy_in = instance_double(ActiveFedora::Base, uri: RDF::URI("obj1"))
      600.times do
        ordered_list.append_target member, proxy_in: proxy_in
      end
      expect(ordered_list.length).to eq 600
      expect(ordered_list.to_a.last.next).not_to eq nil
      expect(ordered_list.to_a.last.proxy_in).to eq proxy_in
    end
  end

  describe "#insert_at" do
    it "can insert in the middle" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      3.times do
        ordered_list.append_target member
      end

      ordered_list.insert_at(1, member_2)

      expect(ordered_list.to_a.map(&:target)).to eq [member, member_2, member, member]
      expect(ordered_list).to be_changed
    end
    it "can insert at the beginning" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      2.times do
        ordered_list.append_target member
      end

      ordered_list.insert_at(0, member_2)

      expect(ordered_list.to_a.map(&:target)).to eq [member_2, member, member]
    end
  end

  describe "#delete_node" do
    it "can delete a node in the middle" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      ordered_list.append_target member
      ordered_list.append_target member_2
      ordered_list.append_target member

      ordered_list.delete_node(ordered_list.to_a[1])

      expect(ordered_list.map(&:target)).to eq [member, member]
    end
    it "can delete a node at the start" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      ordered_list.append_target member_2
      ordered_list.append_target member
      ordered_list.append_target member

      ordered_list.delete_node(ordered_list.to_a[0])

      expect(ordered_list.map(&:target)).to eq [member, member]
    end
    it "can delete a node at the end" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      ordered_list.append_target member
      ordered_list.append_target member
      ordered_list.append_target member_2

      ordered_list.delete_node(ordered_list.to_a[2])

      expect(ordered_list.map(&:target)).to eq [member, member]
    end
  end

  describe "#delete_at" do
    it "can delete a node in the middle" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      ordered_list.append_target member
      ordered_list.append_target member_2
      ordered_list.append_target member

      ordered_list.delete_at(1)

      expect(ordered_list.map(&:target)).to eq [member, member]
    end
    it "can delete a node at the start" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      ordered_list.append_target member_2
      ordered_list.append_target member
      ordered_list.append_target member

      ordered_list.delete_at(0)

      expect(ordered_list.map(&:target)).to eq [member, member]
    end
    it "can delete a node at the end" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      ordered_list.append_target member
      ordered_list.append_target member
      ordered_list.append_target member_2

      ordered_list.delete_at(2)

      expect(ordered_list.map(&:target)).to eq [member, member]
    end
    it "does not delete nodes if the loc is out of bounds" do
      member = instance_double(ActiveFedora::Base)
      member_2 = instance_double(ActiveFedora::Base)
      ordered_list.append_target member
      ordered_list.append_target member
      ordered_list.append_target member_2

      ordered_list.delete_at(3)
      ordered_list.delete_at(nil)

      expect(ordered_list.map(&:target)).to eq [member, member, member_2]
    end
  end

  describe "#to_graph" do
    it "creates a good graph" do
      member = instance_double(ActiveFedora::Base, id: '123/456')
      owner = instance_double(ActiveFedora::Base, uri: RDF::URI("http://owner.org"))
      ordered_list.append_target member
      ordered_list.append_target member, proxy_in: owner

      graph = ordered_list.to_graph

      expect(graph.statements.to_a.length).to eq 5
      expect(graph.subjects.to_a).to contain_exactly(*ordered_list.to_a.map(&:rdf_subject))
      expect(graph.query([nil, RDF::Vocab::ORE.proxyFor, nil]).to_a.last.object).to be_kind_of RDF::URI
    end
  end

  describe "#changes_committed!" do
    it "sets changed back to false" do
      member = instance_double(ActiveFedora::Base, uri: RDF::URI("http://test.org"))
      ordered_list.append_target member
      expect(ordered_list).to be_changed

      ordered_list.changes_committed!

      expect(ordered_list).not_to be_changed
    end
  end
end
