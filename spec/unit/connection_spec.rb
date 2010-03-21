require File.join( File.dirname(__FILE__),  "../spec_helper" )

require 'active_resource'
require 'fedora/repository'

describe Fedora::Connection do
  it "should be creatable w/ a surrogate id" do
    c = Fedora::Connection.new('http://127.0.0.1/fedora', 'fubar', 'bob')
    c.site.to_s.should == "http://127.0.0.1/fedora"
    c.format.should == 'fubar'
    c.surrogate.should == 'bob'
  end
  it "should set a from header if surrogate defined." do
    c = Fedora::Connection.new('http://127.0.0.1/fedora', ActiveResource::Formats[:xml], 'bob')
    h = Hash.new
    r= c.send(:build_request_headers,h)
    r['From'].should == 'bob'
  end
  it "should not set a from header if surrogate undefined." do
    c = Fedora::Connection.new('http://127.0.0.1/fedora' )
    h = Hash.new
    r= c.send(:build_request_headers,h)
    r['From'].should be_nil
  end
end
