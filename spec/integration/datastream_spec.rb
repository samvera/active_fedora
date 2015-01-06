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
    expect(dc).to be_an_instance_of(ActiveFedora::Datastream)
    expect(dc.dsid).to eql("DC")
    expect(dc.pid).not_to be_nil
    # dc.control_group.should == "X"
  end

  it "should be able to access Datastream content using content method" do
    dc = @test_object.datastreams["DC"].content
    expect(dc).not_to be_nil
  end

  it "should be able to update XML Datastream content and save to Fedora" do
    xml_content = Nokogiri::XML::Document.parse(@test_object.datastreams["DC"].content)
    title = Nokogiri::XML::Element.new "title", xml_content
    title.content = "Test Title"
    title.namespace = xml_content.xpath('//oai_dc:dc/dc:identifier').first.namespace
    xml_content.root.add_child title

    allow(@test_object.datastreams["DC"]).to receive(:before_save)
    @test_object.datastreams["DC"].content = xml_content.to_s
    @test_object.datastreams["DC"].save

    found = Nokogiri::XML::Document.parse(@test_object.class.find(@test_object.pid).datastreams['DC'].content)
    expect(found.xpath('*/dc:title/text()').first.inner_text).to eq(title.content)
  end

  it "should be able to update Blob Datastream content and save to Fedora" do
    dsid = "ds#{Time.now.to_i}"
    ds = ActiveFedora::Datastream.new(@test_object.inner_object, dsid)
    ds.content = fixture('dino.jpg')
    expect(@test_object.add_datastream(ds)).to be_truthy
    @test_object.save
    expect(@test_object.datastreams[dsid]).not_to be_changed
    to = ActiveFedora::Base.find(@test_object.pid)
    expect(to).not_to be_nil
    expect(to.datastreams[dsid]).not_to be_nil
    expect(to.datastreams[dsid].content).to eq(fixture('dino.jpg').read)
  end

  it "should be able to set the versionable attribute" do
    dsid = "ds#{Time.now.to_i}"
    v1 = "<version1>data</version1>"
    v2 = "<version2>data</version2>"
    ds = ActiveFedora::Datastream.new(@test_object.inner_object, dsid)
    ds.content = v1
    ds.versionable = false
    expect(@test_object.add_datastream(ds)).to be_truthy
    @test_object.save
    to = ActiveFedora::Base.find(@test_object.pid)
    ds = to.datastreams[dsid]
    expect(ds.versionable).to be_falsey
    ds.versionable = true
    to.save
    ds.content = v2
    to.save
    versions = ds.versions
    expect(versions.length).to eq(2)
    # order of versions not guaranteed
    if versions[0].content == v2
      expect(versions[1].content).to eq(v1)
      expect(versions[0].asOfDateTime).to be >= versions[1].asOfDateTime
    else
      expect(versions[0].content).to eq(v1)
      expect(versions[1].content).to eq(v2)
      expect(versions[1].asOfDateTime).to be >= versions[0].asOfDateTime
    end
    expect(ds.content).to eq(v2)
  end
end
