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
    allow(streamer).to receive(:authorization_key).and_return("authorization_key")
    streamer
  end

  context "without ssl" do
    let(:uri) { "http://localhost/file/1" }

    it do
      expect(Net::HTTP).to receive(:start).with('localhost', 80, use_ssl: false).and_return(nil)
      streamer.stream.each
    end
  end

  context "with ssl" do
    let(:uri) { "https://localhost/file/1" }

    it do
      expect(Net::HTTP).to receive(:start).with('localhost', 443, use_ssl: true).and_return(nil)
      streamer.stream.each
    end
  end
end
