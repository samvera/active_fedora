require 'spec_helper'
@@last_id = 0

describe ActiveFedora::Base do
  describe "get_descendent_uris" do

    before :each do
      ids.each do |id|
        ActiveFedora::Base.create id: id
      end
    end

    def root_uri(ids=[])
      ActiveFedora::Base.id_to_uri(ids.first)
    end

    context 'when there there are no descendents' do

      let(:ids) { ['foo'] }

      it 'returns an array containing only the URI passed to it' do
        expect(ActiveFedora::Base.get_descendent_uris(root_uri(ids))).to eq ids.map {|id| ActiveFedora::Base.id_to_uri(id) }
      end
    end

    context 'when there are > 1 descendents' do

      let(:ids) { ['foo', 'foo/bar', 'foo/bar/chu'] }

      it 'returns an array containing the URI passed to it, as well as all descendent URIs' do
        expect(ActiveFedora::Base.get_descendent_uris(root_uri(ids))).to eq ids.map {|id| ActiveFedora::Base.id_to_uri(id) }
      end
    end

    context 'when some of the decendants are not RDFSources' do
      let(:ids) { ['foo', 'foo/bar'] }
      let(:datastream) { ActiveFedora::Datastream.new(ActiveFedora::Base.id_to_uri('foo/bar/bax')) }

      before do
        datastream.content = "Hello!!!"
        datastream.save
      end

      it "should not put the datastream in the decendants list" do
        expect(ActiveFedora::Base.get_descendent_uris(root_uri(ids))).not_to include datastream.uri
      end
    end
  end
end
