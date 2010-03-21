require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require 'mocha'

include Mocha::Standalone

describe ActiveFedora::Relationship do
  
  %/
  module ModelSpec
    class AudioRecord
      include ActiveFedora::Model

      relationship "parents", :is_part_of, [nil, :oral_history]      
    end
    
    class OralHistory
      include ActiveFedora::Model
      
      relationship "parts", :is_part_of, [:audio_record], :inbound => true
  end
  /%
  before(:each) do
    @test_relationship = ActiveFedora::Relationship.new
  end
  
  it "should provide #new" do
    ActiveFedora::Relationship.should respond_to(:new)
  end
  
  describe "#new" do
    test_relationship = ActiveFedora::Relationship.new(:subject => "demo:5", :predicate => "isMemberOf", :object => "demo:10")
    
    test_relationship.subject.should == "info:fedora/demo:5"
    test_relationship.predicate.should == "isMemberOf"
    test_relationship.object.should == "info:fedora/demo:10"
  end
  
  describe "#subject=" do
    it "should turn strings into fedora URIs" do
      @test_relationship.subject = "demo:6"
      @test_relationship.subject.should == "info:fedora/demo:6"
      @test_relationship.subject = "info:fedora/demo:7"
      @test_relationship.subject.should == "info:fedora/demo:7"
    end
    it "should use the pid of the passed object if it responds to #pid" do
      mock_fedora_object = stub("mock_fedora_object", :pid => "demo:stub_pid")
      @test_relationship.subject = mock_fedora_object
      @test_relationship.subject.should == "info:fedora/#{mock_fedora_object.pid}"
    end
  end
  
  describe "#object=" do
    it "should turn strings into Fedora URIs" do
      @test_relationship.object = "demo:11"
      @test_relationship.object.should == "info:fedora/demo:11"
    end
    it "should use the pid of the passed object if it responds to #pid" do
      mock_fedora_object = stub("mock_fedora_object", :pid => "demo:stub_pid")
      @test_relationship.object = mock_fedora_object
      @test_relationship.object.should == "info:fedora/#{mock_fedora_object.pid}"
    end  end
  
  describe "#predicate=" do
    it "should default to setting the argument itself as the new subject" do
      @test_relationship.predicate = "isComponentOf"
      @test_relationship.predicate.should == "isComponentOf"
    end
  end
  
  describe "#to_hash" do
    it "should return a hash of structure {subject => {predicate => [object]}}"
  end
  
end
