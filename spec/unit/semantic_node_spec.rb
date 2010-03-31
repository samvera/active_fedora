require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'xmlsimple'
#require 'mocha'

#include ActiveFedora::SemanticNode
#include Mocha::Standalone

describe ActiveFedora::SemanticNode do
  
  before(:all) do
    @pid = "test:sample_pid"
    @uri = "info:fedora/#{@pid}"
    @sample_solr_hits = [{"id"=>"_PID1_", "active_fedora_model_s"=>["AudioRecord"]},
                          {"id"=>"_PID2_", "active_fedora_model_s"=>["AudioRecord"]},
                          {"id"=>"_PID3_", "active_fedora_model_s"=>["AudioRecord"]}]
  end
  
  before(:each) do
    class SpecNode 
      include ActiveFedora::SemanticNode
    end
    @node = SpecNode.new
    @stub_relationship = stub("mock_relationship", :subject => @pid, :predicate => "isMemberOf", :object => "demo:8", :class => ActiveFedora::Relationship)  
    @test_relationship = ActiveFedora::Relationship.new(:subject => @pid, :predicate => "isMemberOf", :object => "demo:9")  
    @test_relationship1 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "demo:10")  
    @test_relationship2 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_part_of, :object => "demo:11")  
    @test_relationship3 = ActiveFedora::Relationship.new(:subject => @pid, :predicate => :has_part, :object => "demo:12")
  end
  
  after(:each) do
    Object.send(:remove_const, :SpecNode)
  end
  
  it 'should provide predicate mappings for entire Fedora Relationship Ontology' do
    desired_mappings = Hash[:is_member_of => "isMemberOf",
                          :has_member => "hasMember",
                          :is_part_of => "isPartOf",
                          :has_part => "hasPart",
                          :is_member_of_collection => "isMemberOfCollection",
                          :has_collection_member => "hasCollectionMember",
                          :is_constituent_of => "isConstituentOf",
                          :has_constituent => "hasConstituent",
                          :is_subset_of => "isSubsetOf",
                          :has_subset => "hasSubset",
                          :is_derivation_of => "isDerivationOf",
                          :has_derivation => "hasDerivation",
                          :is_dependent_of => "isDependentOf",
                          :has_dependent => "hasDependent",
                          :is_description_of => "isDescriptionOf",
                          :has_description => "hasDescription",
                          :is_metadata_for => "isMetadataFor",
                          :has_metadata => "hasMetadata",
                          :is_annotation_of => "isAnnotationOf",
                          :has_annotation => "hasAnnotation",
                          :has_equivalent => "hasEquivalent",
                          :conforms_to => "conformsTo"]
    desired_mappings.each_pair do |k,v|
      SpecNode::PREDICATE_MAPPINGS.should have_key(k)
      SpecNode::PREDICATE_MAPPINGS[k].should == v
    end
  end
  
  it 'should provide .internal_uri' do
    @node.should  respond_to(:internal_uri)
  end
  
  it 'should provide #has_relationship' do
    SpecNode.should  respond_to(:has_relationship)
    SpecNode.should  respond_to(:has_relationship)
  end
  
  describe '#has_relationship' do
    it "should create finders based on provided relationship name" do
      SpecNode.has_relationship("parts", :is_part_of, :inbound => true)
      local_node = SpecNode.new
      local_node.should respond_to(:parts_ids)
      # local_node.should respond_to(:parts)
      local_node.should_not respond_to(:containers)
      SpecNode.has_relationship("containers", :is_member_of)  
      local_node.should respond_to(:containers_ids)
    end
    
    it "should add a subject and predicate to the relationships array" do
      SpecNode.has_relationship("parents", :is_part_of)
      SpecNode.relationships.should have_key(:self)
      @node.relationships[:self].should have_key(:is_part_of)
    end
    
    it "should use :inbound as the subject if :inbound => true" do
      SpecNode.has_relationship("parents", :is_part_of, :inbound => true)
      SpecNode.relationships.should have_key(:inbound)
      @node.relationships[:inbound].should have_key(:is_part_of)
    end
    
    it 'should create inbound relationship finders' do
      SpecNode.expects(:create_inbound_relationship_finders)
      SpecNode.has_relationship("parts", :is_part_of, :inbound => true) 
    end
    
    it 'should create outbound relationship finders' do
      SpecNode.expects(:create_outbound_relationship_finders).times(2)
      SpecNode.has_relationship("parts", :is_part_of, :inbound => false)
      SpecNode.has_relationship("container", :is_member_of)
    end
    
    it "should create outbound relationship finders that return an array of fedora PIDs" do
      SpecNode.has_relationship("containers", :is_member_of, :inbound => false)
      local_node = SpecNode.new
      local_node.internal_uri = "info:fedora/#{@pid}"
      
      local_node.add_relationship(ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/container:A") )
      local_node.add_relationship(ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/container:B") )
      containers_result = local_node.containers_ids
      containers_result.should be_instance_of(Array)
      containers_result.should include("container:A")
      containers_result.should include("container:B")
    end
    
  end
    
  describe '#create_inbound_relationship_finders' do
    
    it 'should respond to #create_inbound_relationship_finders' do
      SpecNode.should respond_to(:create_inbound_relationship_finders)
    end
    
    it "should create finders based on provided relationship name" do
      SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
      local_node = SpecNode.new
      local_node.should respond_to(:parts_ids)
      local_node.should_not respond_to(:containers)
      SpecNode.create_inbound_relationship_finders("containers", :is_member_of, :inbound => true)  
      local_node.should respond_to(:containers_ids)
      local_node.should respond_to(:containers)
    end
    
    it "resulting finder should search against solr and use Model#load_instance to build an array of objects" do
      solr_result = (mock("solr result", :is_a? => true, :hits => @sample_solr_hits))
      mock_repo = mock("repo")
      mock_repo.expects(:find_model).with("_PID1_", "AudioRecord").returns("AR1")
      mock_repo.expects(:find_model).with("_PID2_", "AudioRecord").returns("AR2")
      mock_repo.expects(:find_model).with("_PID3_", "AudioRecord").returns("AR3")
      SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
      local_node = SpecNode.new()
      local_node.expects(:internal_uri).returns("info:fedora/test:sample_pid")
      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_part_of_s:info\\:fedora/test\\:sample_pid").returns(solr_result)
      Fedora::Repository.expects(:instance).returns(mock_repo).times(3)
      Kernel.expects(:const_get).with("AudioRecord").returns("AudioRecord").times(3)
      local_node.parts.should == ["AR1", "AR2", "AR3"]
    end
    
    it "resulting finder should accept :solr as :response_format value and return the raw Solr Result" do
      solr_result = mock("solr result")
      SpecNode.create_inbound_relationship_finders("constituents", :is_constituent_of, :inbound => true)
      local_node = SpecNode.new
      mock_repo = mock("repo")
      mock_repo.expects(:find_model).never
      local_node.expects(:internal_uri).returns("info:fedora/test:sample_pid")
      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_constituent_of_s:info\\:fedora/test\\:sample_pid").returns(solr_result)
      local_node.constituents(:response_format => :solr).should equal(solr_result)
    end
    
    
    it "resulting _ids finder should search against solr and return an array of fedora PIDs" do
      SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
      local_node = SpecNode.new
      local_node.expects(:internal_uri).returns("info:fedora/test:sample_pid")
      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_part_of_s:info\\:fedora/test\\:sample_pid").returns(mock("solr result", :hits => [Hash["id"=>"pid1"], Hash["id"=>"pid2"]]))
      local_node.parts(:response_format => :id_array).should == ["pid1", "pid2"]
    end
    
    it "resulting _ids finder should call the basic finder with :result_format => :id_array" do
      SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
      local_node = SpecNode.new
      local_node.expects(:parts).with(:response_format => :id_array)
      local_node.parts_ids
    end
    
    it "resulting finder should provide option of filtering results by :type"
  end
  
  describe '#create_outbound_relationship_finders' do
    
    it 'should respond to #create_outbound_relationship_finders' do
      SpecNode.should respond_to(:create_outbound_relationship_finders)
    end
    
    it "should create finders based on provided relationship name" do
      SpecNode.create_outbound_relationship_finders("parts", :is_part_of)
      local_node = SpecNode.new
      local_node.should respond_to(:parts_ids)
      #local_node.should respond_to(:parts)  #.with(:type => "AudioRecord")  
      local_node.should_not respond_to(:containers)
      SpecNode.create_outbound_relationship_finders("containers", :is_member_of)  
      local_node.should respond_to(:containers_ids)
      local_node.should respond_to(:containers)      
    end
    
    describe " resulting finder" do
      it "should read from relationships array and use Repository.find_model to build an array of objects" do
        SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
        local_node = SpecNode.new
        local_node.expects(:outbound_relationships).returns({:is_member_of => ["my:_PID1_", "my:_PID2_", "my:_PID3_"]}).times(2)      
        mock_repo = mock("repo")
        solr_result = mock("solr result", :is_a? => true)
        solr_result.expects(:hits).returns([{"id"=> "my:_PID1_", "active_fedora_model_s" => "SpecNode"}, {"id"=> "my:_PID2_", "active_fedora_model_s" => "SpecNode"}, {"id"=> "my:_PID3_", "active_fedora_model_s" => "SpecNode"}])
        ActiveFedora::SolrService.instance.conn.expects(:query).with("id:my\\:_PID1_ OR id:my\\:_PID2_ OR id:my\\:_PID3_").returns(solr_result)
        mock_repo.expects(:find_model).with("my:_PID1_", SpecNode).returns("AR1")
        mock_repo.expects(:find_model).with("my:_PID2_", SpecNode).returns("AR2")
        mock_repo.expects(:find_model).with("my:_PID3_", SpecNode).returns("AR3")
        Fedora::Repository.expects(:instance).returns(mock_repo).times(3)
        local_node.containers.should == ["AR1", "AR2", "AR3"]
      end
    
      it "should accept :solr as :response_format value and return the raw Solr Result" do
        solr_result = mock("solr result")
        SpecNode.create_outbound_relationship_finders("constituents", :is_constituent_of)
        local_node = SpecNode.new
        mock_repo = mock("repo")
        mock_repo.expects(:find_model).never
        local_node.stubs(:internal_uri)
        ActiveFedora::SolrService.instance.conn.expects(:query).returns(solr_result)
        local_node.constituents(:response_format => :solr).should equal(solr_result)
      end
      
      it "(:response_format => :id_array) should read from relationships array" do
        SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
        local_node = SpecNode.new
        local_node.expects(:outbound_relationships).returns({:is_member_of => []}).times(2)
        local_node.containers_ids
      end
    
      it "(:response_format => :id_array) should return an array of fedora PIDs" do
        SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
        local_node = SpecNode.new
        local_node.add_relationship(@test_relationship1)
        result = local_node.containers_ids
        result.should be_instance_of(Array)
        result.should include("demo:10")
      end
      
      it "should provide option of filtering results by :type"
    end
    
    describe " resulting _ids finder" do
      it "should call the basic finder with :result_format => :id_array" do
        SpecNode.create_outbound_relationship_finders("parts", :is_part_of)
        local_node = SpecNode.new
        local_node.expects(:parts).with(:response_format => :id_array)
        local_node.parts_ids
      end
    end
  end
  
  describe ".add_relationship" do
    it "should add relationship to the relationships hash" do
      @node.add_relationship(@test_relationship)
      @node.relationships.should have_key(@test_relationship.subject) 
      @node.relationships[@test_relationship.subject].should have_key(@test_relationship.predicate)
      @node.relationships[@test_relationship.subject][@test_relationship.predicate].should include(@test_relationship.object)
    end
    
    it "adding relationship to an instance should not affect class-level relationships hash" do 
      local_test_node1 = SpecNode.new
      local_test_node2 = SpecNode.new
      local_test_node1.add_relationship(@test_relationship1)
      #local_test_node2.add_relationship(@test_relationship2)
      
      local_test_node1.relationships[:self][:is_member_of].should == ["info:fedora/demo:10"]      
      local_test_node2.relationships[:self][:is_member_of].should be_nil
    end
    
  end
  
  describe '#relationships' do
    
    it "should return a hash" do
      SpecNode.relationships.class.should == Hash
    end

  end

    
  it "should provide a relationship setter"
  it "should provide a relationship getter"
  it "should provide a relationship deleter"
      
  describe '.register_triple' do
    it 'should add triples to the relationships hash' do
      @node.register_triple(:self, :is_part_of, "info:fedora/demo:10")
      @node.register_triple(:self, :is_member_of, "info:fedora/demo:11")
      @node.relationships[:self].should have_key(:is_part_of)
      @node.relationships[:self].should have_key(:is_member_of)
      @node.relationships[:self][:is_part_of].should include("info:fedora/demo:10")
      @node.relationships[:self][:is_member_of].should include("info:fedora/demo:11")
    end
    
    it "should not be a class level method"
  end
  
  it 'should provide #predicate_lookup that maps symbols to common RELS-EXT predicates' do
    SpecNode.should respond_to(:predicate_lookup)
    SpecNode.predicate_lookup(:is_part_of).should == "isPartOf"
    SpecNode.predicate_lookup(:is_member_of).should == "isMemberOf"
    SpecNode.predicate_lookup("isPartOfCollection").should == "isPartOfCollection"
  end
  
  it 'should provide #relationships_to_rels_ext' do
    SpecNode.should respond_to(:relationships_to_rels_ext)
    @node.should respond_to(:to_rels_ext)
  end
  
  describe '#relationships_to_rels_ext' do
    
    before(:all) do
      @sample_rels_ext_xml = <<-EOS
      <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
        <rdf:Description rdf:about='info:fedora/test:sample_pid'>
          <isMemberOf rdf:resource='info:fedora/demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <isPartOf rdf:resource='info:fedora/demo:11' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <hasPart rdf:resource='info:fedora/demo:12' xmlns='info:fedora/fedora-system:def/relations-external#'/>
        </rdf:Description>
      </rdf:RDF>
      EOS
    end
    
    it 'should serialize the relationships array to Fedora RELS-EXT rdf/xml' do
      @node.add_relationship(@test_relationship1)
      @node.add_relationship(@test_relationship2)
      @node.add_relationship(@test_relationship3)
      @node.internal_uri = @uri
      returned_xml = XmlSimple.xml_in(@node.to_rels_ext(@pid))
      returned_xml.should == XmlSimple.xml_in(@sample_rels_ext_xml)
    end
    
    it "should treat :self and self.pid as equivalent subjects"
  end
  
  it 'should provide #relationships_to_rdf_xml' 

  describe '#relationships_to_rdf_xml' do
    it 'should serialize the relationships array to rdf/xml'
  end
  
  it "should provide .outbound_relationships" do 
    @node.should respond_to(:outbound_relationships)
  end
  
end
