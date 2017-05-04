require 'spec_helper'

describe ActiveFedora::SolrService do
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  let(:mock_conn) { instance_double(RSolr::Client) }

  describe '#options' do
    it 'is readable' do
      expect(described_class.instance.options).to include :read_timeout, :open_timeout, :url
    end
  end

  describe '#conn' do
    it "takes a n-arg constructor and configure for localhost" do
      expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr')
      described_class.register.conn
    end
    it "clobbers options" do
      expect(RSolr).to receive(:connect).with(read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr', autocommit: :off, foo: :bar)
      described_class.register(autocommit: :off, foo: :bar).conn
    end
  end

  describe '#conn=' do
    it 'is settable' do
      described_class.instance.conn = mock_conn
      expect(described_class.instance.conn).to eq mock_conn
    end
  end

  describe '.instance' do
    it "sets the threadlocal solr service" do
      ss = described_class.register(autocommit: :off, foo: :bar)
      expect(ActiveFedora::RuntimeRegistry.solr_service).to eq ss
      expect(described_class.instance).to eq ss
    end
    it "passes on solr_config when initializing the service" do
      allow(RSolr).to receive(:connect)
      allow(ActiveFedora).to receive(:solr_config).and_return(url: 'http://fubar', update_path: 'update_test')
      expect(described_class).to receive(:register).with(hash_including(url: 'http://fubar', update_path: 'update_test')).and_call_original
      described_class.instance
    end
  end

  describe "#get" do
    it "calls solr" do
      stub_result = double("Result")
      expect(mock_conn).to receive(:get).with('select', params: { q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.get('querytext')).to eq stub_result
    end
    it "uses select_path" do
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
    let(:stub_result) { { 'response' => { 'docs' => docs } } }
    before do
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
    end

    it "wraps the solr response documents in Solr hits" do
      expect(mock_conn).to receive(:get).with('select', params: { rows: 2, q: 'querytext', qt: 'standard' }).and_return(stub_result)
      result = described_class.query('querytext', rows: 2)
      expect(result.size).to eq 1
      expect(result.first.id).to eq 'x'
    end

    it "warns about not passing rows" do
      allow(mock_conn).to receive(:get).and_return(stub_result)
      expect(ActiveFedora::Base.logger).to receive(:warn).with(/^Calling ActiveFedora::SolrService\.get without passing an explicit value for ':rows' is not recommended/)
      described_class.query('querytext')
    end
  end

  describe ".count" do
    it "returns a count of matching records" do
      stub_result = { 'response' => { 'numFound' => '7' } }
      expect(mock_conn).to receive(:get).with('select', params: { rows: 0, q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.count('querytext')).to eq 7
    end
    it "accepts query args" do
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
      doc = { 'id' => '1234' }
      expect(mock_conn).to receive(:add).with(doc, params: {})
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.add(doc)
    end
  end

  describe ".commit" do
    it "calls solr" do
      expect(mock_conn).to receive(:commit)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.commit
    end
  end
end
