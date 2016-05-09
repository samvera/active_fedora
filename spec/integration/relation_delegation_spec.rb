require 'spec_helper'

describe ActiveFedora::Model do
  before(:all) do
    module ModelIntegrationSpec
      class Basic < ActiveFedora::Base
        property :foo, predicate: ::RDF::URI('http://example.com/foo')
        property :bar, predicate: ::RDF::URI('http://example.com/bar') do |index|
          index.as :stored_searchable
        end

        def to_solr(doc = {})
          doc = super
          doc[ActiveFedora.index_field_mapper.solr_name('foo', :sortable)] = doc[ActiveFedora.index_field_mapper.solr_name('foo', type: :string)]
          doc
        end
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :ModelIntegrationSpec)
  end

  describe "with multiple objects" do
    let!(:instance1) { ModelIntegrationSpec::Basic.create!(foo: ['Beta'], bar: ['Chips']) }
    let!(:instance2) { ModelIntegrationSpec::Basic.create!(foo: ['Alpha'], bar: ['Peanuts']) }
    let!(:instance3) { ModelIntegrationSpec::Basic.create!(foo: ['Sigma'], bar: ['Peanuts']) }

    subject { ModelIntegrationSpec::Basic.where(bar: 'Peanuts') }

    it "maps" do
      expect(subject.map(&:id)).to eq [instance2.id, instance3.id]
    end

    it "collects" do
      expect(subject.collect(&:id)).to eq [instance2.id, instance3.id]
    end

    it "has each" do
      t = double
      expect(t).to receive(:foo).twice
      subject.each { t.foo }
    end

    it "has all?" do
      expect(subject.all? { |t| t.foo == ['Alpha'] }).to be false
      expect(subject.all? { |t| t.bar == ['Peanuts'] }).to be true
    end

    it "has include?" do
      expect(subject.include?(instance1)).to be false
      expect(subject.include?(instance2)).to be true
    end
  end
end
