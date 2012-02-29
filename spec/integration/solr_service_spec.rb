require 'spec_helper'

require 'active_fedora'

describe ActiveFedora::SolrService do
  describe "#reify_solr_results" do
    before(:all) do
      class FooObject < ActiveFedora::Base
        def self.pid_namespace
          "foo"
        end
        has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
          m.field "holding_id", :string
        end
  
        has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
          m.field "created", :date, :xml_node => "created"
          m.field "language", :string, :xml_node => "language"
          m.field "creator", :string, :xml_node => "creator"
          # Created remaining fields
          m.field "geography", :string, :xml_node => "geography"
          m.field "title", :string, :xml_node => "title"
        end
      end
      @test_object = ActiveFedora::Base.new
      @test_object.label = 'test_object'
      @foo_object = FooObject.new
      @foo_object.label = 'foo_object'
      attributes = {"holding_id"=>{0=>"Holding 1"},
                    "language"=>{0=>"Italian"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Italy"},
                    "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
      @foo_object.update_indexed_attributes(attributes)
      @test_object.save
      @foo_object.save
      @profiles = {
        'test' => @test_object.inner_object.profile,
        'foo' => @foo_object.inner_object.profile,
        'foo_properties' => @foo_object.datastreams['properties'].profile,
        'foo_descMetadata' => @foo_object.datastreams['descMetadata'].profile
      }
      @foo_content = @foo_object.datastreams['descMetadata'].content
    end
    after(:all) do
      @test_object.delete
      @foo_object.delete
    end
    it "should return an array of objects that are of the class stored in active_fedora_model_s" do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@test_object.pid)} OR id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.instance.conn.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result)
      result.length.should == 2
      result.each do |r|
        (r.class == ActiveFedora::Base || r.class == FooObject).should be_true
      end
    end
    
    it 'should load objects from solr data if a :load_from_solr option is passed in' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@test_object.pid)} OR id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.instance.conn.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
      result.length.should == 2
      result.each do |r|
        r.inner_object.should be_a(ActiveFedora::SolrDigitalObject)
        [ActiveFedora::Base, FooObject].should include(r.class)
        ['test_object','foo_object'].should include(r.label)
        @test_object.inner_object.profile.should == @profiles['test']
        @foo_object.inner_object.profile.should == @profiles['foo']
        @foo_object.datastreams['properties'].profile.should == @profiles['foo_properties']
        @foo_object.datastreams['descMetadata'].profile.should == @profiles['foo_descMetadata']
        @foo_object.datastreams['descMetadata'].content.should be_equivalent_to(@foo_content)
      end
    end
    
    it 'should call load_instance_from_solr if :load_from_solr option passed in' do
      query = "id\:#{ActiveFedora::SolrService.escape_uri_for_query(@test_object.pid)} OR id\:#{ActiveFedora::SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.instance.conn.query(query)
      ActiveFedora::Base.expects(:load_instance_from_solr).times(1)
      FooObject.expects(:load_instance_from_solr).times(1)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
    end
    
  end
end
