require 'spec_helper'

describe ActiveFedora::SolrService do
  before do
    Thread.current[:solr_service] = nil
  end

  after(:all) do
    described_class.register(ActiveFedora.solr_config[:url])
  end

  it "takes a n-arg constructor and configure for localhost" do
    expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr')
    described_class.register
  end
  it "accepts host arg into constructor" do
    expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://fubar')
    described_class.register('http://fubar')
  end
  it "clobbers options" do
    expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr', autocommit: :off, foo: :bar)
    described_class.register(nil, autocommit: :off, foo: :bar)
  end

  it "sets the threadlocal solr service" do
    expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr', autocommit: :off, foo: :bar)
    ss = described_class.register(nil, autocommit: :off, foo: :bar)
    expect(Thread.current[:solr_service]).to eq ss
    expect(described_class.instance).to eq ss
  end
  it "tries to initialize if the service not initialized, and fail if it does not succeed" do
    expect(Thread.current[:solr_service]).to be_nil
    expect(described_class).to receive(:register)
    expect(proc { described_class.instance }).to raise_error(ActiveFedora::SolrNotInitialized)
  end

  describe '#construct_query_for_pids' do
    it "generates a useable solr query from an array of Fedora ids" do
      expect(Deprecation).to receive(:warn)
      expect(described_class.construct_query_for_pids(["my:_ID1_", "my:_ID2_", "my:_ID3_"])).to eq '{!terms f=id}my:_ID1_,my:_ID2_,my:_ID3_'
    end
  end

  describe ".query" do
    it "calls solr" do
      mock_conn = double("Connection")
      stub_result = double("Result")
      expect(mock_conn).to receive(:get).with('select', params: { q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.query('querytext', raw: true)).to eq stub_result
    end
  end
  describe ".count" do
    it "returns a count of matching records" do
      mock_conn = double("Connection")
      stub_result = { 'response' => { 'numFound' => '7' } }
      expect(mock_conn).to receive(:get).with('select', params: { rows: 0, q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.count('querytext')).to eq 7
    end
    it "accepts query args" do
      mock_conn = double("Connection")
      stub_result = { 'response' => { 'numFound' => '7' } }
      expect(mock_conn).to receive(:get).with('select', params: { rows: 0, q: 'querytext', qt: 'standard', fq: 'filter' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.count('querytext', fq: 'filter', rows: 10)).to eq 7
    end
  end

  describe ".add" do
    it "calls solr" do
      mock_conn = double("Connection")
      doc = { 'id' => '1234' }
      expect(mock_conn).to receive(:add).with(doc, params: {})
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.add(doc)
    end
  end

  describe ".commit" do
    it "calls solr" do
      mock_conn = double("Connection")
      expect(mock_conn).to receive(:commit)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.commit
    end
  end
end
