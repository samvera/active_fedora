# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ActiveFedora::Indexing::DescendantFetcher do
  before do
    class Thing < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title
    end

    class Source < ActiveFedora::Base
      is_a_container class_name: 'Thing'
    end
  end
  after do
    Object.send(:remove_const, :Source)
    Object.send(:remove_const, :Thing)
  end

  let(:parent) { Source.create }
  let(:child) { parent.contains.create(title: ['my title']) }
  let(:other_parent) { Source.create }
  let!(:source_uris) { [parent, other_parent].map(&:uri).map(&:to_s) }
  let!(:thing_uris) { [child].map(&:uri).map(&:to_s) }
  let(:uri) { ActiveFedora.fedora.base_uri }
  let(:fetcher) { described_class.new(uri) }

  describe '.descendant_and_self_uris' do
    context 'with default priority models' do
      it 'returns uris for all objects by walking tree' do
        expect(fetcher.descendant_and_self_uris).to match_array(source_uris + thing_uris)
      end
    end
    context 'when supplying priority models' do
      let(:priority_models) { ['Thing'] }
      let(:fetcher) { described_class.new(uri, priority_models: priority_models) }
      it 'returns priority model uris first' do
        expect(fetcher.descendant_and_self_uris.slice(0..(thing_uris.count - 1))).to match_array(thing_uris)
      end
    end
  end
  describe '.descendant_and_self_uris_partitioned' do
    context 'with default priority models' do
      it 'returns' do
        expect(fetcher.descendant_and_self_uris_partitioned.to_a).to match_array([[:priority, []], [:other, match_array(source_uris + thing_uris)]])
      end
    end
    context 'when supplying priority models' do
      let(:priority_models) { ['Thing'] }
      let(:fetcher) { described_class.new(uri, priority_models: priority_models) }
      it 'returns' do
        expect(fetcher.descendant_and_self_uris_partitioned.to_a).to match_array([[:priority, match_array(thing_uris)], [:other, match_array(source_uris)]])
      end
    end
  end
  describe '.descendant_and_self_uris_partitioned_by_model' do
    it 'returns' do
      expect(fetcher.descendant_and_self_uris_partitioned_by_model.to_a).to match_array([['Source', match_array(source_uris)], ['Thing', match_array(thing_uris)]])
    end
    context 'excluding self' do
      let(:fetcher) { described_class.new(parent.uri, exclude_self: true) }
      it 'returns' do
        expect(fetcher.descendant_and_self_uris_partitioned_by_model.to_a).to match_array([['Thing', [child.uri.to_s]]])
      end
    end
  end
end
