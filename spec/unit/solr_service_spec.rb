require 'spec_helper'

describe ActiveFedora::SolrService do
  before do
    Thread.current[:solr_service]=nil
  end
  
  after(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end
  
  it "should take a narg constructor and configure for localhost" do
    RSolr.should_receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://localhost:8080/solr')
    ActiveFedora::SolrService.register
  end
  it "should accept host arg into constructor" do
    RSolr.should_receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://fubar')
    ActiveFedora::SolrService.register('http://fubar')
  end
  it "should clobber options" do
    RSolr.should_receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://localhost:8080/solr', :autocommit=>:off, :foo=>:bar)
    ActiveFedora::SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
  end

  it "should set the threadlocal solr service" do
    RSolr.should_receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://localhost:8080/solr', :autocommit=>:off, :foo=>:bar)
    ss = ActiveFedora::SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
    Thread.current[:solr_service].should == ss
    ActiveFedora::SolrService.instance.should == ss
  end
  it "should try to initialize if the service not initialized, and fail if it does not succeed" do
    Thread.current[:solr_service].should be_nil
    ActiveFedora::SolrService.should_receive(:register)
    proc{ActiveFedora::SolrService.instance}.should raise_error(ActiveFedora::SolrNotInitialized)
  end

  describe "reify solr results" do
    before(:all) do
      class AudioRecord
        attr_accessor :pid
        def init_with(inner_obj)
          self.pid = inner_obj.pid
          self
        end
        def self.connection_for_pid(pid)
        end
      end
      @sample_solr_hits = [{"id"=>"my:_PID1_", ActiveFedora::SolrService.solr_name("has_model", :symbol)=>["info:fedora/afmodel:AudioRecord"]},
                           {"id"=>"my:_PID2_", ActiveFedora::SolrService.solr_name("has_model", :symbol)=>["info:fedora/afmodel:AudioRecord"]},
                           {"id"=>"my:_PID3_", ActiveFedora::SolrService.solr_name("has_model", :symbol)=>["info:fedora/afmodel:AudioRecord"]}]
    end
    describe ".reify_solr_result" do
      it "should use .find to instantiate objects" do
        AudioRecord.should_receive(:find).with("my:_PID1_", cast: true)
        ActiveFedora::SolrService.reify_solr_result(@sample_solr_hits.first)
      end
      it "should use .load_instance_from_solr when called with :load_from_solr option" do
        AudioRecord.should_receive(:load_instance_from_solr).with("my:_PID1_", @sample_solr_hits.first)
        ActiveFedora::SolrService.should_not_receive(:query)
        ActiveFedora::SolrService.reify_solr_result(@sample_solr_hits.first, load_from_solr: true)
      end
    end
    describe ".reify_solr_results" do
      it "should use AudioRecord.find to instantiate objects" do
        AudioRecord.should_receive(:find).with("my:_PID1_", cast: true)
        AudioRecord.should_receive(:find).with("my:_PID2_", cast: true)
        AudioRecord.should_receive(:find).with("my:_PID3_", cast: true)
        ActiveFedora::SolrService.reify_solr_results(@sample_solr_hits)
      end
      it "should use AudioRecord.load_instance_from_solr when called with :load_from_solr option" do
        AudioRecord.should_receive(:load_instance_from_solr).with("my:_PID1_", @sample_solr_hits[0])
        AudioRecord.should_receive(:load_instance_from_solr).with("my:_PID2_", @sample_solr_hits[1])
        AudioRecord.should_receive(:load_instance_from_solr).with("my:_PID3_", @sample_solr_hits[2])
        ActiveFedora::SolrService.should_not_receive(:query)
        ActiveFedora::SolrService.reify_solr_results(@sample_solr_hits, load_from_solr: true)
      end
    end
    describe ".lazy_reify_solr_results" do
      it "should lazily reify solr results" do
        AudioRecord.should_receive(:find).with("my:_PID1_", cast: true)
        AudioRecord.should_receive(:find).with("my:_PID2_", cast: true)
        AudioRecord.should_receive(:find).with("my:_PID3_", cast: true)
        ActiveFedora::SolrService.lazy_reify_solr_results(@sample_solr_hits).each {|r| r}
      end
      it "should use AudioRecord.load_instance_from_solr when called with :load_from_solr option" do
        AudioRecord.should_receive(:load_instance_from_solr).with("my:_PID1_", @sample_solr_hits[0])
        AudioRecord.should_receive(:load_instance_from_solr).with("my:_PID2_", @sample_solr_hits[1])
        AudioRecord.should_receive(:load_instance_from_solr).with("my:_PID3_", @sample_solr_hits[2])
        ActiveFedora::SolrService.should_not_receive(:query)
        ActiveFedora::SolrService.lazy_reify_solr_results(@sample_solr_hits, load_from_solr: true).each {|r| r}
      end
    end
  end

  describe "raw_query" do
    it "should generate a raw query clause" do
      expect(ActiveFedora::SolrService.raw_query('id', "my:_PID1_")).to eq '_query_:"{!raw f=id}my:_PID1_"'
    end
  end
  
  describe '#construct_query_for_pids' do
    it "should generate a useable solr query from an array of Fedora pids" do
      ActiveFedora::SolrService.construct_query_for_pids(["my:_PID1_", "my:_PID2_", "my:_PID3_"]).should == '_query_:"{!raw f=id}my:_PID1_" OR _query_:"{!raw f=id}my:_PID2_" OR _query_:"{!raw f=id}my:_PID3_"'

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
    it "should call solr" do 
      mock_conn = double("Connection")
      stub_result = double("Result")
      mock_conn.should_receive(:get).with('select', :params=>{:q=>'querytext', :qt=>'standard'}).and_return(stub_result)
      ActiveFedora::SolrService.stub(:instance =>double("instance", :conn=>mock_conn))
      ActiveFedora::SolrService.query('querytext', :raw=>true).should == stub_result
    end
  end
  describe ".count" do
    it "should return a count of matching records" do 
      mock_conn = double("Connection")
      stub_result = {'response' => {'numFound'=>'7'}}
      mock_conn.should_receive(:get).with('select', :params=>{:rows=>0, :q=>'querytext', :qt=>'standard'}).and_return(stub_result)
      ActiveFedora::SolrService.stub(:instance =>double("instance", :conn=>mock_conn))
      ActiveFedora::SolrService.count('querytext').should == 7 
    end
    it "should accept query args" do
      mock_conn = double("Connection")
      stub_result = {'response' => {'numFound'=>'7'}}
      mock_conn.should_receive(:get).with('select', :params=>{:rows=>0, :q=>'querytext', :qt=>'standard', :fq=>'filter'}).and_return(stub_result)
      ActiveFedora::SolrService.stub(:instance =>double("instance", :conn=>mock_conn))
      ActiveFedora::SolrService.count('querytext', :fq=>'filter', :rows=>10).should == 7 
    end
  end
  describe ".add" do
    it "should call solr" do 
      mock_conn = double("Connection")
      doc = {'id' => '1234'}
      mock_conn.should_receive(:add).with(doc, {:params=>{}})
      ActiveFedora::SolrService.stub(:instance =>double("instance", :conn=>mock_conn))
      ActiveFedora::SolrService.add(doc)
    end
  end
  describe ".commit" do
    it "should call solr" do 
      mock_conn = double("Connection")
      doc = {'id' => '1234'}
      mock_conn.should_receive(:commit)
      ActiveFedora::SolrService.stub(:instance =>double("instance", :conn=>mock_conn))
      ActiveFedora::SolrService.commit()
    end
  end
  
end
