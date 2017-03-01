require 'spec_helper'

describe ActiveFedora::Base do
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end
    end
  end
  let(:sort_query) { ActiveFedora.index_field_mapper.solr_name("system_create", :stored_sortable, type: :date) + ' asc' }
  let(:model_query) { "_query_:\"{!raw f=has_model_ssim}SpecModel::Basic\"" }

  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end

  describe ":all" do
    before { allow(described_class).to receive(:relation).and_return(relation) }
    describe "called on a concrete class" do
      let(:relation) { ActiveFedora::Relation.new(SpecModel::Basic) }

      it "queries solr for all objects with has_model_ssim of self.class" do
        expect(relation).to receive(:load_from_fedora).with("changeme:30", nil)
          .and_return("Fake Object1")
        expect(relation).to receive(:load_from_fedora).with("changeme:22", nil)
          .and_return("Fake Object2")
        mock_docs = [{ "id" => "changeme:30" }, { "id" => "changeme:22" }]
        expect(mock_docs).to receive(:has_next?).and_return(false)
        expect(ActiveFedora::SolrService.instance.conn).to receive(:paginate)
          .with(1, 1000, 'select',
                params: { q: model_query, qt: 'standard', sort: [sort_query], fl: 'id' })
          .and_return('response' => { 'docs' => mock_docs })
        expect(SpecModel::Basic.all).to eq ["Fake Object1", "Fake Object2"]
      end
    end

    describe "called without a specific class" do
      let(:relation) { ActiveFedora::Relation.new(described_class) }
      it "specifies a q parameter" do
        expect(relation).to receive(:load_from_fedora).with("changeme:30", true)
          .and_return("Fake Object1")
        expect(relation).to receive(:load_from_fedora).with("changeme:22", true)
          .and_return("Fake Object2")
        mock_docs = [{ "id" => "changeme:30" }, { "id" => "changeme:22" }]
        expect(mock_docs).to receive(:has_next?).and_return(false)
        expect(ActiveFedora::SolrService.instance.conn).to receive(:paginate)
          .with(1, 1000, 'select',
                params: { q: '*:*', qt: 'standard', sort: [sort_query], fl: 'id' })
          .and_return('response' => { 'docs' => mock_docs })
        expect(described_class.all).to eq ["Fake Object1", "Fake Object2"]
      end
    end
  end

  describe '#find' do
    describe "with :cast false" do
      describe "and an id is specified" do
        it "raises an exception if it is not found" do
          expect { SpecModel::Basic.find("_ID_") }.to raise_error ActiveFedora::ObjectNotFoundError, "Couldn't find SpecModel::Basic with 'id'=_ID_"
        end
      end
    end

    context "with a blank string" do
      it 'raises ActiveFedora::ObjectNotFoundError' do
        expect {
          SpecModel::Basic.find('')
        }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end

  describe "#where" do
    before do
      allow(described_class).to receive(:relation).and_return(relation)
      allow(relation).to receive(:clone).and_return(relation)
    end
    let(:relation) { ActiveFedora::Relation.new(SpecModel::Basic) }
    let(:solr) { ActiveFedora::SolrService.instance.conn }
    let(:expected_query) { "#{model_query} AND " \
                           "_query_:\"{!field f=foo}bar\" AND " \
                           "(_query_:\"{!field f=baz}quix\" OR " \
                           "_query_:\"{!field f=baz}quack\")" }
    let(:expected_params) { { params: { sort: [sort_query], fl: 'id', q: expected_query, qt: 'standard' } } }
    let(:expected_sort_params) { { params: { sort: ["title_t desc"], fl: 'id', q: expected_query, qt: 'standard' } } }
    let(:mock_docs) { [{ "id" => "changeme:30" }, { "id" => "changeme:22" }] }

    it "filters by the provided fields" do
      expect(relation).to receive(:load_from_fedora).with("changeme:30", nil).and_return("Fake Object1")
      expect(relation).to receive(:load_from_fedora).with("changeme:22", nil).and_return("Fake Object2")

      expect(mock_docs).to receive(:has_next?).and_return(false)
      expect(solr).to receive(:paginate).with(1, 1000, 'select', expected_params).and_return('response' => { 'docs' => mock_docs })
      expect(SpecModel::Basic.where(foo: 'bar', baz: ['quix', 'quack'])).to eq ["Fake Object1", "Fake Object2"]
    end

    it "queries for empty strings" do
      expect(SpecModel::Basic.where(has_model_ssim: '').count).to eq 0
    end

    it 'queries for empty arrays' do
      expect(SpecModel::Basic.where(has_model_ssim: []).count).to eq 0
    end

    it "adds options" do
      expect(relation).to receive(:load_from_fedora).with("changeme:30", nil)
        .and_return("Fake Object1")
      expect(relation).to receive(:load_from_fedora).with("changeme:22", nil)
        .and_return("Fake Object2")

      expect(mock_docs).to receive(:has_next?).and_return(false)
      expect(solr).to receive(:paginate).with(1, 1000, 'select', expected_sort_params)
        .and_return('response' => { 'docs' => mock_docs })
      expect(SpecModel::Basic.where(foo: 'bar', baz: ['quix', 'quack'])
                                .order('title_t desc')).to eq ["Fake Object1", "Fake Object2"]
    end
  end

  describe '#find_each' do
    before { allow(described_class).to receive(:relation).and_return(relation) }
    let(:relation) { ActiveFedora::Relation.new(SpecModel::Basic) }
    it "queries solr for all objects with :has_model_ssim of self.class" do
      mock_docs = [{ "id" => "changeme-30" }, { "id" => "changeme-22" }]
      expect(mock_docs).to receive(:has_next?).and_return(false)
      expect(ActiveFedora::SolrService.instance.conn).to receive(:paginate)
        .with(1, 1000, 'select',
              params: { q: model_query, qt: 'standard', sort: [sort_query], fl: 'id' })
        .and_return('response' => { 'docs' => mock_docs })

      allow(relation).to receive(:load_from_fedora).with("changeme-30", nil)
        .and_return(SpecModel::Basic.new(id: 'changeme-30'))
      allow(relation).to receive(:load_from_fedora).with("changeme-22", nil)
        .and_return(SpecModel::Basic.new(id: 'changeme-22'))
      SpecModel::Basic.find_each { |obj| obj.class == SpecModel::Basic }
    end

    describe "with conditions" do
      let(:solr) { ActiveFedora::SolrService.instance.conn }
      let(:expected_query) { "#{model_query} AND " \
                             "_query_:\"{!field f=foo}bar\" AND " \
                             "(_query_:\"{!field f=baz}quix\" OR " \
                             "_query_:\"{!field f=baz}quack\")" }
      let(:expected_params) { { params: { sort: [sort_query], fl: 'id', q: expected_query, qt: 'standard' } } }
      let(:mock_docs) { [{ "id" => "changeme-30" }, { "id" => "changeme-22" }] }

      it "filters by the provided fields" do
        expect(relation).to receive(:load_from_fedora).with("changeme-30", nil).and_return(SpecModel::Basic.new(id: 'changeme-30'))
        expect(relation).to receive(:load_from_fedora).with("changeme-22", nil).and_return(SpecModel::Basic.new(id: 'changeme-22'))

        expect(mock_docs).to receive(:has_next?).and_return(false)
        expect(solr).to receive(:paginate).with(1, 1000, 'select', expected_params).and_return('response' => { 'docs' => mock_docs })
        SpecModel::Basic.find_each(foo: 'bar', baz: ['quix', 'quack']) { |obj| obj.class == SpecModel::Basic }
      end
    end
  end

  describe '#search_in_batches' do
    describe "with conditions hash" do
      let(:solr) { ActiveFedora::SolrService.instance.conn }
      let(:expected_query) { "#{model_query} AND " \
                             "_query_:\"{!field f=foo}bar\" AND " \
                             "(_query_:\"{!field f=baz}quix\" OR " \
                             "_query_:\"{!field f=baz}quack\")" }
      let(:expected_params) { { params: { sort: [sort_query], fl: 'id', q: expected_query, qt: 'standard' } } }
      let(:mock_docs) { double('docs') }

      it "filters by the provided fields" do
        expect(mock_docs).to receive(:has_next?).and_return(false)
        expect(solr).to receive(:paginate).with(1, 1002, 'select', expected_params).and_return('response' => { 'docs' => mock_docs })
        yielded = double("yielded method")
        expect(yielded).to receive(:run).with(mock_docs)
        SpecModel::Basic.search_in_batches({ foo: 'bar', baz: ['quix', 'quack'] }, batch_size: 1002, fl: 'id') { |group| yielded.run group }
      end
    end
  end

  describe '#count' do
    let(:mock_result) { { 'response' => { 'numFound' => 7 } } }

    it "returns a count" do
      expect(ActiveFedora::SolrService).to receive(:get)
        .with(model_query, rows: 0)
        .and_return(mock_result)
      expect(SpecModel::Basic.count).to eq 7
    end

    it "allows conditions" do
      expect(ActiveFedora::SolrService).to receive(:get)
        .with("#{model_query} AND (foo:bar)", rows: 0)
        .and_return(mock_result)
      expect(SpecModel::Basic.count(conditions: 'foo:bar')).to eq 7
    end

    it "counts without a class specified" do
      expect(ActiveFedora::SolrService).to receive(:get)
        .with("(foo:bar)", rows: 0)
        .and_return(mock_result)
      expect(described_class.count(conditions: 'foo:bar')).to eq 7
    end
  end

  describe '#last' do
    describe 'with multiple objects' do
      before do
        SpecModel::Basic.create!(id: '0001')
        SpecModel::Basic.create!(id: '0002')
        @c = SpecModel::Basic.create!(id: '0003')
      end

      it 'returns the last object sorted by id' do
        expect(SpecModel::Basic.last).to eq @c
      end
    end

    describe 'with one object' do
      it 'equals the first object when there is only one' do
        SpecModel::Basic.create!
        expect(SpecModel::Basic.first).to eq SpecModel::Basic.last
      end
    end
  end

  describe '#first' do
    describe 'with multiple objects' do
      before do
        @a = SpecModel::Basic.create!(id: '0001')
        SpecModel::Basic.create!(id: '0002')
        SpecModel::Basic.create!(id: '0003')
      end

      it 'returns the first object sorted by id' do
        expect(SpecModel::Basic.first).to eq @a
      end
    end

    describe 'with one object' do
      it 'equals the first object when there is only one' do
        SpecModel::Basic.create!
        expect(SpecModel::Basic.first).to eq SpecModel::Basic.last
      end
    end
  end

  describe '#search_with_conditions' do
    subject(:search_with_conditions) { klass.search_with_conditions(conditions) }
    let(:mock_result) { double('Result') }
    let(:klass) { SpecModel::Basic }

    before do
      expect(ActiveFedora::SolrService).to receive(:query)
        .with(expected_query, sort: [sort_query]).and_return(mock_result)
    end

    context "with a hash of conditions" do
      let(:expected_query) { "#{model_query} AND " \
                             "_query_:\"{!field f=foo}bar\" AND " \
                             "(_query_:\"{!field f=baz}quix\" OR " \
                             "_query_:\"{!field f=baz}quack\")" }
      let(:conditions) { { foo: 'bar', baz: ['quix', 'quack'] } }

      it "makes a query to solr and returns the results" do
        expect(search_with_conditions).to eq mock_result
      end
    end

    context "with quotes in the params" do
      let(:expected_query) { "#{model_query} AND " \
                             "_query_:\"{!field f=foo}9\\\" Nails\" AND " \
                             "(_query_:\"{!field f=baz}7\\\" version\" OR " \
                             "_query_:\"{!field f=baz}quack\")" }
      let(:conditions) { { foo: '9" Nails', baz: ['7" version', 'quack'] } }

      it "escapes quotes" do
        expect(search_with_conditions).to eq mock_result
      end
    end

    context "called on AF::Base" do
      let(:klass) { described_class }

      context "with a hash" do
        let(:conditions) { { baz: 'quack' } }
        let(:expected_query) { "_query_:\"{!field f=baz}quack\"" }
        it "doesn't use the class if it's called on AF:Base " do
          expect(search_with_conditions).to eq mock_result
        end
      end

      context "called with a string" do
        let(:conditions) { 'chunky:monkey' }
        let(:expected_query) { '(chunky:monkey)' }
        it "uses the query string if it's provided and wrap it in parentheses" do
          expect(search_with_conditions).to eq mock_result
        end
      end
    end
  end

  describe "#load_from_fedora" do
    let(:relation) { ActiveFedora::Relation.new(described_class) }
    before { @obj = SpecModel::Basic.create(id: "test_123") }
    after { @obj.destroy }
    it "casts when klass == ActiveFedora::Base and cast argument is nil" do
      expect(relation.send(:load_from_fedora, "test_123", nil)).to be_a SpecModel::Basic
    end
  end
end
