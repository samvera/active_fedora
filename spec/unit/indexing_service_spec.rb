require 'spec_helper'

describe ActiveFedora::IndexingService do
  let(:indexer) { described_class.new(object) }
  let(:object) { ActiveFedora::Base.new }

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
