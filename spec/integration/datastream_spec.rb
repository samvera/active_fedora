require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require 'ftools'

describe ActiveFedora::Datastream do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
    puts @test_object.inspect
    @test_object.save
  end
  
  after(:each) do
    @test_object.delete
  end
  
  it "should be able to access Datastreams using datastreams method" do    
    dc = @test_object.datastreams["DC"]
    dc.should be_an_instance_of(ActiveFedora::Datastream)
    dc.attributes.should be_an_instance_of(Hash)
    dc.attributes["dsid"].to_s.should eql("DC")
    dc.attributes[:pid].should_not be_nil
    # dc.control_group.should == "X"
  end
  
  it "should be able to access Datastream content using content method" do    
    dc = @test_object.datastreams["DC"].content
    dc.should_not be_nil
  end
  
  it "should be able to update XML Datastream content and save to Fedora" do    
    xml_content =REXML::Document.new(@test_object.datastreams["DC"].content)
    title = REXML::Element.new "dc:title"
    title.text = "Test Title"
    xml_content.root.elements << title
    
    @test_object.datastreams["DC"].content = xml_content.to_s
    @test_object.datastreams["DC"].save
    
    @test_object.datastreams["DC"].content.should eql(Fedora::Repository.instance.fetch_custom(@test_object.pid, "datastreams/DC/content"))
  end
  
  it "should be able to update Blob Datastream content and save to Fedora" do    
    dsid = "ds#{Time.now.to_i}"
    ds = ActiveFedora::Datastream.new(:dsID => dsid, :dsLabel => 'hello', :altIDs => '3333', 
      :controlGroup => 'M', :blob => fixture('dino.jpg'))
    File.identical?(ds.blob, fixture('dino.jpg')).should be_true
    @test_object.add_datastream(ds).should be_true
    @test_object.save
    to = ActiveFedora::Base.load_instance(@test_object.pid) 
    to.should_not be_nil 
    to.datastreams[dsid].should_not be_nil
    # to.datastreams[dsid].control_group.should == "M"
    to.datastreams[dsid].content.length.should eql(fixture('dino.jpg').read.length)
    
  end
  
end
