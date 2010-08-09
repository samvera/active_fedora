require File.join( File.dirname(__FILE__), "..", "spec_helper" )

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
end

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_object.new_object = true
  end

  after(:each) do
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
    begin
    @test_object5.delete
    rescue
    end
  end

  describe '#find_by_fields_by_solr' do
    it 'should return fedora objects of the model of self that match the given solr query, queries the active_fedora solr instance' do
      #get objects into fedora and solr
      @test_object2 = MockAFBaseQuerySolr.new
      @test_object2.new_object = true
      attributes = {"holding_id"=>{0=>"Holding 1"},
                    "language"=>{0=>"Italian"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Italy"},
                    "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
      @test_object2.update_indexed_attributes(attributes)
      @test_object2.save
      
      @test_object3 = MockAFBaseQuerySolr.new
      @test_object3.new_object = true
      attributes = {"holding_id"=>{0=>"Holding 2"},
                    "language"=>{0=>"Spanish;Latin"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Spain"},
                    "title"=>{0=>"A study of the evolution of Spanish from Latin"}}
      @test_object3.update_indexed_attributes(attributes)
      @test_object3.save      

      @test_object4 = MockAFBaseQuerySolr.new
      @test_object4.new_object = true
      attributes = {"holding_id"=>{0=>"Holding 3"},
                    "language"=>{0=>"Spanish;Latin"},
                    "creator"=>{0=>"Linguist, A."},
                    "geography"=>{0=>"Spain"},
                    "title"=>{0=>"An obscure look into early nomadic tribes of Spain"}}
      @test_object4.update_indexed_attributes(attributes)
      @test_object4.save
      
      #query based on just model
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object3.pid,@test_object4.pid]
      
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
      
      #assume spaces removed at index time so query by 'Linguist,A.' instead of 'Linguist, A.'
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object3.pid,@test_object4.pid]
      
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"geography"=>"Italy"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid]
      
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A.","title"=>"latin"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid]
      
      #query with value with embedded ':' (pid)
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"id"=>@test_object3.pid})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid]
      
      #query with different options
      #sort defaults to system_create_date
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A.","language"=>"Spanish"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object3.pid,@test_object4.pid]
      
      #change sort direction
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>[{"system_create"=>"desc"}]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object4.pid,@test_object3.pid,@test_object2.pid]
      
      #pass in sort without direction defined and make ascending by default
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>["system_create"]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object3.pid,@test_object4.pid]
      
      #sort on multiple fields
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>["geography",{"system_create"=>"desc"}]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object4.pid,@test_object3.pid]
      
      #check appropriate logic for system_modified_date field name transformation
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:sort=>["geography",{"system_mod"=>"desc"}]})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object4.pid,@test_object3.pid]
      
      #check pass in rows values
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"creator"=>"Linguist,A."},{:rows=>2})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid,@test_object3.pid]
      
      #check query with field mapping to solr field and with solr field that is not a field in object
      #should be able to query by either active fedora model field name or solr key name
      results = MockAFBaseQuerySolr.find_by_fields_by_solr({"geography_t"=>"Italy"})
      found_pids = []
      results.hits.each do |hit|
        found_pids.push(hit[SOLR_DOCUMENT_ID])
      end
      
      found_pids.should == [@test_object2.pid]
    end
  end
end