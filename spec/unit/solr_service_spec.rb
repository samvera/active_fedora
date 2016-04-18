require 'spec_helper'

describe ActiveFedora::SolrService do
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  describe '#conn' do
    it "takes a n-arg constructor and configure for localhost" do
      expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr')
      described_class.register.conn
    end
    it "accepts host arg into constructor" do
      expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://fubar')
      Deprecation.silence(described_class) do
        described_class.register('http://fubar').conn
      end
    end
    it "clobbers options" do
      expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr', autocommit: :off, foo: :bar)
      described_class.register(autocommit: :off, foo: :bar).conn
    end
  end

  describe '#conn=' do
    let(:new_connection) { double }
    it 'is settable' do
      described_class.instance.conn = new_connection
      expect(described_class.instance.conn).to eq new_connection
    end
  end

  describe '.instance' do
    it "sets the threadlocal solr service" do
      ss = described_class.register(autocommit: :off, foo: :bar)
      expect(ActiveFedora::RuntimeRegistry.solr_service).to eq ss
      expect(described_class.instance).to eq ss
    end
    it "tries to initialize if the service not initialized, and fail if it does not succeed" do
      expect(described_class).to receive(:register)
      expect(proc { described_class.instance }).to raise_error(ActiveFedora::SolrNotInitialized)
    end
    it "passes on solr_config when initializing the service" do
      allow(RSolr).to receive(:connect)
      allow(ActiveFedora).to receive(:solr_config).and_return(url: 'http://fubar', update_path: 'update_test')
      expect(described_class).to receive(:register).with(hash_including(url: 'http://fubar', update_path: 'update_test')).and_call_original
      described_class.instance
    end
  end

  describe '#construct_query_for_pids' do
    it "generates a useable solr query from an array of Fedora ids" do
      expect(Deprecation).to receive(:warn)
      expect(described_class.construct_query_for_pids(["my:_ID1_", "my:_ID2_", "my:_ID3_"])).to eq '{!terms f=id}my:_ID1_,my:_ID2_,my:_ID3_'
    end
  end

  describe "#get" do
    it "calls solr" do
      mock_conn = double("Connection")
      stub_result = double("Result")
      expect(mock_conn).to receive(:get).with('select', params: { q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.get('querytext')).to eq stub_result
    end
    it "uses select_path" do
      mock_conn = double("Connection")
      stub_result = double("Result")
      expect(mock_conn).to receive(:get).with('select_test', params: { q: 'querytext', qt: 'standard' }).and_return(stub_result)
      expect(described_class).to receive(:select_path).and_return('select_test')
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.get('querytext')).to eq stub_result
    end
  end

  describe "#query" do
    let(:doc) { { 'id' => 'x' } }
    let(:docs) { [doc] }

    it "wraps the solr response documents in Solr hits" do
      mock_conn = double("Connection")
      stub_result = { 'response' => { 'docs' => docs } }
      expect(mock_conn).to receive(:get).with('select', params: { q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      result = described_class.query('querytext')
      expect(result.size).to eq 1
      expect(result.first.id).to eq 'x'
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
  describe ".select_path" do
    it "gets :select_path from solr_config" do
      expect(ActiveFedora).to receive(:solr_config).and_return(select_path: 'select_test')
      expect(described_class.select_path).to eq 'select_test'
    end
    it "uses 'select' as default" do
      expect(ActiveFedora).to receive(:solr_config).and_return({})
      expect(described_class.select_path).to eq 'select'
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
