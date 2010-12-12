require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'xmlsimple'
#require 'mocha'

#include ActiveFedora::SemanticNode
#include Mocha::Standalone

@@last_pid = 0

class SpecNode2
  include ActiveFedora::SemanticNode
  
  attr_accessor :pid
end

describe ActiveFedora::SemanticNode do
  
  def increment_pid
    @@last_pid += 1    
  end
    
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
      
      attr_accessor :pid
    end
    
    @node = SpecNode.new
    @node.pid = increment_pid
    @test_object = SpecNode2.new
    @test_object.pid = increment_pid    
    @stub_relationship = stub("mock_relationship", :subject => @pid, :predicate => "isMemberOf", :object => "demo:8", :class => ActiveFedora::Relationship)  
    @test_relationship = ActiveFedora::Relationship.new(:subject => @pid, :predicate => "isMemberOf", :object => "demo:9")  
    @test_relationship1 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "demo:10")  
    @test_relationship2 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_part_of, :object => "demo:11")  
    @test_relationship3 = ActiveFedora::Relationship.new(:subject => @pid, :predicate => :has_part, :object => "demo:12")
    @test_cmodel_relationship1 = ActiveFedora::Relationship.new(:subject => @pid, :predicate => :has_model, :object => "afmodel:SampleModel")
    @test_cmodel_relationship2 = ActiveFedora::Relationship.new(:subject => @pid, :predicate => "hasModel", :object => "afmodel:OtherModel")
  end
  
  after(:each) do
    Object.send(:remove_const, :SpecNode)
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
    
    class MockHasRelationship < SpecNode2
      has_relationship "testing", :has_part, :type=>SpecNode2
      has_relationship "testing2", :has_member, :type=>SpecNode2
      has_relationship "testing_inbound", :has_part, :type=>SpecNode2, :inbound=>true
    end
      
    #can only duplicate predicates if not both inbound or not both outbound
    class MockHasRelationshipDuplicatePredicate < SpecNode2
      has_relationship "testing", :has_member, :type=>SpecNode2
      had_exception = false
      begin
        has_relationship "testing2", :has_member, :type=>SpecNode2
      rescue
        had_exception = true
      end
      raise "Did not raise exception if duplicate predicate used" unless had_exception 
    end
      
    #can only duplicate predicates if not both inbound or not both outbound
    class MockHasRelationshipDuplicatePredicate2 < SpecNode2
      has_relationship "testing", :has_member, :type=>SpecNode2, :inbound=>true
      had_exception = false
      begin
        has_relationship "testing2", :has_member, :type=>SpecNode2, :inbound=>true
      rescue
        had_exception = true
      end
      raise "Did not raise exception if duplicate predicate used" unless had_exception 
    end
      
    it 'should create relationship descriptions both inbound and outbound' do
      @test_object2 = MockHasRelationship.new
      @test_object2.pid = increment_pid
      @test_object2.stubs(:testing_inbound).returns({})
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2)})
      @test_object2.add_relationship(r)
      @test_object2.should respond_to(:testing_append)
      @test_object2.should respond_to(:testing_remove)
      @test_object2.should respond_to(:testing2_append)
      @test_object2.should respond_to(:testing2_remove)
      #make sure append/remove method not created for inbound rel
      @test_object2.should_not respond_to(:testing_inbound_append)
      @test_object2.should_not respond_to(:testing_inbound_remove)
      
      @test_object2.named_relationships_desc.should == 
      {:inbound=>{"testing_inbound"=>{:type=>SpecNode2, 
                                     :predicate=>:has_part, 
                                      :inbound=>true, 
                                      :singular=>nil}}, 
       :self=>{"testing"=>{:type=>SpecNode2, 
                           :predicate=>:has_part, 
                           :inbound=>false, 
                           :singular=>nil},
               "testing2"=>{:type=>SpecNode2, 
                            :predicate=>:has_member, 
                            :inbound=>false, 
                            :singular=>nil}}}
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
      local_node.should respond_to(:containers_from_solr)
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
      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_part_of_s:info\\:fedora/test\\:sample_pid", :rows=>25).returns(solr_result)
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
      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_constituent_of_s:info\\:fedora/test\\:sample_pid", :rows=>101).returns(solr_result)
      local_node.constituents(:response_format => :solr, :rows=>101).should equal(solr_result)
    end
    
    
    it "resulting _ids finder should search against solr and return an array of fedora PIDs" do
      SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
      local_node = SpecNode.new
      local_node.expects(:internal_uri).returns("info:fedora/test:sample_pid")
      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_part_of_s:info\\:fedora/test\\:sample_pid", :rows=>25).returns(mock("solr result", :hits => [Hash["id"=>"pid1"], Hash["id"=>"pid2"]]))
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
      local_node.should respond_to(:containers_from_solr)  
    end
    
    describe " resulting finder" do
      it "should read from relationships array and use Repository.find_model to build an array of objects" do
        SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
        local_node = SpecNode.new
        local_node.expects(:outbound_relationships).returns({:is_member_of => ["my:_PID1_", "my:_PID2_", "my:_PID3_"]}).times(2)      
        mock_repo = mock("repo")
        solr_result = mock("solr result", :is_a? => true)
        solr_result.expects(:hits).returns([{"id"=> "my:_PID1_", "active_fedora_model_s" => ["SpecNode"]}, {"id"=> "my:_PID2_", "active_fedora_model_s" => ["SpecNode"]}, {"id"=> "my:_PID3_", "active_fedora_model_s" => ["SpecNode"]}])
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
  
  describe ".create_bidirectional_relationship_finder" do
    before(:each) do
      SpecNode.create_bidirectional_relationship_finders("all_parts", :has_part, :is_part_of)
      @local_node = SpecNode.new
      @local_node.pid = @pid
      @local_node.internal_uri = @uri
    end
    it "should create inbound & outbound finders" do
      @local_node.should respond_to(:all_parts_inbound)
      @local_node.should respond_to(:all_parts_outbound)
    end
    it "should rely on inbound & outbound finders" do      
      @local_node.expects(:all_parts_inbound).with(:rows => 25).returns(["foo1"])
      @local_node.expects(:all_parts_outbound).with(:rows => 25).returns(["foo2"])
      @local_node.all_parts.should == ["foo1", "foo2"]
    end
    it "(:response_format => :id_array) should rely on inbound & outbound finders" do
      @local_node.expects(:all_parts_inbound).with(:response_format=>:id_array, :rows => 34).returns(["fooA"])
      @local_node.expects(:all_parts_outbound).with(:response_format=>:id_array, :rows => 34).returns(["fooB"])
      @local_node.all_parts(:response_format=>:id_array, :rows => 34).should == ["fooA", "fooB"]
    end
    it "(:response_format => :solr) should construct a solr query that combines inbound and outbound searches" do
      # get the id array for outbound relationships then construct solr query by combining id array with inbound relationship search
      @local_node.expects(:all_parts_outbound).with(:response_format=>:id_array).returns(["mypid:1"])
      id_array_query = ActiveFedora::SolrService.construct_query_for_pids(["mypid:1"])
      solr_result = mock("solr result")
      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_part_of_s:info\\:fedora/test\\:sample_pid OR #{id_array_query}", :rows=>25).returns(solr_result)
      @local_node.all_parts(:response_format=>:solr)
    end

    it "should register both inbound and outbound predicate components" do
      @local_node.relationships[:inbound].has_key?(:is_part_of).should == true
      @local_node.relationships[:self].has_key?(:has_part).should == true
    end
  
    it "should register relationship names for inbound, outbound" do
      @local_node.relationship_names.include?("all_parts_inbound").should == true
      @local_node.relationship_names.include?("all_parts_outbound").should == true
    end

  end
  
  describe "#has_bidirectional_relationship" do
    it "should ..." do
      SpecNode.expects(:create_bidirectional_relationship_finders).with("all_parts", :has_part, :is_part_of, {})
      SpecNode.has_bidirectional_relationship("all_parts", :has_part, :is_part_of)
    end

    it "should have named_relationship and relationship hashes contain bidirectionally related objects" do
      SpecNode.has_bidirectional_relationship("all_parts", :has_part, :is_part_of)
      @local_node = SpecNode.new
      @local_node.pid = "mypid1"
      @local_node2 = SpecNode.new
      @local_node2.pid = "mypid2"
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode)}) 
      @local_node.add_relationship(r)
      @local_node2.add_relationship(r)
      r2 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@local_node2})
      @local_node.add_relationship(r2)
      r3 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@local_node})
      @local_node2.add_relationship(r3)
      @local_node.relationships.should == {:self=>{:has_model=>[r.object],:has_part=>[r2.object]},:inbound=>{:is_part_of=>[]}}
      @local_node2.relationships.should == {:self=>{:has_model=>[r.object],:has_part=>[r3.object]},:inbound=>{:is_part_of=>[]}}
      @local_node.named_relationships.should == {:self=>{"all_parts_outbound"=>[r2.object]},:inbound=>{"all_parts_inbound"=>[]}}
      @local_node2.named_relationships.should == {:self=>{"all_parts_outbound"=>[r3.object]},:inbound=>{"all_parts_inbound"=>[]}}
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
          <hasModel rdf:resource='info:fedora/afmodel:OtherModel' xmlns='info:fedora/fedora-system:def/model#'/>
          <hasModel rdf:resource='info:fedora/afmodel:SampleModel' xmlns='info:fedora/fedora-system:def/model#'/>
        </rdf:Description>
      </rdf:RDF>
      EOS
    end
    
    it 'should serialize the relationships array to Fedora RELS-EXT rdf/xml' do
      @node.add_relationship(@test_relationship1)
      @node.add_relationship(@test_relationship2)
      @node.add_relationship(@test_relationship3)
      @node.add_relationship(@test_cmodel_relationship1)
      @node.add_relationship(@test_cmodel_relationship2)
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
  
    
  it 'should provide #unregister_triple' do
    @test_object.should respond_to(:unregister_triple)
  end
  
  describe '#unregister_triple' do
    it 'should remove a triple from the relationships hash' do
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>"info:fedora/3"})
      r2 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>"info:fedora/4"})
      @test_object.add_relationship(r)
      @test_object.add_relationship(r2)
      #check both are there
      @test_object.relationships.should == {:self=>{:has_part=>[r.object,r2.object]}}
      @test_object.unregister_triple(r.subject,r.predicate,r.object)
      #check returns false if relationship does not exist and does nothing
      @test_object.unregister_triple(:self,:has_member,r2.object).should == false
      #check only one item removed
      @test_object.relationships.should == {:self=>{:has_part=>[r2.object]}}
      @test_object.unregister_triple(r2.subject,r2.predicate,r2.object)
      #check last item removed and predicate removed since now emtpy
      @test_object.relationships.should == {:self=>{}}
      
    end
  end

  it 'should provide #remove_relationship' do
    @test_object.should respond_to(:remove_relationship)
  end

  describe '#remove_relationship' do
    it 'should remove a relationship from the relationships hash' do
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>"info:fedora/3"})
      r2 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>"info:fedora/4"})
      @test_object.add_relationship(r)
      @test_object.add_relationship(r2)
      #check both are there
      @test_object.relationships.should == {:self=>{:has_part=>[r.object,r2.object]}}
      @test_object.remove_relationship(r)
      #check returns false if relationship does not exist and does nothing with different predicate
      rBad = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_member,:object=>"info:fedora/4"})
      @test_object.remove_relationship(rBad).should == false
      #check only one item removed
      @test_object.relationships.should == {:self=>{:has_part=>[r2.object]}}
      @test_object.remove_relationship(r2)
      #check last item removed and predicate removed since now emtpy
      @test_object.relationships.should == {:self=>{}}
      
    end
  end

  it 'should provide #named_relationship_predicates' do
    @test_object.should respond_to(:named_relationship_predicates)
  end
  
  describe '#named_relationship_predicates' do
    class MockNamedRelationshipPredicates < SpecNode2
      has_relationship "testing", :has_part, :type=>SpecNode2
      has_relationship "testing2", :has_member, :type=>SpecNode2
      has_relationship "testing_inbound", :has_part, :type=>SpecNode2, :inbound=>true
    end
    
    it 'should return a map of subject to relationship name to fedora ontology relationship predicate' do
      @test_object2 = MockNamedRelationshipPredicates.new
      @test_object2.pid = increment_pid
      model_rel = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockNamedRelationshipPredicates)}) 
      @test_object2.add_relationship(model_rel)
      @test_object3 = SpecNode2.new
      @test_object3.pid = increment_pid
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2)}) 
      @test_object3.add_relationship(r)
      @test_object4 = SpecNode2.new 
      @test_object4.pid = increment_pid
      @test_object4.add_relationship(r)
      @test_object.add_relationship(r)
      #create relationships that mirror "testing"
      r3 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@test_object3})
      r4 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@test_object4})
      @test_object2.add_relationship(r3)
      @test_object2.add_relationship(r4)
      #create relationship mirroring testing2
      r5 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_member,:object=>@test_object})
      @test_object2.add_relationship(r5)
      @test_object2.named_relationship_predicates.should == {:self=>{"testing"=>:has_part,"testing2"=>:has_member},
                                                            :inbound=>{"testing_inbound"=>:has_part}}
      
    end 
  end

   it 'should provide #kind_of_model?' do
    @test_object.should respond_to(:kind_of_model?)
  end
  
  describe '#kind_of_model?' do
    it 'should check if current object is the kind of model class supplied' do
      #has_model relationship does not get created until save called
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2)}) 
      @test_object.add_relationship(r)
      @test_object.kind_of_model?(SpecNode2).should == true
    end
  end
  
  it 'should provide #assert_kind_of_model' do
    @test_object.should respond_to(:assert_kind_of_model)
  end
  
  describe '#assert_kind_of_model' do
    it 'should correctly assert if an object is the type of model supplied' do
      @test_object3 = SpecNode2.new
      @test_object3.pid = increment_pid
      #has_model relationship does not get created until save called so need to add the has model rel here, is fine since not testing save
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2)}) 
      @test_object.add_relationship(r)
      @test_object3.assert_kind_of_model('object',@test_object,SpecNode2)
    end
  end
  
  it 'should provide #class_from_name' do
    @test_object.should respond_to(:class_from_name)
  end
  
  describe '#class_from_name' do
    it 'should return a class constant for a string passed in' do
      @test_object.class_from_name("SpecNode2").should == SpecNode2
    end
  end
  
  it 'should provide #relationship_exists?' do
    @test_object.should respond_to(:relationship_exists?)
  end
  
  describe '#relationship_exists?' do
    it 'should return true if a relationship does exist' do
      @test_object3 = SpecNode2.new
      @test_object3.pid = increment_pid
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_member,:object=>@test_object3})
      @test_object.relationship_exists?(r.subject,r.predicate,r.object).should == false
      @test_object.add_relationship(r)
      @test_object.relationship_exists?(r.subject,r.predicate,r.object).should == true
    end
  end

  it 'should provide #named_relationships' do
    @test_object.should respond_to(:named_relationships)
  end
  
  describe '#named_relationships' do
    
    class MockNamedRelationships3 < SpecNode2
      has_relationship "testing", :has_part, :type=>SpecNode2
      has_relationship "testing2", :has_member, :type=>SpecNode2
      has_relationship "testing_inbound", :has_part, :type=>SpecNode2, :inbound=>true
    end
    
    it 'should return current named relationships' do
      @test_object2 = MockNamedRelationships3.new
      @test_object2.pid = increment_pid
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockNamedRelationships3)}) 
      @test_object2.add_relationship(r)
      r2 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2)}) 
      @test_object.add_relationship(r2)
      #should return expected named relationships
      @test_object2.named_relationships.should == {:self=>{"testing"=>[],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@test_object})
      @test_object2.add_relationship(r)
      @test_object2.named_relationships.should == {:self=>{"testing"=>[r.object],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
    end 

    it 'should automatically update the named_relationships if relationships has changed (no refresh of named_relationships hash unless relationships hash has changed)' do
      @test_object3 = MockNamedRelationships3.new
      @test_object3.pid = increment_pid
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockNamedRelationships3)}) 
      @test_object3.add_relationship(r)
      r2 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2)}) 
      @test_object.add_relationship(r2)
      #should return expected named relationships
      @test_object3.named_relationships.should == {:self=>{"testing"=>[],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
      r3 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@test_object})
      @test_object3.add_relationship(r3)
      @test_object3.named_relationships.should == {:self=>{"testing"=>[r3.object],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
      r4 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_member,:object=>"3"})
      @test_object3.add_relationship(r4)
      @test_object3.named_relationships.should == {:self=>{"testing"=>[r3.object],"testing2"=>[r4.object]},:inbound=>{"testing_inbound"=>[]}}
    end
  end

  it 'should provide #assert_kind_of' do
    @test_object.should respond_to(:assert_kind_of)
  end
  
  describe '#assert_kind_of' do
    it 'should raise an exception if object supplied is not the correct type' do
      had_exception = false
      begin
        @test_object.assert_kind_of 'SpecNode2', @test_object, ActiveFedora::Base
      rescue
        had_exception = true
      end
      raise "Failed to throw exception with kind of mismatch" unless had_exception
      #now should not throw any exception
      @test_object.assert_kind_of 'SpecNode2', @test_object, SpecNode2
    end
  end

  it 'should provide #relationship_names' do
    @test_object.should respond_to(:relationship_names)
  end
  
  describe '#relationship_names' do
    class MockRelationshipNames < SpecNode2
      has_relationship "testing", :has_part, :type=>SpecNode2
      has_relationship "testing2", :has_member, :type=>SpecNode2
      has_relationship "testing_inbound", :has_part, :type=>SpecNode2, :inbound=>true
      has_relationship "testing_inbound2", :has_member, :type=>SpecNode2, :inbound=>true
    end
    
    it 'should return an array of relationship names for this model' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      @test_object2.relationship_names.include?("testing").should == true
      @test_object2.relationship_names.include?("testing2").should == true
      @test_object2.relationship_names.include?("testing_inbound").should == true
      @test_object2.relationship_names.include?("testing_inbound2").should == true
      @test_object2.relationship_names.size.should == 4
    end
  end
  
  it 'should provide #inbound_relationship_names' do
    @test_object.should respond_to(:inbound_relationship_names)
  end
  
  describe '#inbound_relationship_names' do
    it 'should return an array of inbound relationship names for this model' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      @test_object2.inbound_relationship_names.include?("testing_inbound").should == true
      @test_object2.inbound_relationship_names.include?("testing_inbound2").should == true
      @test_object2.inbound_relationship_names.size.should == 2
    end
  end
  
  it 'should provide #outbound_relationship_names' do
    @test_object.should respond_to(:outbound_relationship_names)
  end
  
  describe '#outbound_relationship_names' do
    it 'should return an array of outbound relationship names for this model' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      @test_object2.outbound_relationship_names.include?("testing").should == true
      @test_object2.outbound_relationship_names.include?("testing2").should == true
      @test_object2.outbound_relationship_names.size.should == 2
    end
  end
  
  it 'should provide #named_outbound_relationships' do
    @test_object.should respond_to(:named_outbound_relationships)
  end
  
  describe '#named_outbound_relationships' do
    it 'should return hash of outbound relationship names to arrays of object uri' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      @test_object2.named_outbound_relationships.should == {"testing"=>[],
                                                            "testing2"=>[]} 
    end
  end
  
  it 'should provide #named_inbound_relationships' do
    #testing execution of this in integration since touches solr
    @test_object.should respond_to(:named_inbound_relationships)
  end
  
  it 'should provide #named_relationship' do
    @test_object.should respond_to(:named_relationship)
  end
  
  describe '#named_relationship' do
    it 'should return an array of object uri for a given relationship name' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_model, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockRelationshipNames))
      @test_object2.add_relationship(r)
      @test_object3 = SpecNode2.new 
      @test_object3.pid = increment_pid
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_model, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2))
      @test_object3.add_relationship(r2)
      @test_object4 = SpecNode2.new 
      @test_object4.pid = increment_pid
      @test_object4.add_relationship(r2)
      @test_object.add_relationship(r2)
      #add relationships that mirror 'testing' and 'testing2'
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_part, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_member, :object=>@test_object4)      
      @test_object2.add_relationship(r3)
      @test_object2.add_relationship(r4)
     @test_object2.named_relationship("testing").should == [r3.object] 
    end
  end
  
  describe ActiveFedora::SemanticNode::ClassMethods do
    
    after(:each) do
      begin
        @test_object2.delete
      rescue
      end
    end
    
    describe '#named_relationships_desc' do
      it 'should initialize named_relationships_desc to a new hash containing self' do
        @test_object2 = SpecNode2.new
        @test_object2.pid = increment_pid
        @test_object2.named_relationships_desc.should == {:self=>{}}
      end
    end
      
    describe '#register_named_subject' do
    
      class MockRegisterNamedSubject < SpecNode2
        register_named_subject :test
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedSubject.new
        @test_object2.pid = increment_pid
        @test_object2.named_relationships_desc.should == {:self=>{}, :test=>{}}
      end 
    end
  
    describe '#register_named_relationship' do
    
      class MockRegisterNamedRelationship < SpecNode2
        register_named_relationship :self, "testing", :is_part_of, :type=>SpecNode2
        register_named_relationship :inbound, "testing2", :has_part, :type=>SpecNode2
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedRelationship.new 
        @test_object2.pid = increment_pid
        @test_object2.named_relationships_desc.should == {:inbound=>{"testing2"=>{:type=>SpecNode2, :predicate=>:has_part}}, :self=>{"testing"=>{:type=>SpecNode2, :predicate=>:is_part_of}}}
      end 
    end
    
    describe '#create_named_relationship_methods' do
      class MockCreateNamedRelationshipMethods < SpecNode2
        register_named_relationship :self, "testing", :is_part_of, :type=>SpecNode2
        create_named_relationship_methods "testing"
      end
      
      it 'should create an append and remove method for each outbound relationship' do
        @test_object2 = MockCreateNamedRelationshipMethods.new
        @test_object2.pid = increment_pid 
        @test_object2.should respond_to(:testing_append)
        @test_object2.should respond_to(:testing_remove)
        #test execution in base_spec since method definitions include methods in ActiveFedora::Base
      end
    end

    describe '#create_bidirectional_named_relationship_methods' do
      class MockCreateNamedRelationshipMethods < SpecNode2
        register_named_relationship :self, "testing_outbound", :is_part_of, :type=>SpecNode2
        create_bidirectional_named_relationship_methods "testing", "testing_outbound"
      end
      
      it 'should create an append and remove method for each outbound relationship' do
        @test_object2 = MockCreateNamedRelationshipMethods.new
        @test_object2.pid = increment_pid 
        @test_object2.should respond_to(:testing_append)
        @test_object2.should respond_to(:testing_remove)
        #test execution in base_spec since method definitions include methods in ActiveFedora::Base
      end
    end
    
    describe '#def named_predicate_exists_with_different_name?' do
      
      it 'should return true if a predicate exists for same subject and different name but not different subject' do
        class MockPredicateExists < SpecNode2
          has_relationship "testing", :has_part, :type=>SpecNode2
          has_relationship "testing2", :has_member, :type=>SpecNode2
          has_relationship "testing_inbound", :is_part_of, :type=>SpecNode2, :inbound=>true
      
          named_predicate_exists_with_different_name?(:self,"testing",:has_part).should == false
          named_predicate_exists_with_different_name?(:self,"testing3",:has_part).should == true
          named_predicate_exists_with_different_name?(:inbound,"testing",:has_part).should == false
          named_predicate_exists_with_different_name?(:self,"testing2",:has_member).should == false
          named_predicate_exists_with_different_name?(:self,"testing3",:has_member).should == true
          named_predicate_exists_with_different_name?(:inbound,"testing2",:has_member).should == false
          named_predicate_exists_with_different_name?(:self,"testing_inbound",:is_part_of).should == false
          named_predicate_exists_with_different_name?(:inbound,"testing_inbound",:is_part_of).should == false
          named_predicate_exists_with_different_name?(:inbound,"testing_inbound2",:is_part_of).should == true
        end
      end
    end
  end
end
