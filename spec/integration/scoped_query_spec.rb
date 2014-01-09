require 'spec_helper'

describe "scoped queries" do
  
  before(:each) do 
    module ModelIntegrationSpec
      class Basic < ActiveFedora::Base
        has_metadata "properties", type: ActiveFedora::SimpleDatastream do |m|
          m.field "foo", :string
          m.field "bar", :string
          m.field "baz", :string
        end

        has_attributes :foo, :bar, :baz, datastream: 'properties', multiple: true

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


  describe "When there is one object in the store" do
    let!(:test_instance) { ModelIntegrationSpec::Basic.create!()}

    after do
      test_instance.delete
    end
    
    describe ".all" do
      it "should return an array of instances of the calling Class" do
        result = ModelIntegrationSpec::Basic.all.to_a
        result.should be_instance_of(Array)
        # this test is meaningless if the array length is zero
        result.length.should > 0
        result.each do |obj|
          obj.class.should == ModelIntegrationSpec::Basic
        end
      end
    end

    describe ".first" do
      it "should return one instance of the calling class" do
        ModelIntegrationSpec::Basic.first.should == test_instance
      end
    end
  end

  describe "with multiple objects" do
    let!(:test_instance1) { ModelIntegrationSpec::Basic.create!(:foo=>'Beta', :bar=>'Chips')}
    let!(:test_instance2) { ModelIntegrationSpec::Basic.create!(:foo=>'Alpha', :bar=>'Peanuts')}
    let!(:test_instance3) { ModelIntegrationSpec::Basic.create!(:foo=>'Sigma', :bar=>'Peanuts')}

    describe "when the objects are in fedora" do
      after do
        test_instance1.delete
        test_instance2.delete
        test_instance3.delete
      end
      it "should query" do
        ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('foo', type: :string)=> 'Beta').should == [test_instance1]
        ModelIntegrationSpec::Basic.where('foo' => 'Beta').should == [test_instance1]
      end
      it "should order" do
        ModelIntegrationSpec::Basic.order(ActiveFedora::SolrService.solr_name('foo', :sortable) + ' asc').should == [test_instance2, test_instance1, test_instance3]
      end
      it "should limit" do
        ModelIntegrationSpec::Basic.limit(1).should == [test_instance1]
      end

      it "should chain queries" do
        ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('bar', type: :string) => 'Peanuts').order(ActiveFedora::SolrService.solr_name('foo', :sortable) + ' asc').limit(1).should == [test_instance2]
      end

      it "should chain count" do
        ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('bar', type: :string) => 'Peanuts').count.should == 2 
      end
    end

    describe "when one of the objects in solr isn't in fedora" do
      let!(:pid) { test_instance2.pid }
      before { test_instance2.inner_object.delete }
      after do
        ActiveFedora::SolrService.instance.conn.tap do |conn|
          conn.delete_by_query "id:\"#{pid}\""
          conn.commit
        end
        test_instance1.delete
        test_instance3.delete
      end
      it "should log an error" do
        ActiveFedora::Relation.logger.should_receive(:error).with("When trying to find_each #{pid}, encountered an ObjectNotFoundError. Solr may be out of sync with Fedora")
        ModelIntegrationSpec::Basic.all.should == [test_instance1, test_instance3]
      end
    end
  end
end

