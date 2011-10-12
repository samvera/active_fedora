require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'equivalent-xml'

describe ActiveFedora::RelsExtDatastream do
  
  before(:all) do
    @pid = "test:sample_pid"
  
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
      @test_ds.expects(:model).returns(stub("model", :outbound_relationships=>{:is_member_of=>['demo:10']}, :relationships=>{:self=>{:is_member_of=>['demo:10']}},  :relationships_are_dirty =>true, :relationships_are_dirty= => true)).times(4)
#register_triple(:self, :is_member_of, "demo:10") 
      @test_ds.serialize!
      EquivalentXml.equivalent?(@test_ds.content, "<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>\n        <rdf:Description rdf:about='info:fedora/test:sample_pid'>\n        <isMemberOf rdf:resource='demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/></rdf:Description>\n      </rdf:RDF>").should be_true
    end
  
  end

  describe '#to_rels_ext' do
    
    before(:all) do
      @sample_rels_ext_xml = <<-EOS
      <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
        <rdf:Description rdf:about='info:fedora/test:sample_pid'>
          <isMemberOf rdf:resource='info:fedora/demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <isPartOf rdf:resource='info:fedora/demo:11' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <hasPart rdf:resource='info:fedora/demo:12' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <hasModel rdf:resource='info:fedora/afmodel:OtherModel' xmlns='info:fedora/fedora-system:def/model#'/>
          <hasModel rdf:resource='info:fedora/afmodel:SampleModel' xmlns='info:fedora/fedora-system:def/model#'/>
        </rdf:Description>
      </rdf:RDF>
      EOS
      @pid = "test:sample_pid"
    end
    
    it 'should serialize the relationships array to Fedora RELS-EXT rdf/xml' do
      @test_ds.expects(:model).returns(stub("model", :relationships=>{:self=>{:is_member_of=>['info:fedora/demo:10'], :is_part_of=>['info:fedora/demo:11'], :has_part=>['info:fedora/demo:12'], :has_model=>["info:fedora/afmodel:OtherModel", "info:fedora/afmodel:SampleModel"]}}, 
                  :outbound_relationships=>{:is_member_of=>['info:fedora/demo:10'], :is_part_of=>['info:fedora/demo:11'], :has_part=>['info:fedora/demo:12'], :has_model=>["info:fedora/afmodel:OtherModel", "info:fedora/afmodel:SampleModel"]},
                  :relationships_are_dirty= => true)).twice
      EquivalentXml.equivalent?(@test_ds.to_rels_ext(@pid), @sample_rels_ext_xml).should be_true
    end
    
  end
  
  describe "#from_xml" do
    before(:all) do
      @test_obj = ActiveFedora::Base.new
      @test_obj.add_relationship(:is_member_of, "info:fedora/demo:10")
      @test_obj.add_relationship(:is_part_of, "info:fedora/demo:11")
      @test_obj.add_relationship(:conforms_to, "AnInterface", true)
      @test_obj.save
    end
    after(:all) do
      @test_obj.delete
    end
    it "should handle un-mapped predicates gracefully" do
      @test_obj.relationships.should == {:self=>{:is_member_of=>["info:fedora/demo:10"], :is_part_of=>["info:fedora/demo:11"], :has_model=>["info:fedora/afmodel:ActiveFedora_Base"], :conforms_to=>["AnInterface"], :has_collection_member=>[], :has_part=>[]},:inbound=>{:is_part_of=>[]}}
      @test_obj.add_relationship("foo", "foo:bar")
      @test_obj.save
      @test_obj.relationships.should == {:self=>{:is_part_of=>["info:fedora/demo:11"], "foo"=>["foo:bar"], :has_model=>["info:fedora/afmodel:ActiveFedora_Base"], :is_member_of=>["info:fedora/demo:10"], :conforms_to=>["AnInterface"], :has_collection_member=>[], :has_part=>[]},:inbound=>{:is_part_of=>[]}}
    end
    it "should handle un-mapped literals" do
      pending
      xml = "
              <foxml:datastream ID=\"RELS-EXT\" STATE=\"A\" CONTROL_GROUP=\"X\" VERSIONABLE=\"true\" xmlns:foxml=\"info:fedora/fedora-system:def/foxml#\">
              <foxml:datastreamVersion ID=\"RELS-EXT.0\" LABEL=\"\" CREATED=\"2011-09-20T19:48:43.714Z\" MIMETYPE=\"text/xml\" SIZE=\"622\">
                <foxml:xmlContent>
                <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">
                  <rdf:Description rdf:about=\"info:fedora/changeme:3489\">
                    <hasModel xmlns=\"info:fedora/fedora-system:def/model#\" rdf:resource=\"info:fedora/afmodel:ActiveFedora_Base\"/>
                    <isPartOf xmlns=\"info:fedora/fedora-system:def/relations-external#\" rdf:resource=\"info:fedora/demo:11\"/>
                    <isMemberOf xmlns=\"info:fedora/fedora-system:def/relations-external#\" rdf:resource=\"info:fedora/demo:10\"/>
                    <hasMetadata xmlns=\"info:fedora/fedora-system:def/relations-external#\">oai:hull.ac.uk:hull:2708</hasMetadata>
                  </rdf:Description>
                </rdf:RDF>
              </foxml:xmlContent>
            </foxml:datastreamVersion>\n</foxml:datastream>\n"
      doc = Nokogiri::XML::Document.parse(xml)
      new_ds = ActiveFedora::RelsExtDatastream.new
      ActiveFedora::RelsExtDatastream.from_xml(new_ds,doc.root)
      new_ext = new_ds.to_rels_ext('changeme:3489')
      new_ext.should match "<hasMetadata xmlns=\"info:fedora/fedora-system:def/relations-external#\">oai:hull.ac.uk:hull:2708</hasMetadata>"
      
    end
  end
  
  
  describe ".to_solr" do
    
    it "should provide .to_solr and return a SolrDocument" do
      @test_ds.should respond_to(:to_solr)
      @test_ds.expects(:model).returns(stub("model", :relationships=>{:self=>{:is_member_of=>['demo:10']}}, :relationships_are_dirty= => true))
      @test_ds.to_solr.should be_kind_of(Hash)
    end
    
    it "should serialize the relationships into a Hash" do
      @test_ds.expects(:model).returns(stub("model", :relationships=>{:self=>{:is_member_of=>['info:fedora/demo:10'], :is_part_of=>['info:fedora/demo:11'], :has_part=>['info:fedora/demo:12'], :conforms_to=>["AnInterface"]}}, :relationships_are_dirty= => true))
      solr_doc = @test_ds.to_solr
      solr_doc["is_member_of_s"].should == ["info:fedora/demo:10"]
      solr_doc["is_part_of_s"].should == ["info:fedora/demo:11"]
      solr_doc["has_part_s"].should == ["info:fedora/demo:12"]
      solr_doc["conforms_to_s"].should == ["AnInterface"]
    end
  end
  
  it "should treat :self and self.pid as equivalent subjects"
  
end
