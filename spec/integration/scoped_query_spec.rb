require 'spec_helper'

describe "scoped queries" do

  before do
    module ModelIntegrationSpec
      class Basic < ActiveFedora::Base
        has_metadata "properties", type: ActiveFedora::SimpleDatastream do |m|
          m.field "foo", :string
          m.field "bar", :string
          m.field "baz", :string
        end

        Deprecation.silence(ActiveFedora::Attributes) do
          has_attributes :foo, :bar, :baz, datastream: 'properties', multiple: true
        end

        def to_solr(doc = {})
          doc = super
          doc[ActiveFedora::SolrQueryBuilder.solr_name('foo', :sortable)] = doc[ActiveFedora::SolrQueryBuilder.solr_name('foo', type: :string)]
          doc
        end

      end
    end

  end

  after do
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
        expect(result).to be_instance_of(Array)
        # this test is meaningless if the array length is zero
        expect(result.length > 0).to be true
        expect(result).to all( be_an ModelIntegrationSpec::Basic )
      end
    end

    describe ".first" do
      it "should return one instance of the calling class" do
        expect(ModelIntegrationSpec::Basic.first).to eq test_instance
      end
    end
  end

  describe "with multiple objects" do
    let!(:test_instance1) { ModelIntegrationSpec::Basic.create!(foo: ['Beta'], bar: ['Chips'])}
    let!(:test_instance2) { ModelIntegrationSpec::Basic.create!(foo: ['Alpha'], bar: ['Peanuts'])}
    let!(:test_instance3) { ModelIntegrationSpec::Basic.create!(foo: ['Sigma'], bar: ['Peanuts'])}

    describe "when the objects are in fedora" do
      after do
        test_instance1.delete
        test_instance2.delete
        test_instance3.delete
      end

      it "should query" do
        field = ActiveFedora::SolrQueryBuilder.solr_name('foo', type: :string)
        expect(ModelIntegrationSpec::Basic.where(field => 'Beta')).to eq [test_instance1]
        expect(ModelIntegrationSpec::Basic.where('foo' => 'Beta')).to eq [test_instance1]
      end
      it "should order" do
        expect(ModelIntegrationSpec::Basic.order(ActiveFedora::SolrQueryBuilder.solr_name('foo', :sortable) + ' asc')).to eq [test_instance2, test_instance1, test_instance3]
      end
      it "should limit" do
        expect(ModelIntegrationSpec::Basic.limit(1)).to eq [test_instance1]
      end
      it "should offset" do
        expect(ModelIntegrationSpec::Basic.offset(1)).to eq [test_instance2, test_instance3]
      end

      it "should chain queries" do
        expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrQueryBuilder.solr_name('bar', type: :string) => 'Peanuts').order(ActiveFedora::SolrQueryBuilder.solr_name('foo', :sortable) + ' asc').limit(1)).to eq [test_instance2]
      end

      it "should wrap string conditions with parentheses" do
        expect(ModelIntegrationSpec::Basic.where("foo:bar OR bar:baz").where_values).to eq ["(foo:bar OR bar:baz)"]
      end

      it "should chain where queries" do
        expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrQueryBuilder.solr_name('bar', type: :string) => 'Peanuts').where("#{ActiveFedora::SolrQueryBuilder.solr_name('foo', type: :string)}:bar").where_values).to eq ["#{ActiveFedora::SolrQueryBuilder.solr_name('bar', type: :string)}:Peanuts", "(#{ActiveFedora::SolrQueryBuilder.solr_name('foo', type: :string)}:bar)"]
      end

      it "should chain count" do
        expect(ModelIntegrationSpec::Basic.where(ActiveFedora::SolrQueryBuilder.solr_name('bar', type: :string) => 'Peanuts').count).to eq 2
      end

      it "calling first should not affect the relation's ability to get all results later" do
        relation = ModelIntegrationSpec::Basic.where(ActiveFedora::SolrQueryBuilder.solr_name('bar', type: :string) => 'Peanuts')
        expect {relation.first}.not_to change {relation.to_a.size}
      end

      it "calling where should not affect the relation's ability to get all results later" do
        relation = ModelIntegrationSpec::Basic.where(ActiveFedora::SolrQueryBuilder.solr_name('bar', type: :string) => 'Peanuts')
        expect {relation.where(ActiveFedora::SolrQueryBuilder.solr_name('foo', type: :string) => 'bar')}.not_to change {relation.to_a.size}
      end

      it "calling order should not affect the original order of the relation later" do
        relation = ModelIntegrationSpec::Basic.order(ActiveFedora::SolrQueryBuilder.solr_name('foo', :sortable) + ' asc')
        expect {relation.order(ActiveFedora::SolrQueryBuilder.solr_name('foo', :sortable) + ' desc')}.not_to change {relation.to_a}
      end
    end

    describe "when one of the objects in solr isn't in fedora" do
      let!(:id) { test_instance2.id }
      before { Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, test_instance2.uri).delete }
      after do
        ActiveFedora::SolrService.instance.conn.tap do |conn|
          conn.delete_by_query "id:\"#{id}\""
          conn.commit
        end
        test_instance1.delete
        test_instance3.delete
      end
      it "should log an error" do
        expect(ActiveFedora::Base.logger).to receive(:error).with("Although #{id} was found in Solr, it doesn't seem to exist in Fedora. The index is out of synch.")
        expect(ModelIntegrationSpec::Basic.all).to eq [test_instance1, test_instance3]
      end
    end
  end
end

