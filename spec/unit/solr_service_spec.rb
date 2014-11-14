require 'spec_helper'

describe ActiveFedora::SolrService do
  before do
    Thread.current[:solr_service]=nil
  end
  
  after(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end
  
  it "should take a n-arg constructor and configure for localhost" do
    expect(RSolr).to receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://localhost:8080/solr')
    ActiveFedora::SolrService.register
  end
  it "should accept host arg into constructor" do
    expect(RSolr).to receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://fubar')
    ActiveFedora::SolrService.register('http://fubar')
  end
  it "should clobber options" do
    expect(RSolr).to receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://localhost:8080/solr', :autocommit=>:off, :foo=>:bar)
    ActiveFedora::SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
  end

  it "should set the threadlocal solr service" do
    expect(RSolr).to receive(:connect).with(:read_timeout => 120, :open_timeout => 120, :url => 'http://localhost:8080/solr', :autocommit=>:off, :foo=>:bar)
    ss = ActiveFedora::SolrService.register(nil, {:autocommit=>:off, :foo=>:bar})
    expect(Thread.current[:solr_service]).to eq ss
    expect(ActiveFedora::SolrService.instance).to eq ss
  end
  it "should try to initialize if the service not initialized, and fail if it does not succeed" do
    expect(Thread.current[:solr_service]).to be_nil
    expect(ActiveFedora::SolrService).to receive(:register)
    expect(proc{ActiveFedora::SolrService.instance}).to raise_error(ActiveFedora::SolrNotInitialized)
  end

  describe "reify solr results" do
    before(:all) do
      class AudioRecord
        attr_accessor :id
        def self.connection_for_id(id)
        end
      end
      @sample_solr_hits = [{"id"=>"my:_ID1_", ActiveFedora::SolrService.solr_name("has_model", :symbol)=>["AudioRecord"]},
                           {"id"=>"my:_ID2_", ActiveFedora::SolrService.solr_name("has_model", :symbol)=>["AudioRecord"]},
                           {"id"=>"my:_ID3_", ActiveFedora::SolrService.solr_name("has_model", :symbol)=>["AudioRecord"]}]
    end
    describe ".reify_solr_result" do
      it "should use .find to instantiate objects" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        ActiveFedora::SolrService.reify_solr_result(@sample_solr_hits.first)
      end
    end
    describe ".reify_solr_results" do
      it "should use AudioRecord.find to instantiate objects" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID2_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID3_", cast: true)
        ActiveFedora::SolrService.reify_solr_results(@sample_solr_hits)
      end
    end
    describe ".lazy_reify_solr_results" do
      it "should lazily reify solr results" do
        expect(AudioRecord).to receive(:find).with("my:_ID1_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID2_", cast: true)
        expect(AudioRecord).to receive(:find).with("my:_ID3_", cast: true)
        ActiveFedora::SolrService.lazy_reify_solr_results(@sample_solr_hits).each {|r| r}
      end
    end
  end

  describe "raw_query" do
    it "should generate a raw query clause" do
      expect(ActiveFedora::SolrService.raw_query('id', "my:_ID1_")).to eq '_query_:"{!raw f=id}my:_ID1_"'
    end
  end

  describe '#construct_query_for_ids' do
    it "should generate a useable solr query from an array of Fedora ids" do
      expect(ActiveFedora::SolrService.construct_query_for_ids(["my:_ID1_", "my:_ID2_", "my:_ID3_"])).to eq '_query_:"{!raw f=id}my:_ID1_" OR _query_:"{!raw f=id}my:_ID2_" OR _query_:"{!raw f=id}my:_ID3_"'

    end
    it "should return a valid solr query even if given an empty array as input" do
      expect(ActiveFedora::SolrService.construct_query_for_ids([""])).to eq "id:NEVER_USE_THIS_ID"
    end
  end

  describe '#construct_query_for_pids' do
    it "should generate a useable solr query from an array of Fedora ids" do
      expect(Deprecation).to receive(:warn)
      expect(ActiveFedora::SolrService.construct_query_for_pids(["my:_ID1_", "my:_ID2_", "my:_ID3_"])).to eq '_query_:"{!raw f=id}my:_ID1_" OR _query_:"{!raw f=id}my:_ID2_" OR _query_:"{!raw f=id}my:_ID3_"'

    end
  end

  describe ".query" do
    it "should call solr" do
      mock_conn = double("Connection")
      stub_result = double("Result")
      expect(mock_conn).to receive(:get).with('select', :params=>{:q=>'querytext', :qt=>'standard'}).and_return(stub_result)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(ActiveFedora::SolrService.query('querytext', :raw=>true)).to eq stub_result
    end
  end
  describe ".count" do
    it "should return a count of matching records" do
      mock_conn = double("Connection")
      stub_result = {'response' => {'numFound'=>'7'}}
      expect(mock_conn).to receive(:get).with('select', :params=>{:rows=>0, :q=>'querytext', :qt=>'standard'}).and_return(stub_result)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(ActiveFedora::SolrService.count('querytext')).to eq 7
    end
    it "should accept query args" do
      mock_conn = double("Connection")
      stub_result = {'response' => {'numFound'=>'7'}}
      expect(mock_conn).to receive(:get).with('select', :params=>{:rows=>0, :q=>'querytext', :qt=>'standard', :fq=>'filter'}).and_return(stub_result)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(ActiveFedora::SolrService.count('querytext', :fq=>'filter', :rows=>10)).to eq 7
    end
  end
  describe ".add" do
    it "should call solr" do
      mock_conn = double("Connection")
      doc = {'id' => '1234'}
      expect(mock_conn).to receive(:add).with(doc, {:params=>{}})
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(double("instance", conn: mock_conn))
      ActiveFedora::SolrService.add(doc)
    end
  end
  describe ".commit" do
    it "should call solr" do
      mock_conn = double("Connection")
      doc = {'id' => '1234'}
      expect(mock_conn).to receive(:commit)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(double("instance", conn: mock_conn))
      ActiveFedora::SolrService.commit()
    end
  end
end
