require 'spec_helper'

require 'active_fedora'

describe ActiveFedora::SolrService do
  describe "#reify_solr_results" do
    before(:all) do
      class FooObject < ActiveFedora::Base
        def self.pid_namespace
          "foo"
        end
  
        has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream
      end
      @test_object = ActiveFedora::Base.new
      @test_object.label = 'test_object'
      @foo_object = FooObject.new
      @foo_object.label = 'foo_object'
      attributes = {"language"=>{0=>"Italian"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Italy"},
                    "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
      @foo_object.descMetadata.update_indexed_attributes(attributes)
      @test_object.save
      @foo_object.save
      @profiles = {
        'test' => @test_object.profile,
        'foo' => @foo_object.profile,
        'foo_descMetadata' => @foo_object.datastreams['descMetadata'].profile
      }
      @foo_content = @foo_object.datastreams['descMetadata'].content
    end
    after(:all) do
      @test_object.delete
      @foo_object.delete
      Object.send(:remove_const, :FooObject)
    end
    it "should return an array of objects that are of the class stored in active_fedora_model_s" do
      query = "id\:#{RSolr.escape(@test_object.pid)} OR id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result)
      result.length.should == 2
      result.each do |r|
        (r.class == ActiveFedora::Base || r.class == FooObject).should be_true
      end
    end
    
    it 'should #reify a lightweight object as a new instance' do
      query = "id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
      solr_foo = result.first
      solr_foo.inner_object.should be_a(ActiveFedora::SolrDigitalObject)
      solr_foo.label.should == 'foo_object'
    end
  end
end
