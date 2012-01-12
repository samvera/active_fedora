require 'spec_helper'
require "active_fedora/samples"

class MockAFBaseQuerySolr < ActiveFedora::Base
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

  has_metadata :name=>'ng_metadata', :type=> Hydra::ModsArticleDatastream
end

describe ActiveFedora::Base do
  
  before(:all) do
    @test_object = ActiveFedora::Base.new
    #get objects into fedora and solr
    @test_object2 = MockAFBaseQuerySolr.new
    attributes = {"holding_id"=>{0=>"Holding 1"},
                  "language"=>{0=>"Italian"},
                  "creator"=>{0=>"Linguist, A."},
                  "geography"=>{0=>"Italy"},
                  "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
    @test_object2.update_indexed_attributes(attributes)
    @test_object2.save
    
    @test_object3 = MockAFBaseQuerySolr.new
    attributes = {"holding_id"=>{0=>"Holding 2"},
                  "language"=>{0=>"Spanish;Latin"},
                  "creator"=>{0=>"Linguist, A."},
                  "geography"=>{0=>"Spain"},
                  "title"=>{0=>"A study of the evolution of Spanish from Latin"}}
    @test_object3.update_indexed_attributes(attributes)
    @test_object3.save      

    @test_object4 = MockAFBaseQuerySolr.new
    attributes = {"holding_id"=>{0=>"Holding 3"},
                  "language"=>{0=>"Spanish;Latin"},
                  "creator"=>{0=>"Linguist, A."},
                  "geography"=>{0=>"Spain"},
                  "title"=>{0=>"An obscure look into early nomadic tribes of Spain"}}
    @test_object4.update_indexed_attributes(attributes)
    @test_object4.save
      
  end

  after(:all) do
    begin
    @test_object.delete
    rescue
    end
    begin
    @test_object2.delete
    rescue
    end
    begin
    @test_object3.delete
    rescue
    end
    begin
    @test_object4.delete
    rescue
    end
  end

  describe '#find_by_fields_by_solr' do
    it 'should return fedora objects of the correct class' do
      #query based on just model
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object3.pid,@test_object4.pid]
    end
      
    it 'should match a query against multiple result fields' do
      #query on certain fields
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"language"=>"Latin"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid,@test_object4.pid]
      
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"language"=>"Italian"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should== [@test_object2.pid]
      
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"language"=>"Spanish"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid,@test_object4.pid]
    end
      
    it 'should  query against many fields' do
      #assume spaces removed at index time so query by 'Linguist,A.' instead of 'Linguist, A.'
      
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A.","title"=>"latin"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid]
    end

    it 'should query by id' do
      
      #query with value with embedded ':' (pid)
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"id"=>@test_object3.pid})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid]
    end


    it "should sort by default by system_create_date" do
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A.","language"=>"Spanish"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid,@test_object4.pid]
    end

    it "should be able to change the sort direction" do 
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>[{"system_create"=>"desc"}]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object4.pid,@test_object3.pid,@test_object2.pid]
    end

    it "should default the sort direction to ascending" do
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>["system_create"]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object3.pid,@test_object4.pid]
    end
      

    it "should sort by multiple fields" do
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>["geography",{"system_create"=>"desc"}]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object4.pid,@test_object3.pid]
    end
      
    it "should transform system_modified_date" do
      #check appropriate logic for system_modified_date field name transformation
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>["geography",{"system_mod"=>"desc"}]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object4.pid,@test_object3.pid]
    end

    it "should accept rows as a parameter" do 
      #check pass in rows values
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:rows=>2})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object3.pid]
    end
      
    it "should accept a solr field (geography_t) that is not an object field name(e.g. geography)" do
      #check query with field mapping to solr field and with solr field that is not a field in object
      #should be able to query by either active fedora model field name or solr key name
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"geography_t"=>"Italy"})
      found_pids = results.hits.map{|h| h[SOLR_DOCUMENT_ID]}
      found_pids.should == [@test_object2.pid]
    end

    describe "with Nokogiri based datastreams" do
      before do
        @test_object2.ng_metadata.journal_title = "foo"
        @test_object2.save
      end
      it "should query Nokogiri based datastreams if you use the solr field names (doesn't do mapping)" do
        results = MockAFBaseQuerySolr.find_by_fields_by_solr({"journal_title_t" => "foo"})
        found_pids = results.hits.map{|h| h[SOLR_DOCUMENT_ID]}
        found_pids.should == [@test_object2.pid]
      end
    end
  end
end
