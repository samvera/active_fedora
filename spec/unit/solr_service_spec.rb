require 'spec_helper'


describe ActiveFedora::SolrService do
  before do
    Thread.current[:solr_service]=nil
  end
  
  after(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end
  
  it "should take a narg constructor and configure for localhost" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:on}).returns(mconn)
    ss = ActiveFedora::SolrService.register
  end
  it "should accept host arg into constructor" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://fubar', {:autocommit=>:on}).returns(mconn)
    ss = ActiveFedora::SolrService.register('http://fubar')
  end
  it "should merge options" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:on, :foo=>'bar'}).returns(mconn)
    ss = ActiveFedora::SolrService.register(nil, {:foo=>'bar'})
  end
  it "should clobber options" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:off, :foo=>:bar}).returns(mconn)
    ss = ActiveFedora::SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
  end

  it "should set the threadlocal solr service" do
    mconn = mock('conn')
    Solr::Connection.expects(:new).with('http://localhost:8080/solr', {:autocommit=>:off, :foo=>:bar}).returns(mconn)
    ss = ActiveFedora::SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
    Thread.current[:solr_service].should == ss
    ActiveFedora::SolrService.instance.should == ss
  end
  it "should try to initialize if the service not initialized, and fail if it does not succeed" do
    Thread.current[:solr_service].should be_nil
    ActiveFedora.expects(:load_configs)
    ActiveFedora::SolrService.expects(:register)
    proc{ActiveFedora::SolrService.instance}.should raise_error(ActiveFedora::SolrNotInitialized)
  end

  describe "#reify_solr_results" do
    before(:each) do
      class AudioRecord
        attr_accessor :pid
        def initialize (params={}) 
          self.pid = params[:pid]
        end
      end
      @sample_solr_hits = [{"id"=>"my:_PID1_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                            {"id"=>"my:_PID2_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                            {"id"=>"my:_PID3_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]}]
    end
    it "should only take Solr::Response::Standard objects as input" do
      mocko = mock("input", :is_a? => false)
      lambda {ActiveFedora::SolrService.reify_solr_results(mocko)}.should raise_error(ArgumentError)
    end
    it "should use Repository.find_model to instantiate objects" do
      solr_result = mock("solr result", :is_a? => true)
      solr_result.expects(:hits).returns(@sample_solr_hits)
      ActiveFedora::SolrService.reify_solr_results(solr_result).map(&:pid).should == ["my:_PID1_", "my:_PID2_", "my:_PID3_"] 
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
