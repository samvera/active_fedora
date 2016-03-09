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
    subject { described_class.from_class_uri(uri) }
    context "a blank string" do
      before { expect(ActiveFedora::Base.logger).to receive(:warn) }
      let(:uri) { '' }
      it { should be_nil }
    end
  end

  describe ".class_from_string" do
    before do
      module ParentClass
        class SiblingClass
        end
        class OtherSiblingClass
        end
      end
    end
    it "returns class constants based on strings" do
      expect(described_class.class_from_string("Om")).to eq Om
      expect(described_class.class_from_string("ActiveFedora::RDF::IndexingService")).to eq ActiveFedora::RDF::IndexingService
      expect(described_class.class_from_string("IndexingService", ActiveFedora::RDF)).to eq ActiveFedora::RDF::IndexingService
    end

    it "finds sibling classes" do
      expect(described_class.class_from_string("SiblingClass", ParentClass::OtherSiblingClass)).to eq ParentClass::SiblingClass
    end

    it "raises a NameError if the class isn't found" do
      expect {
        described_class.class_from_string("FooClass", ParentClass::OtherSiblingClass)
      }.to raise_error NameError, /uninitialized constant (Object::)?FooClass/
    end
  end
end
