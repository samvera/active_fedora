require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'

#
# This is moving towards replacing the ActiveFedora::Base class with an ActiveFedora::FedoraObject module.
# => Work put on hold 01 October 2008 to wait for re-implementation of Fedora::Repository as a singleton
#


describe ActiveFedora::FedoraObject do
  
  before :all do
    class Fobject
      include ActiveFedora::FedoraObject
    end
  end
  
  before(:each) do
    @test_object = Fobject.new
  end
  
  after(:each) do
    @test_object.delete
  end
  
  it "calling constructor should create a new Fedora Object" do    
    @test_object.should have(0).errors
    @test_object.pid.should_not be_nil
  end
  
  it "should return an Hash of the objects datastreams" do
    datastreams = @test_object.datastreams
    datastreams.should be_an_instance_of(Hash) 
    @test_object.datastreams["DC"].should be_an_instance_of(ActiveFedora::Datastream)
    datastreams["DC"].should_not be_nil
    datastreams["DC"].should be_an_instance_of(ActiveFedora::Datastream)       
    #datastreams["DC"].should be_an_instance_of(Hash)   
  end
  
  it "should expose the DC datastream using dc method" do
    dc = @test_object.dc
    dc.should be_an_instance_of(ActiveFedora::Datastream)
    rexml = REXML::Document.new(dc.content)
    rexml.root.elements["dc:identifier"].get_text.should_not be_nil
    #rexml.elements["dc:identifier"].should_not be_nil
  end
  
  it 'should respond to #rels_ext' do
    @test_object.should respond_to(:rels_ext)
  end
  
  describe '#rels_ext' do
    it 'should create the RELS-EXT datastream if it doesnt exist' do
      mocker = mock("rels-ext")
      ActiveFedora::RelsExtDatastream.expects(:new).returns(mocker)
      @test_object.expects(:add).with(mocker)
      # Make sure the RELS-EXT datastream does not exist yet
      @test_object.datastreams["RELS-EXT"].should == nil
      @test_object.rels_ext
      # Assume that @test_object.add actually does its job and adds the datastream to the datastreams array.  Not testing that here.
    end
    
    it 'should return the RelsExtDatastream object from the datastreams array' do
      @test_object.expects(:datastreams).returns({"RELS-EXT" => "foo"}).at_least_once
      @test_object.rels_ext.should == "foo"
    end
  end
  
  it "should be able to add datastreams" do
    ds = ActiveFedora::Datastream.new(:dsID => 'ds1.jpg', :dsLabel => 'hello', :altIDs => '3333', 
      :controlGroup => 'M', :blob => fixture('dino.jpg'))
    @test_object.add_datastream(ds).should be_true
    @test_object.save.should be_true
  end

end
