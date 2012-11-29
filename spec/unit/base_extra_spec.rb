require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  describe ".update_index" do
    before do
      mock_conn = mock("SolrConnection")
      mock_conn.expects(:add)
      mock_conn.expects(:commit)
      mock_ss = mock("SolrService")
      mock_ss.stubs(:conn).returns(mock_conn)
      ActiveFedora::SolrService.stubs(:instance).returns(mock_ss)
    end
    
    it "should call .to_solr on all SimpleDatastreams AND RelsExtDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = mock("ds1", :to_solr)
      mock2 = mock("ds2", :to_solr)
      mock3 = mock("RELS-EXT", :to_solr)
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      mock1.expects(:solrize_profile).returns({})
      mock2.expects(:solrize_profile).returns({})
      mock3.expects(:solrize_profile).returns({})
      @test_object.expects(:datastreams).twice.returns(mock_datastreams)
      @test_object.expects(:solrize_relationships)
      @test_object.update_index
    end

    it "should call .to_solr on all RDFDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = mock("ds1", :to_solr)
      mock2 = mock("ds2", :to_solr)
      mock3 = mock("RELS-EXT", :to_solr)
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      mock1.expects(:solrize_profile).returns({})
      mock2.expects(:solrize_profile).returns({})
      mock3.expects(:solrize_profile).returns({})
      @test_object.expects(:datastreams).twice.returns(mock_datastreams)
      @test_object.expects(:solrize_relationships)
      @test_object.update_index
    end

    it "should retrieve a solr Connection and call Connection.add" do
      @test_object.update_index
    end

  end
  
  describe ".delete" do
    
    before(:each) do
    end
    
    it "should delete object from repository and index" do
      @test_object.inner_object.stubs(:delete)
      mock_conn = mock("SolrConnection")
      mock_conn.expects(:delete_by_id).with("__DO_NOT_USE__") 
      mock_conn.expects(:commit)
      mock_ss = mock("SolrService")
      mock_ss.stubs(:conn).returns(mock_conn)
      ActiveFedora::SolrService.stubs(:instance).returns(mock_ss)
      @test_object.expects(:inbound_relationships).returns({})
      @test_object.delete
    end

  end
  
  describe '#pids_from_uris' do 
    it "should strip the info:fedora/ out of a given string" do 
      ActiveFedora::Base.pids_from_uris("info:fedora/FOOBAR").should == "FOOBAR"
    end
    it "should accept an array of strings"do 
      ActiveFedora::Base.pids_from_uris(["info:fedora/FOOBAR", "info:fedora/BAZFOO"]).should == ["FOOBAR", "BAZFOO"]
    end
  end

end
