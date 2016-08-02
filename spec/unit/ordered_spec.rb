require 'spec_helper'

describe ActiveFedora::Orders do
  subject(:image) { Image.new }
  before do
    class Member < ActiveFedora::Base
    end
    class BadClass < ActiveFedora::Base
    end
    class Image < ActiveFedora::Base
      ordered_aggregation :members, through: :list_source
    end
  end
  after do
    Object.send(:remove_const, :Image)
    Object.send(:remove_const, :Member)
    Object.send(:remove_const, :BadClass)
  end
  describe "<<" do
    it "does not accept base objects" do
      member = Member.new
      expect { image.ordered_member_proxies << member }.to raise_error ActiveFedora::AssociationTypeMismatch
      expect(image).not_to be_changed
      expect(image.list_source).not_to be_changed
    end
  end

  describe "ordered_by" do
    let(:image) { Image.new }

    context "an element aggregated by one record" do
      it "can find the record that contains it" do
        m = Member.create
        image.ordered_members << m
        image.save

        expect(m.ordered_by.to_a).to eq [image]
      end
    end

    context "a new element" do
      it "returns an empty array" do
        m = Member.new
        expect(m.ordered_by.to_a).to eq []
      end
    end

    context "an element aggregated by multiple records" do
      let(:image2) { Image.new }
      it "can find all of the records that contain it" do
        m = Member.create
        image.ordered_members << m
        image2.ordered_members << m
        image.save
        image2.save
        expect(m.ordered_by).to contain_exactly(image2, image)
      end
    end
  end

  describe "#ordered_members" do
    describe "<<" do
      it "appends" do
        member = Member.new
        image.save!
        expect(image.ordered_members << member).to eq [member]
        expect(image.ordered_members).to eq [member]
        expect(image.members).to eq [member]
        expect(image.ordered_member_proxies.to_a.length).to eq 1
        image.save!
        expect(image.head).not_to be_blank
        expect(image.reload.head).not_to be_blank
      end
      it "maintains member associations" do
        member = Member.create
        image.ordered_members << member
        image.save
        image.reload
        expect(image.members).to eq [member]
      end
    end
    describe "#=" do
      it "sets ordered members" do
        member = Member.new
        member_2 = Member.new
        image.ordered_members << member
        expect(image.ordered_members).to eq [member]
        image.ordered_members = [member_2, member_2]
        expect(image.ordered_members).to eq [member_2, member_2]
        # Removing from ordering is not the same as removing from aggregation.
        expect(image.members).to contain_exactly member, member_2
      end
    end
    describe "+=" do
      it "appends ordered members" do
        member = Member.new
        member_2 = Member.new
        image.ordered_members << member
        expect(image.ordered_members += [member, member_2]).to eq [member, member, member_2]
        expect(image.ordered_members).to eq [member, member, member_2]
        expect(image.ordered_member_proxies.map(&:target)).to eq [member, member, member_2]
      end
    end
    describe "#delete_at" do
      it "deletes that position" do
        member = Member.new
        member_2 = Member.new
        image.ordered_members += [member, member_2]

        expect(image.ordered_members.delete_at(0)).to eq member
        expect(image.ordered_members).to eq [member_2]
      end
    end

    describe "#delete" do
      let(:member) { Member.create }
      let(:member_2) { Member.create }
      before do
        image.ordered_members += [member, member_2, member]
        image.save!
      end

      context "with an object found in the list" do
        it "deletes all occurences of the object" do
          expect(image.ordered_members.delete(member)).to eq member
          expect(image.ordered_members.to_a).to eq [member_2]
        end
        it "can delete all" do
          expect(image.ordered_members.delete(member)).to eq member
          expect(image.ordered_members.delete(member_2)).to eq member_2
          image.save!
          expect(image.reload.ordered_members.to_a).to eq []
        end
      end

      context "with an object not found in the list" do
        it "returns nil" do
          expect(image.ordered_members.delete(Member.create)).to be_nil
          expect(image.ordered_members.to_a).to eq [member, member_2, member]
        end
      end
    end

    describe "#insert_at" do
      it "adds at a given position" do
        member = Member.new
        member_2 = Member.new
        image.ordered_members += [member, member_2]

        image.ordered_members.insert_at(0, member_2)
        expect(image.ordered_members).to eq [member_2, member, member_2]
      end
      it "adds a proxy_in statement" do
        member = Member.new
        member_2 = Member.new
        image.ordered_members += [member, member_2]

        image.ordered_members.insert_at(0, member_2)
        expect(image.ordered_member_proxies.map(&:proxy_in).uniq).to eq [image]
      end
    end
    describe "lazy loading" do
      it "does not instantiate every record on append" do
        member = Member.new
        member_2 = Member.new
        image.ordered_members += [member, member_2]
        image.save
        allow(ActiveFedora::Base).to receive(:find).and_call_original

        reloaded = image.class.find(image.id)
        reloaded.ordered_members << member

        expect(ActiveFedora::Base).not_to have_received(:find).with(member_2.id)
      end
      it "does not instantiate every record on #insert_at" do
        member = Member.new
        member_2 = Member.new
        image.ordered_members += [member, member_2]
        image.save
        allow(ActiveFedora::Base).to receive(:find).and_call_original

        reloaded = image.class.find(image.id)
        reloaded.ordered_members.insert_at(0, member)

        expect(ActiveFedora::Base).not_to have_received(:find).with(member_2.id)
      end
    end
  end
  describe "append_target" do
    it "doesn't add all members" do
      member = Member.new
      image.members << member
      expect(image.ordered_members).to eq []
    end
    it "can handle adding many objects" do
      member = Member.new
      60.times do
        image.ordered_member_proxies.append_target member
      end
      expect(image.ordered_member_proxies.to_a.length).to eq 60
    end
    it "can't add items not accepted by indirect container" do
      bad_class = BadClass.new
      expect { image.ordered_member_proxies.append_target bad_class }.to raise_error ActiveFedora::AssociationTypeMismatch
    end
    it "adds a member if it doesn't exist in members" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      expect(image.members).to eq [member]
      expect(image.ordered_members).to eq [member]
    end
    it "doesn't add a member twice" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      expect(image.members).to eq [member]
      expect(image.ordered_members).to eq [member, member]
    end
    it "survives persistence" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.save
      image.reload
      expect(image.ordered_members).to eq [member, member]
      expect(image.ordered_member_ids).to eq [member.id, member.id]
      expect(image.list_source.resource.query([nil, ::RDF::Vocab::ORE.proxyIn, image.resource.rdf_subject]).to_a.length).to eq 2
      expect(image.head_ids).to eq image.list_source.head_id
      expect(image.tail_ids).to eq image.list_source.tail_id
    end
    it "can add already persisted items" do
      member = Member.create
      image.ordered_member_proxies.append_target member
      image.save
      image.reload
      expect(image.ordered_members).to eq [member]
    end
    it "can append to a pre-persisted item" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.save
      image.reload
      member_2 = Member.new
      image.ordered_member_proxies.append_target member_2
      image.save
      image.reload
      expect(image.ordered_members).to eq [member, member_2]
    end
  end
  describe "insert_target_at" do
    it "can add between items" do
      member = Member.new
      member2 = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.insert_target_at(1, member2)
      expect(image.ordered_members).to eq [member, member2, member]
      image.save
      image.reload
      expect(image.ordered_members).to eq [member, member2, member]
      image.ordered_member_proxies.insert_target_at(2, member2)
      image.save
      image.reload
      expect(image.ordered_members).to eq [member, member2, member2, member]
    end
  end
  describe "insert_target_id_at" do
    it "can add between items" do
      member = Member.create
      member2 = Member.create
      image.ordered_members += [member, member2]

      allow(ActiveFedora::Base).to receive(:find).and_call_original
      image.ordered_member_proxies.insert_target_id_at(1, member2.id)
      expect(ActiveFedora::Base).not_to have_received(:find).with(member2.id)
      expect(image.ordered_members).to eq [member, member2, member2]
      expect(ActiveFedora::Base).to have_received(:find).with(member2.id)
    end
    context "when given a nil id" do
      it "raises an ArgumentError" do
        expect { image.ordered_member_proxies.insert_target_id_at(0, nil) }.to raise_error ArgumentError, "ID can not be nil"
      end
    end
    context "when given an ID not in members" do
      it "raises an ArgumentError" do
        expect { image.ordered_member_proxies.insert_target_id_at(0, "test") }.to raise_error "test is not a part of members"
      end
    end
  end
  describe "-=" do
    it "can remove proxies" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies -= [image.ordered_member_proxies.last]
      expect(image.ordered_members).to eq []
      expect(image.list_source.resource.statements.to_a.length).to eq 1
    end
    it "can remove proxies in the middle" do
      member = Member.new
      member_2 = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member_2
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies -= [image.ordered_member_proxies[1]]
      expect(image.ordered_members).to eq [member, member]
    end
    it "can remove proxies post-create" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.save
      image.reload
      image.ordered_member_proxies -= [image.ordered_member_proxies[1]]
      expect(image.ordered_members).to eq [member, member]
      image.save
      image.reload
      expect(image.ordered_members).to eq [member, member]
      # THIS NEEDS TO PASS - can't delete fragment URI resources via sparql
      # update?
      # Blocked by https://jira.duraspace.org/browse/FCREPO-1764
      # expect(image.list_source.resource.subjects.to_a.length).to eq 5
    end
  end
  describe ".delete_at" do
    it "can remove in the middle" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.delete_at(1)
      expect(image.ordered_members).to eq [member, member]
    end
    it "returns the node" do
      member = Member.new
      image.ordered_members << member
      image.ordered_members << member
      second_node = image.ordered_member_proxies[1]
      expect(image.ordered_member_proxies.delete_at(1)).to eq second_node
    end
    context "when the node doesn't exist" do
      it "returns nil" do
        expect(image.ordered_member_proxies.delete_at(0)).to eq nil
      end
    end
    it "doesn't do anything if passed a bad value" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.delete_at(3)
      image.ordered_member_proxies.delete_at(nil)
      expect(image.ordered_members).to eq [member, member, member]
    end
    it "can persist a deletion" do
      member = Member.new
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      image.ordered_member_proxies.append_target member
      expect(image.ordered_members).to eq [member, member, member]
      image.ordered_member_proxies.delete_at(1)
      image.save
      image.reload
      expect(image.ordered_members).to eq [member, member]
    end
  end
end
