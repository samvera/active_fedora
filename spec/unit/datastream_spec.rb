require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require 'ftools'

describe ActiveFedora::Datastream do
  
  before(:each) do
    Fedora::Repository.instance.expects(:nextid).returns("foo")
    @test_object = ActiveFedora::Base.new
    @test_datastream = ActiveFedora::Datastream.new(:pid=>@test_object.pid, :dsid=>'abcd', :blob=>StringIO.new("hi there"))
  end

  it "should implement delete" do
    Fedora::Repository.instance.expects(:delete).with('foo/datastreams/abcd').returns(true).times(2)
    @test_datastream.delete.should == true
    ActiveFedora::Datastream.delete('foo', 'abcd').should == true
  end
  
  it "should set control_group" do
    xml=<<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <foxml:datastream xmlns:foxml="foo" ID="Addelson_Frances19971114_FINAL.doc" STATE="A" CONTROL_GROUP="M" VERSIONABLE="true">
        <foxml:datastreamVersion ID="Addelson_Frances19971114_FINAL.doc.0" LABEL="Addelson_Frances19971114_FINAL.doc" CREATED="2008-11-19T18:18:46.631Z" MIMETYPE="application/msword">
          <foxml:contentLocation TYPE="INTERNAL_ID" REF="changeme:551+Addelson_Frances19971114_FINAL.doc+Addelson_Frances19971114_FINAL.doc.0"/>
        </foxml:datastreamVersion>
      </foxml:datastream>
    EOF
    n = ActiveFedora::Datastream.from_xml(ActiveFedora::Datastream.new, REXML::Document.new(xml).elements.first)
    n.control_group.should == 'M'

  end

  it "should escape dots in  to_param" do
    @test_datastream.stubs(:dsid).returns('foo.bar')
    @test_datastream.to_param.should == 'foo%2ebar'
  end
  
  it 'should provide #save, #before_save and #after_save' do
    @test_datastream.should respond_to(:save)
    @test_datastream.should respond_to(:before_save)
    @test_datastream.should respond_to(:after_save)
  end
  
  describe '#save' do
    it 'should call #before_save and #after_save' do
      Fedora::Repository.instance.stubs(:save)
      @test_datastream.stubs(:last_modified_in_repository)
      @test_datastream.expects(:before_save)
      @test_datastream.expects(:after_save)
      @test_datastream.save
    end
    
    it "should set @dirty to false" do
      Fedora::Repository.instance.stubs(:save)
      #@test_datastream.stubs(:last_modified_in_repository)
      @test_datastream.expects(:dirty=).with(false)
      @test_datastream.save
    end
  end
  
  describe ".dirty?" do
    it "should return the value of the @dirty attribute" do
      @test_datastream.dirty.should equal(@test_datastream.dirty?)
      @test_datastream.dirty = "boo"
      @test_datastream.dirty?.should == "boo"    
    end
  end 
  
  describe ".dsid=" do
    it "should set the datastream's dsid" do
      @test_datastream.dsid = "foodsid"
      @test_datastream.dsid.should == "foodsid"
    end
  end 
  
  it "should have mime_type accessors and should allow you to pass :mime_type OR :mimeType as an argument to initialize block" do
    ds1 = ActiveFedora::Datastream.new(:mime_type=>"text/foo")    
    ds1.mime_type.should == "text/foo"
    ds2 = ActiveFedora::Datastream.new(:mime_type=>"text/bar")
    ds2.mime_type.should == "text/bar"
  end
  
end
