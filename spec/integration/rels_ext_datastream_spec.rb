require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require 'ftools'

class MockAFRelsSolr < ActiveFedora::Base
  has_relationship "testing", :has_part, :type=>MockAFRelsSolr
  has_relationship "testing2", :has_member, :type=>MockAFRelsSolr
  has_relationship "testing_inbound", :has_part, :type=>MockAFRelsSolr, :inbound=>true
  has_relationship "testing_inbound2", :has_member, :type=>MockAFRelsSolr, :inbound=>true
end

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
    @test_object = ActiveFedora::Base.new
    @test_datastream = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
    @test_object.save
    @test_relationships = [ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:5"), 
                              ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:10")]
  end
  
  after(:each) do
    begin
    @test_object.delete
    rescue
    end
    begin
    @test_object2.delete
    rescue
    end
    begin
    @test_object3.delete
    rescue
    end
    begin
    @test_object4.delete
    rescue
    end
    begin
    @test_object5.delete
    rescue
    end
  end
  
  
  describe '#serialize!' do
    
    it "should generate new rdf/xml as the datastream content" do
      @test_object.add_datastream(@test_datastream)
      @test_relationships.each do |rel|
        @test_datastream.add_relationship(rel)
      end
      rexml1 = REXML::Document.new(@test_datastream.to_rels_ext(@test_object.pid))
      @test_datastream.serialize!
      rexml2 = REXML::Document.new(@test_object.datastreams["RELS-EXT"].content)
      rexml1.root.elements["rdf:Description"].inspect.should eql(rexml2.root.elements["rdf:Description"].inspect)
    end
  
  end
  
  it "should load relationships from fedora into parent object" do
    class SpecNode; include ActiveFedora::SemanticNode; end
    SpecNode.predicate_mappings[SpecNode.default_predicate_namespace].each_key do |p| 
      @test_object.add_relationship(p, "demo:#{rand(100)}")
    end
    @test_object.save
    # make sure that _something_ was actually added to the object's relationships hash
    @test_object.relationships[:self].should have_key(:is_member_of)
    o = ActiveFedora::Base.load_instance(@test_object.pid)
    ActiveFedora::Base.load_instance(@test_object.pid).relationships.should == @test_object.relationships
  end

  describe '#from_solr' do
    
    it "should respond_to from_solr" do
      @test_datastream.respond_to?(:from_solr).should be_true
    end
    
    it 'should populate the relationships hash based on data in solr only for any possible fedora predicates' do
      @test_object2 = MockAFRelsSolr.new
      #@test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFRelsSolr.new
      #@test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFRelsSolr.new
      #@test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFRelsSolr.new
      #@test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.testing_append(@test_object3)
      @test_object2.testing2_append(@test_object4)
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFRelsSolr))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      #get solr doc for @test_object2
      solr_doc = MockAFRelsSolr.find_by_solr(@test_object2.pid).hits.first
      test_from_solr_object2 = MockAFRelsSolr.new
      test_from_solr_object2.rels_ext.from_solr(solr_doc)
      solr_doc = MockAFRelsSolr.find_by_solr(@test_object3.pid).hits.first
      test_from_solr_object3 = MockAFRelsSolr.new
      test_from_solr_object3.rels_ext.from_solr(solr_doc)
      solr_doc = MockAFRelsSolr.find_by_solr(@test_object4.pid).hits.first
      test_from_solr_object4 = MockAFRelsSolr.new
      test_from_solr_object4.rels_ext.from_solr(solr_doc)
      solr_doc = MockAFRelsSolr.find_by_solr(@test_object5.pid).hits.first
      test_from_solr_object5 = MockAFRelsSolr.new
      test_from_solr_object5.rels_ext.from_solr(solr_doc)
      
      test_from_solr_object2.relationships.should == {:self=>{:has_part=>[r3.object],:has_member=>[r4.object],:has_model=>[model_rel.object]}}
      test_from_solr_object2.relationships_by_name.should == {:self=>{"testing"=>[r3.object],"testing2"=>[r4.object], "collection_members"=>[], "part_of"=>[], "parts_outbound"=>[r3.object]}}
      test_from_solr_object3.relationships.should == {:self=>{:has_model=>[model_rel.object]}}
      test_from_solr_object3.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}}
      test_from_solr_object4.relationships.should == {:self=>{:has_model=>[model_rel.object]}}
      test_from_solr_object4.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}}
      test_from_solr_object5.relationships.should == {:self=>{:has_model=>[model_rel.object],
                                                             :has_part=>[r2.object],
                                                             :has_member=>[r3.object]}}
      test_from_solr_object5.relationships_by_name.should == {:self=>{"testing2"=>[r3.object], "collection_members"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object]}} 
    end
  end
end
