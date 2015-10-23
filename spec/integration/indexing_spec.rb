require 'spec_helper'
@@last_id = 0

describe ActiveFedora::Base do
  describe "descendant_uris" do
    before :each do
      ids.each do |id|
        described_class.create id: id
      end
    end

    def root_uri(ids = [])
      ActiveFedora::Base.id_to_uri(ids.first)
    end

    context 'when there there are no descendants' do
      let(:ids) { ['foo'] }

      it 'returns an array containing only the URI passed to it' do
        expect(described_class.descendant_uris(root_uri(ids))).to eq ids.map { |id| described_class.id_to_uri(id) }
      end
    end

    context 'when there are > 1 descendants' do
      let(:ids) { ['foo', 'foo/bar', 'foo/bar/chu'] }

      it 'returns an array containing the URI passed to it, as well as all descendant URIs' do
        expect(described_class.descendant_uris(root_uri(ids))).to eq ids.map { |id| described_class.id_to_uri(id) }
      end
    end

    context 'when some of the decendants are not RDFSources' do
      let(:ids) { ['foo', 'foo/bar'] }
      let(:datastream) { ActiveFedora::Datastream.new(described_class.id_to_uri('foo/bar/bax')) }

      before do
        datastream.content = "Hello!!!"
        datastream.save
      end

      it "does not put the datastream in the decendants list" do
        expect(described_class.descendant_uris(root_uri(ids))).not_to include datastream.uri
      end
    end

    describe "reindex_everything" do
      let(:ids) { ['foo', 'bar'] }
      let(:solr) { ActiveFedora::SolrService.instance.conn }
      before do
        solr.delete_by_query('*:*', params: { 'softCommit' => true })
      end
      it "calls update_index on every object represented in the sitemap" do
        expect {
          described_class.reindex_everything
        }.to change { ActiveFedora::SolrService.query('id:foo').size }.from(0).to(1)
      end
    end
  end
end
