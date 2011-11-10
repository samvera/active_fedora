require File.join( File.dirname(__FILE__), "../spec_helper" )

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
      @foo_object = FooObject.new
      attributes = {"holding_id"=>{0=>"Holding 1"},
                    "language"=>{0=>"Italian"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Italy"},
                    "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
      @foo_object.update_indexed_attributes(attributes)
      @test_object.save
      @foo_object.save
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
        (r.class == ActiveFedora::Base || r.class == FooObject).should be_true
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
