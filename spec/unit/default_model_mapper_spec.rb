require 'spec_helper'

describe ActiveFedora::DefaultModelMapper do
  subject(:mapper) { described_class.new classifier_class: classifier, solr_field: solr_field, predicate: predicate }
  let(:classifier) { class_double(ActiveFedora::ModelClassifier) }
  let(:classifier_instance) { instance_double(ActiveFedora::ModelClassifier) }
  let(:solr_field) { 'solr_field' }
  let(:predicate) { 'info:predicate' }

  describe '#classifier' do
    context 'with a solr document' do
      let(:solr_document) { { 'solr_field' => ['xyz'] } }

      before do
        expect(classifier).to receive(:new).with(['xyz']).and_return(classifier_instance)
      end

      it 'creates a classifier from the solr field data' do
        expect(mapper.classifier(solr_document)).to eq classifier_instance
      end
    end

    context 'with a resource' do
      let(:graph) do
        RDF::Graph.new << [:hello, predicate, 'xyz']
      end

      let(:resource) { instance_double(ActiveFedora::LdpResource, graph: graph) }

      before do
        expect(classifier).to receive(:new).with(['xyz']).and_return(classifier_instance)
      end

      it 'creates a classifier from the resource model predicate' do
        expect(mapper.classifier(resource)).to eq classifier_instance
      end
    end
  end
end
