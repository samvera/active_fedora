require 'spec_helper'

describe ActiveFedora::IndexingService do
  let(:indexer) { described_class.new(object) }
  let(:object) { ActiveFedora::Base.new }

  describe "#generate_solr_document" do
    context "when no block is passed" do
      subject(:solr_doc) { indexer.generate_solr_document }
      it "produces a document" do
        expect(solr_doc['has_model_ssim']).to eq ['ActiveFedora::Base']
      end
    end

    context "when a block is passed" do
      subject(:solr_doc) do
        indexer.generate_solr_document do |solr_doc|
          solr_doc['noid'] = '12345'
        end
      end

      it "produces and yield the document" do
        expect(solr_doc['has_model_ssim']).to eq ['ActiveFedora::Base']
        expect(solr_doc['noid']).to eq '12345'
      end
    end
  end
end
