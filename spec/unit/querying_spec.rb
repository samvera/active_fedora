require 'spec_helper'

describe ActiveFedora::Querying do
  before do
    class SpecModel < ActiveFedora::Base
    end
  end

  after do
    Object.send(:remove_const, :SpecModel)
  end

  describe '.solr_query_handler' do
    subject { SpecModel.solr_query_handler }

    it { is_expected.to eq 'standard' }

    context "when setting to something besides the default" do
      before { SpecModel.solr_query_handler = 'search' }

      it { is_expected.to eq 'search' }
    end
  end
end
