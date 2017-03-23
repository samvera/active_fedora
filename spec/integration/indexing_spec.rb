require 'spec_helper'
@@last_id = 0

describe ActiveFedora::Base do
  describe "descendant_uris" do
    before do
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
      let(:file) { ActiveFedora::File.new(described_class.id_to_uri('foo/bar/bax')) }

      before do
        file.content = "Hello!!!"
        file.save
      end

      it "does not put the datastream in the decendants list" do
        expect(described_class.descendant_uris(root_uri(ids))).not_to include file.uri
      end
    end

    describe "when some of the descendants are prioritized models" do
      around do |example|
        class PriorityModel < ActiveFedora::Base
        end
        original_defaults = ActiveFedora::Indexing::DescendantFetcher.default_priority_models
        ActiveFedora::Indexing::DescendantFetcher.default_priority_models = ["PriorityModel"]

        example.run

        ActiveFedora::Indexing::DescendantFetcher.default_priority_models = original_defaults
        Object.send(:remove_const, :PriorityModel)
      end
      let(:ids) { ['foo', 'bar'] }
      let!(:priority_models) { [PriorityModel.create, PriorityModel.create] }

      it "puts prioritized model ids first" do
        expect(described_class.descendant_uris(ActiveFedora.fedora.base_uri).slice(0..(priority_models.count - 1))).to contain_exactly(*priority_models.collect(&:uri).collect(&:to_s))
      end
    end

    describe "reindex_everything" do
      let(:ids) { ['foo', 'bar'] }
      let(:solr) { ActiveFedora::SolrService.instance.conn }
      before do
        solr.delete_by_query('*:*', params: { 'softCommit' => true })
      end
      it "adds object to solr" do
        expect {
          described_class.reindex_everything
        }.to change { ActiveFedora::SolrService.query('id:foo').size }.from(0).to(1)
      end
    end
  end

  describe "with an autosave association, where some records are deleted" do
    before do
      class GenericFile < ActiveFedora::Base
        has_many :permissions, predicate: ::RDF::Vocab::ACL.accessTo
        accepts_nested_attributes_for :permissions, allow_destroy: true
        property :title, predicate: ::RDF::Vocab::DC.title

        def to_solr
          super.tap do |doc|
            doc['permissions_ssim'] = permission_ids
          end
        end
      end

      class Permission < ActiveFedora::Base
        belongs_to :generic_file, predicate: ::RDF::Vocab::ACL.accessTo
      end
    end

    let(:p1) { Permission.create! }
    let(:p2) { Permission.create! }
    let(:gf) { GenericFile.create(permissions: [p1, p2]) }

    before { gf.update(permissions_attributes: [{ id: p1.id, _destroy: 'true' }]) }

    it "saves to solr correctly" do
      result = ActiveFedora::SolrService.query("id:#{gf.id}", rows: 10).first['permissions_ssim']
      expect(result).to eq [p2.id]
    end
  end
end
