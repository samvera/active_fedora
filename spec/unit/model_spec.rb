require 'spec_helper'

describe ActiveFedora::Model do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  describe '.solr_query_handler' do
    subject { SpecModel::Basic.solr_query_handler }
    after do
      # reset to default
      SpecModel::Basic.solr_query_handler = 'standard'
    end

    it { should eq 'standard' }

    context "when setting to something besides the default" do
      before { SpecModel::Basic.solr_query_handler = 'search' }

      it { should eq 'search' }
    end
  end

  describe ".from_class_uri" do
    subject { ActiveFedora::Model.from_class_uri(uri) }
    context "a blank string" do
      before { expect(ActiveFedora::Base.logger).to receive(:warn) }
      let(:uri) { '' }
      it { should be_nil }
    end
  end
end
