require File.join( File.dirname(__FILE__),  "../spec_helper" )

require "rexml/document"

describe Fedora::FedoraObject do
  
  before(:each) do
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
    @test_object = Fedora::FedoraObject.new(:pid=>"demo:1000")
    Fedora::Repository.instance.save(@test_object)
  end
  
  after(:each) do
    Fedora::Repository.instance.delete(@test_object)
  end
  
  describe '#object_xml' do
    it "should return XML with a root of digitalObject with namespace info:fedora/fedora-system:def/foxml#" do
      object_rexml = REXML::Document.new(@test_object.object_xml)
      object_rexml.root.name.should == "digitalObject"
      object_rexml.root.namespace.should == "info:fedora/fedora-system:def/foxml#"
      object_rexml.root.elements["foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state']"].attributes["VALUE"].should_not be_nil
    end
  end
  
  describe '#profile' do
    it "should return an array with misc Fedora Object attributes" do
      profile = @test_object.profile
      profile.class.should == Hash
      profile.empty?.should_not == true
      #profile.class.should_not be_empty
      profile.should have_key(:owner_id)
      profile[:owner_id].should == "fedoraAdmin"
      #profile.should have_key(:content_model)
      profile.should have_key(:label)
      profile.should have_key(:create_date)
      profile.should have_key(:modified_date)
      profile.should have_key(:methods_list_url)
      profile.should have_key(:datastreams_list_url)
      profile.should have_key(:state)
      profile[:state].should == "A"
      
    end
  end
  
  it "should allow access to fedora object info" do
    @test_object.label = "test"
    Fedora::Repository.instance.save(@test_object)
    obj = Fedora::Repository.instance.find_objects("pid=#{@test_object.pid}").first
    obj.pid.should == "demo:1000"
    obj.label.should == 'test'
    obj.state.should == 'A'
    obj.owner_id.should == 'fedoraAdmin'
  end
  
  describe "properties_from_fedora" do
    it" should return the object properties from fedora" do
      @test_object.label = "test"
      Fedora::Repository.instance.save(@test_object)
      properties = @test_object.properties_from_fedora     
      properties[:pid].should == "demo:1000" 
      properties[:state].should == 'A'
      properties[:create_date].should == @test_object.profile[:create_date]
      properties[:modified_date].should == @test_object.profile[:modified_date]
      properties[:label].should == 'test'
      properties[:owner_id].should == 'fedoraAdmin'
    end
    it "should not set :label if it is not there in the object_xml" do
      object_rexml = REXML::Document.new(@test_object.object_xml)
      # The label node will be missing from the FOXML because label was never set.
      object_rexml.root.elements["//foxml:property[@NAME='info:fedora/fedora-system:def/model#label']"].attributes["VALUE"].should == ""
      properties = @test_object.properties_from_fedora     
      properties[:label].should == nil 
    end
  end
  
  describe "load_attr_from_fedora" do
    it "should push all of the properties from fedora into the objects attributes" do
      @test_object.label = "test"
      Fedora::Repository.instance.save(@test_object)
      @test_object.attributes.should == {:pid=>"demo:1000", :label=>"test"}
      @test_object.load_attributes_from_fedora
      #{:create_date=>"2009-07-16T17:42:33.548Z", :label=>"test", :modified_date=>"2009-07-16T17:42:33.548Z", :state=>"Active", :pid=>"demo:1000", :owner_id=>"fedoraAdmin"} 
      @test_object.attributes[:pid].should == "demo:1000" 
      @test_object.attributes[:state].should == 'A'
      #@test_object.attributes[:state].should == 'Active'
      @test_object.attributes[:create_date].should == @test_object.profile[:create_date]
      @test_object.attributes[:modified_date].should == @test_object.profile[:modified_date]
      @test_object.attributes[:label].should == 'test'
      @test_object.attributes[:owner_id].should == 'fedoraAdmin'
    end
  end
  
  
end
