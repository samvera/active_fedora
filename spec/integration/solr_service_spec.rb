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
    it "should return an array of objects that are of the class stored in active_fedora_model_s" do
      query = "id\:#{RSolr.escape(@test_object.pid)} OR id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result)
      result.length.should == 2
      result.each do |r|
        (r.class == ActiveFedora::Base || r.class == FooObject).should be_true
      end
    end
    
    it 'should load objects from solr data if a :load_from_solr option is passed in' do
      query = "id\:#{RSolr.escape(@test_object.pid)} OR id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
      result.length.should == 2
      result.each do |r|
        r.inner_object.should be_a(ActiveFedora::SolrDigitalObject)
        [ActiveFedora::Base, FooObject].should include(r.class)
        ['test_object','foo_object'].should include(r.label)
        @test_object.inner_object.profile.should == @profiles['test']
        @foo_object.inner_object.profile.should == @profiles['foo']
        @foo_object.datastreams['descMetadata'].profile.should == @profiles['foo_descMetadata']
        @foo_object.datastreams['descMetadata'].content.should be_equivalent_to(@foo_content)
      end
    end
    
    it 'should instantiate all datastreams in the solr doc, even ones undeclared by the class' do
      obj = ActiveFedora::Base.load_instance_from_solr @foo_object.pid 
      obj.datastreams.keys.should include('descMetadata')
    end
    
    it 'should #reify a lightweight object as a new instance' do
      query = "id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
      solr_foo = result.first
      real_foo = solr_foo.reify
      solr_foo.inner_object.should be_a(ActiveFedora::SolrDigitalObject)
      real_foo.inner_object.should be_a(ActiveFedora::DigitalObject)
      solr_foo.label.should == 'foo_object'
      real_foo.label.should == 'foo_object'
    end
    
    it 'should #reify! a lightweight object within the same instance' do
      query = "id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
      solr_foo = result.first
      solr_foo.inner_object.should be_a(ActiveFedora::SolrDigitalObject)
      solr_foo.reify!
      solr_foo.inner_object.should be_a(ActiveFedora::DigitalObject)
      solr_foo.label.should == 'foo_object'
    end
    
    it 'should raise an exception when attempting to reify a first-class object' do
      query = "id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
      solr_foo = result.first
      lambda {solr_foo.reify}.should_not raise_exception
      lambda {solr_foo.reify!}.should_not raise_exception
      lambda {solr_foo.reify!}.should raise_exception(/already a full/)
      lambda {solr_foo.reify}.should raise_exception(/already a full/)
    end
  
    it 'should call load_instance_from_solr if :load_from_solr option passed in' do
      query = "id\:#{RSolr.escape(@test_object.pid)} OR id\:#{RSolr.escape(@foo_object.pid)}"
      solr_result = ActiveFedora::SolrService.query(query)
      ActiveFedora::Base.should_receive(:load_instance_from_solr).once
      FooObject.should_receive(:load_instance_from_solr).once
      result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
    end
    
  end
end
