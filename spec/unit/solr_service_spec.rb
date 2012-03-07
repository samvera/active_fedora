require 'spec_helper'


describe ActiveFedora::SolrService do
  before do
    Thread.current[:solr_service]=nil
  end
  
  after(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end
  
  it "should take a narg constructor and configure for localhost" do
    RSolr.expects(:connect).with(:url => 'http://localhost:8080/solr')
    ActiveFedora::SolrService.register
  end
  it "should accept host arg into constructor" do
    RSolr.expects(:connect).with(:url => 'http://fubar')
    ActiveFedora::SolrService.register('http://fubar')
  end
  it "should clobber options" do
    RSolr.expects(:connect).with(:url => 'http://localhost:8080/solr', :autocommit=>:off, :foo=>:bar)
    ActiveFedora::SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
  end

  it "should set the threadlocal solr service" do
    RSolr.expects(:connect).with(:url => 'http://localhost:8080/solr', :autocommit=>:off, :foo=>:bar)
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
        def init_with(inner_obj)
          self.pid = inner_obj.pid
          self
        end
        def self.connection_for_pid(pid)
        end
      end
      @sample_solr_hits = [{"id"=>"my:_PID1_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                            {"id"=>"my:_PID2_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                            {"id"=>"my:_PID3_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]}]
    end
    it "should use Repository.find to instantiate objects" do
      AudioRecord.expects(:find).with("my:_PID1_")
      AudioRecord.expects(:find).with("my:_PID2_")
      AudioRecord.expects(:find).with("my:_PID3_")
      ActiveFedora::SolrService.reify_solr_results(@sample_solr_hits)
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

  describe ".query" do
    it "should call rubydora" do 
      mock_conn = mock("Connection")
      stub_result = stub("Result")
      mock_conn.expects(:get).with('select', :params=>{:q=>'querytext', :qt=>'standard'}).returns(stub_result)
      ActiveFedora::SolrService.stubs(:instance =>stub("instance", :conn=>mock_conn))
      ActiveFedora::SolrService.query('querytext', :raw=>true).should == stub_result
    end
  end
  
end
