require 'spec_helper'

describe ActiveFedora::Model do

  before(:each) do
    module ModelIntegrationSpec
      class Basic < ActiveFedora::Base
        has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
          m.field "foo", :string
          m.field "bar", :string
          m.field "baz", :string
        end

        delegate_to :properties, [:foo, :bar, :baz]

        def to_solr(doc = {})
          doc = super
          doc[ActiveFedora::SolrService.solr_name('foo', :string, :sortable)] = doc[ActiveFedora::SolrService.solr_name('foo', :string, :searchable)]
          doc
        end

      end
    end

  end

  after(:each) do
    Object.send(:remove_const, :ModelIntegrationSpec)
  end


  describe "When there is one object in the store" do
    before do
      @test_instance = ModelIntegrationSpec::Basic.new
      @test_instance.save
    end

    after do
      @test_instance.delete
    end


    describe ".all" do
      it "should return an array of instances of the calling Class" do
        result = ModelIntegrationSpec::Basic.all
        expect(result).to be_instance_of(Array)
        # this test is meaningless if the array length is zero
        expect(result.length).to be > 0
        result.each do |obj|
          expect(obj.class).to eq(ModelIntegrationSpec::Basic)
        end
      end
    end

    describe ".first" do
      it "should return one instance of the calling class" do
        expect(ModelIntegrationSpec::Basic.first).to eq(@test_instance)
      end
    end
  end

  describe "with multiple objects" do
    before do
      @test_instance1 = ModelIntegrationSpec::Basic.create!(:foo=>'Beta', :bar=>'Chips')
      @test_instance2 = ModelIntegrationSpec::Basic.create!(:foo=>'Alpha', :bar=>'Peanuts')
      @test_instance3 = ModelIntegrationSpec::Basic.create!(:foo=>'Sigma', :bar=>'Peanuts')
    end
    after do
      @test_instance1.delete
      @test_instance2.delete
      @test_instance3.delete
    end
    it "should query" do
      expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('foo', :string, :searchable)=> 'Beta')).to eq([@test_instance1])
      expect(ModelIntegrationSpec::Basic.where('foo' => 'Beta')).to eq([@test_instance1])
    end
    it "should order" do
      expect(ModelIntegrationSpec::Basic.order(ActiveFedora::SolrService.solr_name('foo', :string, :sortable) + ' asc')).to eq([@test_instance2, @test_instance1, @test_instance3])
    end
    it "should limit" do
      expect(ModelIntegrationSpec::Basic.limit(1)).to eq([@test_instance1])
    end

    it "should chain them" do
      expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('bar', :string, :searchable) => 'Peanuts').order(ActiveFedora::SolrService.solr_name('foo', :string, :sortable) + ' asc').limit(1)).to eq([@test_instance2])
    end
  end
end

