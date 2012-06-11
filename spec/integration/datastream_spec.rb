require 'spec_helper'

require 'active_fedora'
require "rexml/document"

describe ActiveFedora::Datastream do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_object.save
  end
  
  after(:each) do
    @test_object.delete
  end
  
  it "should be able to access Datastreams using datastreams method" do    
    dc = @test_object.datastreams["DC"]
    dc.should be_an_instance_of(ActiveFedora::Datastream)
    dc.dsid.should eql("DC")
    dc.pid.should_not be_nil
    # dc.control_group.should == "X"
  end
  
  it "should be able to access Datastream content using content method" do    
    dc = @test_object.datastreams["DC"].content
    dc.should_not be_nil
  end
  
  it "should be able to update XML Datastream content and save to Fedora" do    
    xml_content = Nokogiri::XML::Document.parse(@test_object.datastreams["DC"].content)
    title = Nokogiri::XML::Element.new "title", xml_content
    title.content = "Test Title"
    title.namespace = xml_content.xpath('//oai_dc:dc/dc:identifier').first.namespace
    xml_content.root.add_child title
    
    @test_object.datastreams["DC"].stubs(:before_save)
    @test_object.datastreams["DC"].content = xml_content.to_s
    @test_object.datastreams["DC"].save
    
    found = Nokogiri::XML::Document.parse(@test_object.class.find(@test_object.pid).datastreams['DC'].content)
    found.xpath('*/dc:title/text()').first.inner_text.should == title.content
  end
  
  it "should be able to update Blob Datastream content and save to Fedora" do    
    dsid = "ds#{Time.now.to_i}"
    ds = ActiveFedora::Datastream.new(@test_object.inner_object, dsid)
    ds.content = fixture('dino.jpg')
    @test_object.add_datastream(ds).should be_true
    @test_object.save
    to = ActiveFedora::Base.find(@test_object.pid) 
    to.should_not be_nil 
    to.datastreams[dsid].should_not be_nil
    to.datastreams[dsid].content.should == fixture('dino.jpg').read
    
  end
  
  it "should be able to set the versionable attribute" do
    dsid = "ds#{Time.now.to_i}"
    v1 = "<version1>data</version1>"
    v2 = "<version2>data</version2>"
    ds = ActiveFedora::Datastream.new(@test_object.inner_object, dsid)
    ds.content = v1
    ds.versionable = false
    @test_object.add_datastream(ds).should be_true
    @test_object.save
    to = ActiveFedora::Base.find(@test_object.pid)
    ds = to.datastreams[dsid]
    ds.versionable.should be_false
    ds.versionable = true
    to.save
    timestamp = Time.now.utc
    ms = timestamp.usec / 1000
    timestamp = timestamp.strftime("%Y-%m-%dT%H:%M:%S") + ".#{ms.to_s}Z"
    ds.content = v2
    to.save
    versions = ds.versions
    versions.length.should == 2   
    ds.content.should == v2
    ds.asOfDateTime(timestamp).content.should == v1
  end
end
