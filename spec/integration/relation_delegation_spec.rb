require 'spec_helper'

describe ActiveFedora::Base do
  before(:all) do
    class TestClass < ActiveFedora::Base
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

  after(:all) do
    Object.send(:remove_const, :TestClass)
  end

  describe "with multiple objects" do
    let!(:instance1) { TestClass.create!(foo: ['Beta'], bar: ['Chips']) }
    let!(:instance2) { TestClass.create!(foo: ['Alpha'], bar: ['Peanuts']) }
    let!(:instance3) { TestClass.create!(foo: ['Sigma'], bar: ['Peanuts']) }

    subject(:peanuts) { TestClass.where(bar: 'Peanuts') }

    it "maps" do
      expect(peanuts.map(&:id)).to contain_exactly instance2.id, instance3.id
    end

    it "collects" do
      expect(peanuts.collect(&:id)).to contain_exactly instance2.id, instance3.id
    end

    it "has each" do
      expect(peanuts.each.to_a.length).to eq 2
    end

    it "has all?" do
      expect(peanuts.all? { |t| t.foo == ['Alpha'] }).to be false
      expect(peanuts.all? { |t| t.bar == ['Peanuts'] }).to be true
    end

    it "has include?" do
      expect(peanuts.include?(instance1)).to be false
      expect(peanuts.include?(instance2)).to be true
    end
  end
end
