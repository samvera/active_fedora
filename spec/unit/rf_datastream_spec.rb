require File.join( File.dirname(__FILE__),  "../spec_helper" )

require 'ruby-fedora'


describe Fedora::Datastream do
  
  before(:each) do
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
    @test_datastream = Fedora::Datastream.new
  end
  
  it "should track the controlgroup attr" do
    td = Fedora::Datastream.new(:controlGroup=>'M')
    td.control_group.should == 'M'
  end
  
  it "should provide .url" do
    @test_datastream.should respond_to(:url)
    @test_datastream.expects(:pid).returns("_foo_")
    @test_datastream.url.should == 'http://localhost:8080/fedora/objects/_foo_/datastreams/'
  end
  
  describe ".url" do
    it "should return the Repository base_url with /objects/pid appended" do
      Fedora::Repository.instance.expects(:base_url).returns("BASE_URL")
      @test_datastream.expects(:pid).returns("_PID_")
      @test_datastream.expects(:dsid).returns("_DSID_")
      @test_datastream.url.should == "BASE_URL/objects/_PID_/datastreams/_DSID_"
    end
  end
  
  describe ".label" do
    it "should return the dsLabel attribute" do
      @test_datastream.label.should == @test_datastream.attributes[:dsLabel]
    end
  end
  
  describe ".label=" do
    it "should set the dsLabel attribute" do
      @test_datastream.label.should_not == "Foo dsLabel"
      @test_datastream.attributes[:dsLabel].should_not == "Foo dsLabel"
      @test_datastream.label = "Foo dsLabel"
      @test_datastream.label.should == "Foo dsLabel"
      @test_datastream.attributes[:dsLabel].should == "Foo dsLabel"
    end
  end

end
