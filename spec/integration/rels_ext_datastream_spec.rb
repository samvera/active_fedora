require 'spec_helper'

require 'active_fedora'
require "rexml/document"


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
    @test_datastream.model = @test_object
    @test_object.save
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
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:5")
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:10")
      rexml1 = REXML::Document.new(@test_datastream.to_rels_ext())
      @test_datastream.serialize!
      rexml2 = REXML::Document.new(@test_object.datastreams["RELS-EXT"].content)
      rexml1.root.elements["rdf:Description"].inspect.should eql(rexml2.root.elements["rdf:Description"].inspect)
    end
  
  end
  
  it "should load relationships from fedora into parent object" do
    class SpecNode; include ActiveFedora::SemanticNode; end
    ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace].each_key do |p| 
      @test_object.add_relationship(p, "info:fedora/demo:#{rand(100)}")
    end
    @test_object.save
    # make sure that _something_ was actually added to the object's relationships hash
    @test_object.ids_for_outbound(:is_member_of).size.should == 1
    new_rels = ActiveFedora::Base.find(@test_object.pid).relationships
    # This stopped working, need to push an issue into the rdf library. (when dumping ntriples, the order of assertions changed)
    #new_rels.should == @test_object.relationships
    new_rels.dump(:rdfxml).should == @test_object.relationships.dump(:rdfxml)
  end

end
