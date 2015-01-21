require 'spec_helper'

describe ActiveFedora::IndexingService do
  let(:indexer) { described_class.new(object) }
  let(:object) { ActiveFedora::Base.new }

  describe "#solrize_relationships" do
    subject { indexer.send(:solrize_relationships) }
    let(:person_reflection) { double('person', foreign_key: 'person_id', kind_of?: true, solr_key: member_of) }
    let(:location_reflection) { double('location', foreign_key: 'location_id', kind_of?: true, solr_key: part_of) }
    let(:reflections) { { 'person' => person_reflection, 'location' => location_reflection } }

    let(:member_of) { ActiveFedora::SolrQueryBuilder.solr_name("info:fedora/fedora-system:def/relations-external#isMemberOf", :symbol) }
    let(:part_of) { ActiveFedora::SolrQueryBuilder.solr_name("info:fedora/fedora-system:def/relations-external#isPartOf", :symbol) }

    before do
      expect(object).to receive(:[]).with('person_id').and_return('info:fedora/demo:10')
      expect(object).to receive(:[]).with('location_id').and_return('info:fedora/demo:11')
      expect(object.class).to receive(:reflections).and_return(reflections)
    end

    it "should serialize the relationships into a Hash" do
      expect(subject[member_of]).to eq "info:fedora/demo:10"
      expect(subject[part_of]).to eq "info:fedora/demo:11"
    end
  end

  describe "#generate_solr_document" do
    context "when no block is passed" do
      subject { indexer.generate_solr_document }
      it "should produce a document" do
        expect(subject['has_model_ssim']).to eq ['ActiveFedora::Base']
      end
    end

    context "when a block is passed" do
      subject do
        indexer.generate_solr_document do |solr_doc|
          solr_doc['noid'] = '12345'
        end
      end

      it "should produce and yield the document" do
        expect(subject['has_model_ssim']).to eq ['ActiveFedora::Base']
        expect(subject['noid']).to eq '12345'
      end
    end
  end
end
