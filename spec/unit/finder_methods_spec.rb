require 'spec_helper'

describe ActiveFedora::FinderMethods do
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
      @@klass = this.object_class
      def initialize
        @klass = @@klass
      end
    end
  end

  let(:finder) { finder_class.new }

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
      it { is_expected.to eq "_query_:\"{!raw f=library_id}one/two/three\"" }
    end

    context "when value is an array" do
      let(:value) { ['one', 'four'] }
      it { is_expected.to eq "_query_:\"{!raw f=library_id}one\" AND " \
                             "_query_:\"{!raw f=library_id}four\"" }
    end
  end

  describe "#search_in_batches" do
    let(:docs) { double('docs', has_next?: false) }
    let(:select_handler) { 'select' }
    let(:connection) { double('conn') }
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
end
