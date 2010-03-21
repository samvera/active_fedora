require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'

include ActiveFedora


describe ActiveFedora::SolrService do
  describe "#reify_solr_results" do
    before(:all) do
      class FooObject < ActiveFedora::Base
      end
      @test_object = ActiveFedora::Base.new
      @foo_object = FooObject.new
      @test_object.save
      @foo_object.save
    end
    after(:all) do
      @test_object.delete
      @foo_object.delete
    end
    it "should return an array of objects that are of the class stored in active_fedora_model_s" do
      query = "id\:#{SolrService.escape_uri_for_query(@test_object.pid)} OR id\:#{SolrService.escape_uri_for_query(@foo_object.pid)}"
      solr_result = SolrService.instance.conn.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result)
      result.length.should == 2
      result.each do |r|
        (r.class == ActiveFedora::Base || r.class == FooObject).should be_true
      end
    end
    
  end
end
