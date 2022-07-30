require 'spec_helper'

RSpec.describe ActiveFedora::FinderMethods do
  let(:object_class) do
    Class.new do
      def self.delegated_attributes
        {}
      end

      def self.solr_query_handler
        'standard'
      end

      def self.default_sort_params
        ["system_create_dtsi asc"]
      end
    end
  end

  let(:finder_class) do
    this = self
    Class.new do
      include ActiveFedora::FinderMethods
      def initialize(object_class:)
        @klass = object_class
      end
    end
  end

  let(:finder) { finder_class.new(object_class: object_class) }

  describe '#equivalent_class?' do
    let(:child_class) { Class.new(object_class) }
    let(:object_class) { Class.new }
    it 'is true for the exact class' do
      expect(finder.send(:equivalent_class?, object_class)).to be true
    end

    it 'is true for child classes' do
      expect(finder.send(:equivalent_class?, child_class)).to be true
    end

    it 'is falsey for non-decendants' do
      expect(finder.send(:equivalent_class?, Class.new)).to be_nil
    end
  end

  describe '#class_to_load' do
    subject(:class_to_load) { finder.send(:class_to_load, resource, true) }

    let(:best_model) { Class.new }
    let(:mapper) { instance_double(ActiveFedora::DefaultModelMapper, classifier: classifier) }
    let(:classifier) { instance_double(ActiveFedora::ModelClassifier, best_model: best_model) }
    let(:resource) { instance_double(Hash) }

    before do
      allow(ActiveFedora).to receive(:model_mapper).and_return(mapper)
    end

    context 'when using the default implementation' do
      it 'raises an error' do
        expect { class_to_load }.to raise_error ActiveFedora::ModelMismatch
      end
    end

    context 'when a custom finder overrides equivalent_class?' do
      before do
        allow(finder).to receive(:equivalent_class?).and_return(true)
      end

      it 'calls the overridden implementation' do
        expect(class_to_load).to eq best_model
        expect(finder).to have_received(:equivalent_class?).with(best_model)
      end
    end
  end

  describe "#condition_to_clauses" do
    subject { finder.send(:condition_to_clauses, key, value) }
    let(:key) { 'library_id' }

    context "when value is nil" do
      let(:value) { nil }
      it { is_expected.to eq "-library_id:[* TO *]" }
    end

    context "when value is empty string" do
      let(:value) { '' }
      it { is_expected.to eq "-library_id:[* TO *]" }
    end

    context "when value is an id" do
      let(:value) { 'one/two/three' }
      it { is_expected.to eq "_query_:\"{!field f=library_id}one/two/three\"" }
    end

    context "when value is an array" do
      let(:value) { ['one', 'four'] }
      it { is_expected.to eq "(_query_:\"{!field f=library_id}one\" AND " \
                             "_query_:\"{!field f=library_id}four\")" }
    end
  end

  describe "#search_in_batches" do
    let(:docs) { instance_double(RSolr::Response::PaginatedDocSet, has_next?: false) }
    let(:select_handler) { 'select' }
    let(:connection) { instance_double(RSolr::Client) }
    before do
      expect(finder).to receive(:create_query).with('age_t' => '21').and_return('dummy query')
      allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(connection)
      allow(ActiveFedora::SolrService).to receive(:select_path).and_return(select_handler)
      expect(connection).to receive(:paginate) \
        .with(1, 1000, select_handler, params: hash_including(other_opt: 'test')) \
        .and_return('response' => { 'docs' => docs })
    end
    it "yields the docs" do
      expect { |b|
        finder.search_in_batches({ 'age_t' => '21' }, { other_opt: 'test' }, &b)
      }.to yield_with_args(docs)
    end

    context "with custom select handler" do
      let(:select_handler) { 'select_test' }
      it "uses the custom select handler" do
        finder.search_in_batches({ 'age_t' => '21' }, other_opt: 'test') do end
      end
    end
  end

  describe '#search_by_id' do
    context 'with a document in solr' do
      let(:doc) { instance_double(Hash) }

      before do
        expect(finder).to receive(:search_with_conditions).with({ id: 'x' }, hash_including(rows: 1)).and_return([doc])
      end

      it "returns the document" do
        expect(finder.search_by_id('x')).to eq doc
      end
    end

    context 'without a document in solr' do
      before do
        expect(finder).to receive(:search_with_conditions).with({ id: 'x' }, hash_including(rows: 1)).and_return([])
      end

      it "returns the document" do
        expect { finder.search_by_id('x') }.to raise_error ActiveFedora::ObjectNotFoundError, "Object 'x' not found in solr"
      end
    end
  end
end
