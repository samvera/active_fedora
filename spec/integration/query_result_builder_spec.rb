require 'spec_helper'

describe ActiveFedora::QueryResultBuilder do
  describe "#reify_solr_results" do
    before(:each) do
      class FooObject < ActiveFedora::Base
        def self.id_namespace
          "foo"
        end

        has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream
      end
      @test_object = ActiveFedora::Base.new
      @foo_object = FooObject.new
      attributes = {"language"=>{0=>"Italian"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Italy"},
                    "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
      @foo_object.descMetadata.update_indexed_attributes(attributes)
      @test_object.save
      @foo_object.save
      @profiles = {
        # 'test' => @test_object.profile,
        # 'foo' => @foo_object.profile,
        # 'foo_descMetadata' => @foo_object.datastreams['descMetadata'].profile
      }
      @foo_content = @foo_object.attached_files['descMetadata'].content
    end
    after(:each) do
      Object.send(:remove_const, :FooObject)
    end
    it "should return an array of objects that are of the class stored in active_fedora_model_s" do
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([@test_object.id, @foo_object.id])
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::QueryResultBuilder.reify_solr_results(solr_result)
      expect(result.length).to eq 2
      result.each do |r|
        expect((r.class == ActiveFedora::Base || r.class == FooObject)).to be true
      end
    end

    it 'should #reify a lightweight object as a new instance' do
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([@foo_object.id])
      solr_result = ActiveFedora::SolrService.query(query)
      result = ActiveFedora::QueryResultBuilder.reify_solr_results(solr_result,{:load_from_solr=>true})
      expect(result.first).to be_instance_of FooObject
    end
  end
end
