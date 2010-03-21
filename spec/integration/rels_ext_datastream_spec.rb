require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require 'ftools'

describe ActiveFedora::RelsExtDatastream do
  
  before(:all) do
    @sample_relationships_hash = Hash.new(:is_member_of => ["info:fedora/demo:5", "info:fedora/demo:10"])
    @sample_xml_string = <<-EOS
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      <rdf:Description rdf:about="info:fedora/changeme:475">
        <isMemberOf xmlns="info:fedora/fedora-system:def/relations-external#" rdf:resource="info:fedora/demo:5"></isMemberOf>
        <isMemberOf xmlns="info:fedora/fedora-system:def/relations-external#" rdf:resource="info:fedora/demo:10"></isMemberOf>
      </rdf:Description>
    </rdf:RDF>
    EOS
  
    @sample_xml = REXML::Document.new(@sample_xml_string)
  end
  
  before(:each) do
    @test_datastream = ActiveFedora::RelsExtDatastream.new
    @test_object = ActiveFedora::Base.new
    @test_object.save
    @test_relationships = [ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:5"), 
                              ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:10")]
  end
  
  after(:each) do
    @test_object.delete
  end
  
  
  describe '#save' do
    
    it "should generate new rdf/xml as the datastream content if the object has been changed" do
      @test_object.add_datastream(@test_datastream)
      @test_relationships.each do |rel|
        @test_datastream.add_relationship(rel)
      end
      rexml1 = REXML::Document.new(@test_datastream.to_rels_ext(@test_object.pid))
      @test_datastream.dirty = true
      @test_datastream.save
      rexml2 = REXML::Document.new(@test_object.datastreams["RELS-EXT"].content)
      rexml1.root.elements["rdf:Description"].inspect.should eql(rexml2.root.elements["rdf:Description"].inspect)
      #rexml1.root.elements["rdf:Description"].to_s.should eql(rexml2.root.elements["rdf:Description"].to_s)
      
      #rexml1.root.elements["rdf:Description"].each_element do |el|
      #  el.inspect.should eql(rexml2.root.elements["rdf:Description"][el.index_in_parent].inspect)
      #end
      
    end
  
  end
  
  it "should load relationships from fedora into parent object" do
    ActiveFedora::SemanticNode::PREDICATE_MAPPINGS.each_key do |p| 
      @test_object.add_relationship(p, "demo:#{rand(100)}")
    end
    @test_object.save
    # make sure that _something_ was actually added to the object's relationships hash
    @test_object.relationships[:self].should have_key(:is_member_of)
    ActiveFedora::Base.load_instance(@test_object.pid).relationships.should == @test_object.relationships
  end
end
