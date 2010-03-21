require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora/solr_service'

include ActiveFedora

describe ActiveFedora::SolrService do
  it "should take a narg constructor and configure for localhost" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:on}).returns(mconn)
    ss = SolrService.register
  end
  it "should accept host arg into constructor" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://fubar', {:autocommit=>:on}).returns(mconn)
    ss = SolrService.register('http://fubar')
  end
  it "should merge options" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:on, :foo=>'bar'}).returns(mconn)
    ss = SolrService.register(nil, {:foo=>'bar'})
  end
  it "should clobber options" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:off, :foo=>:bar}).returns(mconn)
    ss = SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
  end

  it "should set the threadlocal solr service" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:off, :foo=>:bar}).returns(mconn)
    ss = SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
    Thread.current[:solr_service].should == ss
    SolrService.instance.should == ss
  end
  it "should fail fast if solr service not initialized" do
    Thread.current[:solr_service].should be_nil
    proc{SolrService.instance}.should raise_error(SolrNotInitialized)
  end
  before do
    Thread.current[:solr_service]=nil
  end
  
  describe "#reify_solr_results" do
    before(:each) do
      @sample_solr_hits = [{"id"=>"my:_PID1_", "active_fedora_model_s"=>["AudioRecord"]},
                            {"id"=>"my:_PID2_", "active_fedora_model_s"=>["AudioRecord"]},
                            {"id"=>"my:_PID3_", "active_fedora_model_s"=>["AudioRecord"]}]
    end
    it "should only take Solr::Response::Standard objects as input" do
      mocko = mock("input", :is_a? => false)
      lambda {ActiveFedora::SolrService.reify_solr_results(mocko)}.should raise_error(ArgumentError)
    end
    it "should use Repository.find_model to instantiate objects" do
      solr_result = mock("solr result", :is_a? => true)
      solr_result.expects(:hits).returns(@sample_solr_hits)
      Kernel.expects(:const_get).with("AudioRecord").returns("AudioRecord").times(3)
      mock_repo = mock("repo")
      mock_repo.expects(:find_model).with("my:_PID1_", "AudioRecord").returns("AR1")
      mock_repo.expects(:find_model).with("my:_PID2_", "AudioRecord").returns("AR2")
      mock_repo.expects(:find_model).with("my:_PID3_", "AudioRecord").returns("AR3")
      Fedora::Repository.expects(:instance).returns(mock_repo).times(3)
      ActiveFedora::SolrService.reify_solr_results(solr_result).should == ["AR1", "AR2", "AR3"]
    end
  end
  
  describe '#construct_query_for_pids' do
    it "should generate a useable solr query from an array of Fedora pids" do
      ActiveFedora::SolrService.construct_query_for_pids(["my:_PID1_", "my:_PID2_", "my:_PID3_"]).should == 'id:my\:_PID1_ OR id:my\:_PID2_ OR id:my\:_PID3_' 
    end
    it "should return a valid solr query even if given an empty array as input" do
      ActiveFedora::SolrService.construct_query_for_pids([""]).should == "id:NEVER_USE_THIS_ID"
      
    end
  end
  
  describe '#escape_uri_for_query' do
    it "should escape : with a backslash" do
      ActiveFedora::SolrService.escape_uri_for_query("my:pid").should == 'my\:pid'
    end
  end
  
end
