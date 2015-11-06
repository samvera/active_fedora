require 'spec_helper'

describe 'scoped queries' do

  before(:each) do
    module ModelIntegrationSpec
      class Basic < ActiveFedora::Base
        has_metadata :name => 'properties', :type => ActiveFedora::SimpleDatastream do |m|
          m.field 'foo', :string
          m.field 'bar', :string
          m.field 'baz', :string
        end

        delegate_to :properties, [:foo, :bar, :baz], multiple: true

        def to_solr(doc = {})
          doc = super
          doc[ActiveFedora::SolrService.solr_name('foo', :sortable)] = doc[ActiveFedora::SolrService.solr_name('foo', type: :string)]
          doc
        end

      end
    end

  end

  after(:each) do
    Object.send(:remove_const, :ModelIntegrationSpec)
  end


  describe 'When there is one object in the store' do
    let!(:test_instance) { ModelIntegrationSpec::Basic.create!()}

    after do
      test_instance.delete
    end

    describe '.all' do
      it 'should return an array of instances of the calling Class' do
        result = ModelIntegrationSpec::Basic.all
        expect(result).to be_instance_of(Array)
        # this test is meaningless if the array length is zero
        expect(result.length).to be > 0
        result.each do |obj|
          expect(obj.class).to eq(ModelIntegrationSpec::Basic)
        end
      end
    end

    describe '.first' do
      it 'should return one instance of the calling class' do
        expect(ModelIntegrationSpec::Basic.first).to eq(test_instance)
      end
    end
  end

  describe 'with multiple objects' do
    let!(:test_instance1) { ModelIntegrationSpec::Basic.create!(:foo => 'Beta', :bar => 'Chips')}
    let!(:test_instance2) { ModelIntegrationSpec::Basic.create!(:foo => 'Alpha', :bar => 'Peanuts')}
    let!(:test_instance3) { ModelIntegrationSpec::Basic.create!(:foo => 'Sigma', :bar => 'Peanuts')}

    after do
      test_instance1.delete
      test_instance2.delete
      test_instance3.delete
    end
    it 'should query' do
      expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('foo', type: :string) => 'Beta')).to eq([test_instance1])
      expect(ModelIntegrationSpec::Basic.where('foo' => 'Beta')).to eq([test_instance1])
    end
    it 'should order' do
      expect(ModelIntegrationSpec::Basic.order(ActiveFedora::SolrService.solr_name('foo', :sortable) + ' asc')).to eq([test_instance2, test_instance1, test_instance3])
    end
    it 'should limit' do
      expect(ModelIntegrationSpec::Basic.limit(1)).to eq([test_instance1])
    end

    it 'should chain queries' do
      expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('bar', type: :string) => 'Peanuts').order(ActiveFedora::SolrService.solr_name('foo', :sortable) + ' asc').limit(1)).to eq([test_instance2])
    end

    it 'should chain count' do
      expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('bar', type: :string) => 'Peanuts').count).to eq(2)
    end

    describe "when one of the objects in solr isn't in fedora" do
      it 'should log an error' do
        expect(ModelIntegrationSpec::Basic).to receive(:find_one).with(test_instance1.pid, nil).and_call_original
        expect(ModelIntegrationSpec::Basic).to receive(:find_one).with(test_instance2.pid, nil).and_raise(ActiveFedora::ObjectNotFoundError)
        expect(ModelIntegrationSpec::Basic).to receive(:find_one).with(test_instance3.pid, nil).and_call_original
        expect(ActiveFedora::Relation.logger).to receive(:error).with("When trying to find_each #{test_instance2.pid}, encountered an ObjectNotFoundError. Solr may be out of sync with Fedora")
        expect(ModelIntegrationSpec::Basic.all).to eq([test_instance1, test_instance3])
      end
    end
  end
end
