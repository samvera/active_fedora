require 'spec_helper'

require 'active_fedora'

describe ActiveFedora::SolrService do
  describe '#reify_solr_results' do
    before(:all) do
      class FooObject < ActiveFedora::Base
        def self.pid_namespace
          'foo'
        end

        has_metadata :name => 'descMetadata', :type => ActiveFedora::QualifiedDublinCoreDatastream
      end
      @test_object = ActiveFedora::Base.new
      @test_object.label = 'test_object'
      @foo_object = FooObject.new
      @foo_object.label = 'foo_object'
      attributes = {'language' => {0 => 'Italian'},
                    'creator' => {0 => 'Linguist, A.'},
                    'geography' => {0 => 'Italy'},
                    'title' => {0 => 'Italian and Spanish: A Comparison of Common Phrases'}}
      @foo_object.descMetadata.update_indexed_attributes(attributes)
      @test_object.save
      @foo_object.save
      @profiles = {
        'test' => @test_object.inner_object.profile,
        'foo' => @foo_object.inner_object.profile,
        'foo_descMetadata' => @foo_object.datastreams['descMetadata'].profile
      }
      @foo_content = @foo_object.datastreams['descMetadata'].content
    end
    after(:all) do
      @test_object.delete
      @foo_object.delete
      Object.send(:remove_const, :FooObject)
    end
    it 'should return an array of objects that are of the class stored in active_fedora_model_s' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@test_object.pid)} OR id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result)
      expect(result.length).to eq(2)
      result.each do |r|
        expect(r.class == ActiveFedora::Base || r.class == FooObject).to be_truthy
      end
    end

    it 'should load objects from solr data if a :load_from_solr option is passed in' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@test_object.pid)} OR id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result, {:load_from_solr => true})
      expect(result.length).to eq(2)
      result.each do |r|
        expect(r.inner_object).to be_a(ActiveFedora::SolrDigitalObject)
        expect([ActiveFedora::Base, FooObject]).to include(r.class)
        expect(['test_object', 'foo_object']).to include(r.label)
        expect(@test_object.inner_object.profile).to eq(@profiles['test'])
        expect(@foo_object.inner_object.profile).to eq(@profiles['foo'])
        expect(@foo_object.datastreams['descMetadata'].profile).to eq(@profiles['foo_descMetadata'])
        expect(@foo_object.datastreams['descMetadata'].content).to be_equivalent_to(@foo_content)
      end
    end

    it 'should instantiate all datastreams in the solr doc, even ones undeclared by the class' do
      obj = ActiveFedora::Base.load_instance_from_solr @foo_object.pid
      expect(obj.datastreams.keys).to include('descMetadata')
    end

    it 'should #reify a lightweight object as a new instance' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result, {:load_from_solr => true})
      solr_foo = result.first
      real_foo = solr_foo.reify
      expect(solr_foo.inner_object).to be_a(ActiveFedora::SolrDigitalObject)
      expect(real_foo.inner_object).to be_a(ActiveFedora::DigitalObject)
      expect(solr_foo.label).to eq('foo_object')
      expect(real_foo.label).to eq('foo_object')
    end

    it 'should #reify! a lightweight object within the same instance' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result, {:load_from_solr => true})
      solr_foo = result.first
      expect(solr_foo.inner_object).to be_a(ActiveFedora::SolrDigitalObject)
      solr_foo.reify!
      expect(solr_foo.inner_object).to be_a(ActiveFedora::DigitalObject)
      expect(solr_foo.label).to eq('foo_object')
    end

    it 'should raise an exception when attempting to reify a first-class object' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result, {:load_from_solr => true})
      solr_foo = result.first
      expect {solr_foo.reify}.not_to raise_exception
      expect {solr_foo.reify!}.not_to raise_exception
      expect {solr_foo.reify!}.to raise_exception(/already a full/)
      expect {solr_foo.reify}.to raise_exception(/already a full/)
    end

    it 'should call load_instance_from_solr if :load_from_solr option passed in' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@test_object.pid)} OR id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      expect(ActiveFedora::Base).to receive(:load_instance_from_solr).once
      expect(FooObject).to receive(:load_instance_from_solr).once
      result = ActiveFedora::SolrService.reify_solr_results(solr_result, {:load_from_solr => true})
    end

  end
end
