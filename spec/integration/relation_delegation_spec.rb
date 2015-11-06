require 'spec_helper'

describe ActiveFedora::Model do

  before(:all) do
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

  after(:all) do
    Object.send(:remove_const, :ModelIntegrationSpec)
  end


  describe 'with multiple objects' do
    let!(:instance1){ ModelIntegrationSpec::Basic.create!(:foo => 'Beta', :bar => 'Chips')}
    let!(:instance2){ ModelIntegrationSpec::Basic.create!(:foo => 'Alpha', :bar => 'Peanuts')}
    let!(:instance3){ ModelIntegrationSpec::Basic.create!(:foo => 'Sigma', :bar => 'Peanuts')}

    after { ModelIntegrationSpec::Basic.delete_all }

    subject { ModelIntegrationSpec::Basic.where(bar: 'Peanuts') }

    it 'should map' do
      expect(subject.map(&:id)).to eq([instance2.id, instance3.id])
    end

    it 'should collect' do
      expect(subject.collect(&:id)).to eq([instance2.id, instance3.id])
    end

    it 'should have each' do
      t = double
      expect(t).to receive(:foo).twice
      subject.each { t.foo }
    end

    it 'should have all?' do
      expect(subject.all? { |t| t.foo == ['Alpha']}).to be_falsey
      expect(subject.all? { |t| t.bar == ['Peanuts']}).to be_truthy
    end

    it 'should have include?' do
      expect(subject.include?(instance1)).to be_falsey
      expect(subject.include?(instance2)).to be_truthy
    end
  end
end
