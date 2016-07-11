require 'spec_helper'

describe ActiveFedora::Querying do
  before do
    module ModelIntegrationSpec
      class Basic < ActiveFedora::Base
        property :foo, predicate: ::RDF::URI('http://example.com/foo') do |index|
          index.as :stored_searchable
        end
        property :bar, predicate: ::RDF::URI('http://example.com/bar') do |index|
          index.as :stored_searchable
        end
        property :baz, predicate: ::RDF::URI('http://example.com/baz')

        def to_solr(doc = {})
          doc = super
          doc[ActiveFedora.index_field_mapper.solr_name('foo', :sortable)] = doc[ActiveFedora.index_field_mapper.solr_name('foo', type: :string)]
          doc
        end
      end
    end
  end

  after do
    Object.send(:remove_const, :ModelIntegrationSpec)
  end

  describe "When there is one object in the store" do
    let!(:test_instance) { ModelIntegrationSpec::Basic.create! }

    after do
      test_instance.delete
    end

    describe ".all" do
      it "returns an array of instances of the calling Class" do
        result = ModelIntegrationSpec::Basic.all.to_a
        expect(result).to be_instance_of(Array)
        # this test is meaningless if the array length is zero
        expect(result.length).to be > 0
        expect(result).to all(be_an(ModelIntegrationSpec::Basic))
      end
    end

    describe ".first" do
      it "returns one instance of the calling class" do
        expect(ModelIntegrationSpec::Basic.first).to eq test_instance
      end
    end
  end

  describe "with multiple objects" do
    let!(:test_instance1) { ModelIntegrationSpec::Basic.create!(foo: ['Beta'], bar: ['Chips']) }
    let!(:test_instance2) { ModelIntegrationSpec::Basic.create!(foo: ['Alpha'], bar: ['Peanuts']) }
    let!(:test_instance3) { ModelIntegrationSpec::Basic.create!(foo: ['Sigma'], bar: ['Peanuts']) }

    describe "when the objects are in fedora" do
      after do
        test_instance1.delete
        test_instance2.delete
        test_instance3.delete
      end

      it "queries" do
        field = ActiveFedora.index_field_mapper.solr_name('foo', type: :string)
        expect(ModelIntegrationSpec::Basic.where(field => 'Beta')).to eq [test_instance1]
        expect(ModelIntegrationSpec::Basic.where('foo' => 'Beta')).to eq [test_instance1]
        expect(ModelIntegrationSpec::Basic.where('foo' => ['Beta', 'Alpha'])).to eq [test_instance1, test_instance2]
      end
      it "orders" do
        expect(ModelIntegrationSpec::Basic.order(ActiveFedora.index_field_mapper.solr_name('foo', :sortable) + ' asc')).to contain_exactly test_instance2, test_instance1, test_instance3
      end
      it "limits" do
        expect(ModelIntegrationSpec::Basic.limit(1)).to eq [test_instance1]
      end
      it "offsets" do
        expect(ModelIntegrationSpec::Basic.offset(1)).to contain_exactly test_instance2, test_instance3
      end

      it "chains queries" do
        expect(ModelIntegrationSpec::Basic.where(ActiveFedora.index_field_mapper.solr_name('bar', type: :string) => 'Peanuts').order(ActiveFedora.index_field_mapper.solr_name('foo', :sortable) + ' asc').limit(1)).to eq [test_instance2]
      end

      it "wraps string conditions with parentheses" do
        expect(ModelIntegrationSpec::Basic.where("foo:bar OR bar:baz").where_values).to eq ["(foo:bar OR bar:baz)"]
      end

      it "chains where queries" do
        first_condition = { ActiveFedora.index_field_mapper.solr_name('bar', type: :string) => 'Peanuts' }
        second_condition = "foo_tesim:bar"
        where_values = ModelIntegrationSpec::Basic.where(first_condition)
                                                  .where(second_condition).where_values
        expect(where_values).to eq ["_query_:\"{!field f=bar_tesim}Peanuts\"",
                                    "(foo_tesim:bar)"]
      end

      it "chains count" do
        expect(ModelIntegrationSpec::Basic.where(ActiveFedora.index_field_mapper.solr_name('bar', type: :string) => 'Peanuts').count).to eq 2
      end

      it "calling first should not affect the relation's ability to get all results later" do
        relation = ModelIntegrationSpec::Basic.where(ActiveFedora.index_field_mapper.solr_name('bar', type: :string) => 'Peanuts')
        expect { relation.first }.not_to change { relation.to_a.size }
      end

      it "calling where should not affect the relation's ability to get all results later" do
        relation = ModelIntegrationSpec::Basic.where(ActiveFedora.index_field_mapper.solr_name('bar', type: :string) => 'Peanuts')
        expect { relation.where(ActiveFedora.index_field_mapper.solr_name('foo', type: :string) => 'bar') }.not_to change { relation.to_a.size }
      end

      it "calling order should not affect the original order of the relation later" do
        relation = ModelIntegrationSpec::Basic.order(ActiveFedora.index_field_mapper.solr_name('foo', :sortable) + ' asc')
        expect { relation.order(ActiveFedora.index_field_mapper.solr_name('foo', :sortable) + ' desc') }.not_to change { relation.to_a }
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
      it "logs an error" do
        expect(ActiveFedora::Base.logger).to receive(:error).with("Although #{id} was found in Solr, it doesn't seem to exist in Fedora. The index is out of synch.")
        expect(ModelIntegrationSpec::Basic.all).to contain_exactly test_instance1, test_instance3
      end
    end
  end
end
