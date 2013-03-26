require "spec_helper"
require 'ostruct'
require 'webmock/rspec'
WebMock.allow_net_connect!
require "active_fedora/rspec_matchers/match_fedora_datastream_matcher"

describe RSpec::Matchers, "match_fedora_datastream" do
  let(:pid) { 123 }
  let(:expected_xml) { '<xml><node>Value</node></xml>' }
  let(:datastream_name) { 'metadata' }
  let(:datastream_url) {
    File.join(ActiveFedora.config.credentials[:url], 'objects', pid.to_s,'datastreams', datastream_name, 'content')
  }
  subject { OpenStruct.new(:pid => pid )}

  it 'should match based on request' do
    stub_request(:get, datastream_url).to_return(:body => expected_xml, :status => 200)
    subject.should match_fedora_datastream(datastream_name).with(expected_xml)
  end

  it 'should handle non-matching requests' do
    stub_request(:get, datastream_url).to_return(:body => "<parent>#{expected_xml}</parent>", :status => 200)
    lambda {
      subject.should match_fedora_datastream(datastream_name).with(expected_xml)
    }.should(
      raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /expected #{subject.class} PID=#{pid} datastream: #{datastream_name.inspect} to match Fedora/
      )
    )
  end

  it 'should require :with option' do
    stub_request(:get, datastream_url).to_return(:body => "<parent>#{expected_xml}</parent>", :status => 200)
    lambda {
      subject.should match_fedora_datastream(datastream_name)
    }.should(
      raise_error(
        ArgumentError,
        "match_fedora_datastream(<datastream_name>).with(<expected_xml>)"
      )
    )
  end
end
