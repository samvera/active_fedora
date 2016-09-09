require 'spec_helper'

describe ActiveFedora::Base do
  subject(:object) { described_class.new }
  describe ".update_index" do
    before do
      mock_conn = instance_double(RSolr::Client)
      expect(mock_conn).to receive(:add) do |_, opts|
        expect(opts).to eq(params: { softCommit: true })
      end
      mock_ss = instance_double(ActiveFedora::SolrService)
      allow(mock_ss).to receive(:conn).and_return(mock_conn)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(mock_ss)
    end

    it "makes the solr_document with to_solr and add it" do
      expect(object).to receive(:to_solr)
      object.update_index
    end
  end

  describe ".delete" do
    before do
      allow(object).to receive(:new_record?).and_return(false)
      allow(ActiveFedora.fedora.connection).to receive(:delete)
    end

    it "deletes object from repository and index" do
      expect(ActiveFedora::SolrService).to receive(:delete).with(nil)
      object.delete
    end
  end
end
