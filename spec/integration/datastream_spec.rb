require 'spec_helper'

require 'active_fedora'
require "rexml/document"

describe ActiveFedora::Datastream do

  context "when autocreate is true" do
    before(:all) do
      class MockAFBase < ActiveFedora::Base
        has_metadata "descMetadata", type: ActiveFedora::QualifiedDublinCoreDatastream, autocreate: true
      end
    end
  
    before do
      @test_object = MockAFBase.create
    end
    
    after do
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
      
      ds = @test_object.descMetadata
      ds.stub(:before_save)
      ds.content = xml_content.to_s
      ds.save
      
      found = Nokogiri::XML::Document.parse(@test_object.class.find(@test_object.pid).datastreams['descMetadata'].content)
      found.xpath('//dc/title/text()').first.inner_text.should == title.content
    end
    
    it "should be able to update Blob Datastream content and save to Fedora" do    
      dsid = "ds#{Time.now.to_i}"
      ds = ActiveFedora::Datastream.new(@test_object, dsid)
      ds.content = fixture('dino.jpg')
      @test_object.add_datastream(ds).should be_true
      @test_object.save
      @test_object.datastreams[dsid].should_not be_changed
      to = ActiveFedora::Base.find(@test_object.pid) 
      to.should_not be_nil 
      to.datastreams[dsid].should_not be_nil
      to.datastreams[dsid].content.should == fixture('dino.jpg').read
    end
    
  end
end
