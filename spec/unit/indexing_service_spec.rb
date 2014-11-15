require 'spec_helper'

describe ActiveFedora::IndexingService do
  let(:indexer) { described_class.new(object) }
  let(:object) { ActiveFedora::Base.new }

  subject { indexer.send(:solrize_relationships) }

  describe "#solrize_relationships" do
    let(:person_reflection) { double('person', foreign_key: 'person_id', kind_of?: true, solr_key: 'http://fedora.info/definitions/v4/rels-ext#isMemberOf_ssim') }
    let(:location_reflection) { double('location', foreign_key: 'location_id', kind_of?: true, solr_key: 'http://fedora.info/definitions/v4/rels-ext#isPartOf_ssim') }
    let(:reflections) { { 'person' => person_reflection, 'location' => location_reflection } }

    it "should serialize the relationships into a Hash" do
      expect(object).to receive(:[]).with('person_id').and_return('info:fedora/demo:10')
      expect(object).to receive(:[]).with('location_id').and_return('info:fedora/demo:11')
      expect(object.class).to receive(:reflections).and_return(reflections)
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("http://fedora.info/definitions/v4/rels-ext#isMemberOf", :symbol)]).to eq "info:fedora/demo:10"
      expect(subject[ActiveFedora::SolrQueryBuilder.solr_name("http://fedora.info/definitions/v4/rels-ext#isPartOf", :symbol)]).to eq "info:fedora/demo:11"
    end
  end

end
