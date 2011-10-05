require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require "nokogiri"
require 'ftools'

describe ActiveFedora::RelsExtDatastream do
  
  before(:all) do
    @pid = "test:sample_pid"
    @test_relationship1 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "demo:10")  
    @test_relationship2 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_part_of, :object => "demo:11")  
    @test_relationship3 = ActiveFedora::Relationship.new(:subject => @pid, :predicate => :has_part, :object => "demo:12")  
    @test_relationship4 = ActiveFedora::Relationship.new(:subject => @pid, :predicate => :conforms_to, :object => "AnInterface", :is_literal=>true)  
  
    @sample_xml = Nokogiri::XML::Document.parse(@sample_xml_string)
  end
  
  before(:each) do
      mock_inner = mock('inner object')
      @mock_repo = mock('repository')
      @mock_repo.stubs(:datastream_dissemination=>'My Content')
      mock_inner.stubs(:repository).returns(@mock_repo)
      mock_inner.stubs(:pid).returns(@pid)
      @test_ds = ActiveFedora::RelsExtDatastream.new(mock_inner, "RELS-EXT")
  end
  
  it 'should respond to #save' do
    @test_ds.should respond_to(:save)
  end
  
  describe '#serialize!' do
    
    it "should generate new rdf/xml as the datastream content if the object has been changed" do
      @test_ds.register_triple(:self, :is_member_of, "demo:10") 
      @test_ds.serialize!
      @test_ds.content.should == "      <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>\n        <rdf:Description rdf:about='info:fedora/test:sample_pid'>\n        <isMemberOf rdf:resource='demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/></rdf:Description>\n      </rdf:RDF>\n"
    end
  
  end
  
  describe "#from_xml" do
    before(:all) do
      @test_obj = ActiveFedora::Base.new
      @test_obj.add_relationship(:is_member_of, "demo:10")
      @test_obj.add_relationship(:is_part_of, "demo:11")
      @test_obj.add_relationship(:conforms_to, "AnInterface", true)
      @test_obj.save
    end
    after(:all) do
      @test_obj.delete
    end
    it "should load RELS-EXT relationships into relationships hash" do
      @test_obj.relationships.should == {:self=>{:is_member_of=>["info:fedora/demo:10"], :is_part_of=>["info:fedora/demo:11"], :has_model=>["info:fedora/afmodel:ActiveFedora_Base"], :conforms_to=>["AnInterface"]}}
      new_ds = ActiveFedora::RelsExtDatastream.new(nil, nil)
      new_ds.relationships.should == {:self=>{}}
      ActiveFedora::RelsExtDatastream.from_xml(@test_obj.rels_ext.content,new_ds)
      new_ds.relationships.should == @test_obj.relationships
    end
    it "should handle un-mapped predicates gracefully" do
      @test_obj.relationships.should == {:self=>{:is_member_of=>["info:fedora/demo:10"], :is_part_of=>["info:fedora/demo:11"], :has_model=>["info:fedora/afmodel:ActiveFedora_Base"], :conforms_to=>["AnInterface"]}}
      @test_obj.add_relationship("foo", "foo:bar")
      @test_obj.save
      @test_obj.relationships.should == {:self=>{:is_part_of=>["info:fedora/demo:11"], "foo"=>["info:fedora/foo:bar"], :has_model=>["info:fedora/afmodel:ActiveFedora_Base"], :is_member_of=>["info:fedora/demo:10"], :conforms_to=>["AnInterface"]}}
    end
  end
  
  
  describe ".to_solr" do
    
    it "should provide .to_solr and return a SolrDocument" do
      @test_ds.should respond_to(:to_solr)
      @test_ds.to_solr.should be_kind_of(Hash)
    end
    
    it "should serialize the relationships into a Hash" do
      @test_ds.add_relationship(@test_relationship1)
      @test_ds.add_relationship(@test_relationship2)
      @test_ds.add_relationship(@test_relationship3)
      @test_ds.add_relationship(@test_relationship4)
      solr_doc = @test_ds.to_solr
      solr_doc["is_member_of_s"].should == ["info:fedora/demo:10"]
      solr_doc["is_part_of_s"].should == ["info:fedora/demo:11"]
      solr_doc["has_part_s"].should == ["info:fedora/demo:12"]
      solr_doc["conforms_to_s"].should == ["AnInterface"]
    end
  end
  
  it "should treat :self and self.pid as equivalent subjects"
  
end
