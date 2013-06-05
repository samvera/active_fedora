require 'spec_helper'

require 'active_fedora'
require "rexml/document"

describe ActiveFedora::Datastream do

  before(:all) do
    class MockAFBase < ActiveFedora::Base
      has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream, :autocreate => true
    end
  end
  
  before(:each) do
    @test_object = MockAFBase.new
    @test_object.save
  end
  
  after(:each) do
    @test_object.delete
  end

  it "should be able to access Datastreams using datastreams method" do
    descMetadata = @test_object.datastreams["descMetadata"]
    descMetadata.should be_a_kind_of(ActiveFedora::Datastream)
    descMetadata.dsid.should eql("descMetadata")
  end

  it "should be able to access Datastream content using content method" do    
    descMetadata = @test_object.datastreams["descMetadata"].content
    descMetadata.should_not be_nil
  end
  
  it "should be able to update XML Datastream content and save to Fedora" do    
    xml_content = Nokogiri::XML::Document.parse(@test_object.datastreams["descMetadata"].content)
    title = Nokogiri::XML::Element.new "title", xml_content
    title.content = "Test Title"
    xml_content.root.add_child title
    
    @test_object.datastreams["descMetadata"].stub(:before_save)
    @test_object.datastreams["descMetadata"].content = xml_content.to_s
    @test_object.datastreams["descMetadata"].save
    
    found = Nokogiri::XML::Document.parse(@test_object.class.find(@test_object.pid).datastreams['descMetadata'].content)
    found.xpath('//dc/title/text()').first.inner_text.should == title.content
  end
  
  it "should be able to update Blob Datastream content and save to Fedora" do    
    dsid = "ds#{Time.now.to_i}"
    ds = ActiveFedora::Datastream.new(@test_object.inner_object, dsid)
    ds.content = fixture('dino.jpg')
    @test_object.add_datastream(ds).should be_true
    @test_object.save
    @test_object.datastreams[dsid].should_not be_changed
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
    ds.content = v2
    to.save
    versions = ds.versions
    versions.length.should == 2
    # order of versions not guaranteed
    if versions[0].content == v2
      versions[1].content.should == v1
      versions[0].asOfDateTime.should be >= versions[1].asOfDateTime
    else
      versions[0].content.should == v1
      versions[1].content.should == v2   
      versions[1].asOfDateTime.should be >= versions[0].asOfDateTime
    end
    ds.content.should == v2
  end
end
