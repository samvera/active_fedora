require 'spec_helper'

describe ActiveFedora::File::Streaming do
  let(:test_class) do
    tc = Class.new
    tc.send(:include, described_class)
    tc
  end
  let(:streamer) do
    streamer = test_class.new
    allow(streamer).to receive(:uri).and_return(uri)
    streamer
  end
  let(:http_client) { instance_double("Faraday::Connection") }

  before do
    allow(http_client).to receive(:get).and_return(nil)
  end

  context "without ssl" do
    let(:uri) { "http://localhost/file/1" }

    it do
      expect(Faraday).to receive(:new).with(ActiveFedora.fedora.host, {}).and_return(http_client)
      streamer.stream.each
    end
  end

  context "with ssl" do
    let(:uri) { "https://localhost/file/1" }

    before do
      allow(ActiveFedora.fedora).to receive(:ssl_options).and_return(true)
    end

    it do
      expect(Faraday).to receive(:new).with(ActiveFedora.fedora.host, hash_including(ssl: true)).and_return(http_client)
      streamer.stream.each
    end
  end
end
