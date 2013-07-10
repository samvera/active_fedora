require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  describe ".update_index" do
    before do
      mock_conn = double("SolrConnection")
      mock_conn.should_receive(:add)
      mock_conn.should_receive(:commit)
      mock_ss = double("SolrService")
      mock_ss.stub(:conn).and_return(mock_conn)
      ActiveFedora::SolrService.stub(:instance).and_return(mock_ss)
    end
    
    it "should call .to_solr on all SimpleDatastreams AND RelsExtDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})
      mock3 = double("RELS-EXT", :to_solr => {})
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      mock1.should_receive(:solrize_profile).and_return({})
      mock2.should_receive(:solrize_profile).and_return({})
      mock3.should_receive(:solrize_profile).and_return({})
      @test_object.should_receive(:datastreams).twice.and_return(mock_datastreams)
      @test_object.should_receive(:solrize_relationships)
      @test_object.update_index
    end

    it "should call .to_solr on all RDFDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})
      mock3 = double("RELS-EXT", :to_solr => {})
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      mock1.should_receive(:solrize_profile).and_return({})
      mock2.should_receive(:solrize_profile).and_return({})
      mock3.should_receive(:solrize_profile).and_return({})
      @test_object.should_receive(:datastreams).twice.and_return(mock_datastreams)
      @test_object.should_receive(:solrize_relationships)
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
      @test_object.inner_object.stub(:delete)
      mock_conn = double("SolrConnection")
      mock_conn.should_receive(:delete_by_id).with("__DO_NOT_USE__") 
      mock_conn.should_receive(:commit)
      mock_ss = double("SolrService")
      mock_ss.stub(:conn).and_return(mock_conn)
      ActiveFedora::SolrService.stub(:instance).and_return(mock_ss)
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
