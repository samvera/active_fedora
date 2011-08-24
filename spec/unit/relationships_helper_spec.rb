require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'xmlsimple'

class SpecNamedNode
  include ActiveFedora::RelationshipsHelper
  
  attr_accessor :pid
end

describe ActiveFedora::RelationshipsHelper do
  
  def increment_pid
    @@last_pid += 1    
  end

  before(:each) do
    @test_object = SpecNamedNode.new
    @test_object.pid = increment_pid
  end

  describe '#relationship_predicates' do
    class MockNamedRelationshipPredicates < SpecNamedNode
      register_relationship_desc(:self, "testing", :has_part, :type=>SpecNamedNode)
      create_relationship_name_methods("testing")
      register_relationship_desc(:self, "testing2", :has_member, :type=>SpecNamedNode)
      create_relationship_name_methods("testing2")
      register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNamedNode)
    end

    it 'should provide #relationship_predicates' do
      @test_object.should respond_to(:relationship_predicates)
    end
    
    it 'should return a map of subject to relationship name to fedora ontology relationship predicate' do
      @test_object2 = MockNamedRelationshipPredicates.new
      @test_object2.relationship_predicates.should == {:self=>{"testing"=>:has_part,"testing2"=>:has_member},
                                                            :inbound=>{"testing_inbound"=>:has_part}}
      
    end 
  end
  
  describe '#conforms_to?' do
    it 'should provide #conforms_to?' do
      @test_object.should respond_to(:conforms_to?)
    end
    
    it 'should check if current object is the kind of model class supplied' do
      #has_model relationship does not get created until save called
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNamedNode)})
      @test_object.expects(:relationships).returns({:self=>{:has_model=>[r.object]}}).at_least_once
      @test_object.conforms_to?(SpecNamedNode).should == true
    end
  end
  
  describe '#assert_kind_of_model' do
    it 'should provide #assert_kind_of_model' do
      @test_object.should respond_to(:assert_kind_of_model)
    end

    it 'should correctly assert if an object is the type of model supplied' do
      @test_object3 = SpecNamedNode.new
      @test_object3.pid = increment_pid
      #has_model relationship does not get created until save called so need to add the has model rel here, is fine since not testing save
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNamedNode)}) 
      @test_object.expects(:relationships).returns({:self=>{:has_model=>[r.object]}}).at_least_once
      @test_object3.assert_kind_of_model('object',@test_object,SpecNamedNode)
    end
  end
  
  it 'should provide #class_from_name' do
    @test_object.should respond_to(:class_from_name)
  end
  
  describe '#class_from_name' do
    it 'should return a class constant for a string passed in' do
      @test_object.class_from_name("SpecNamedNode").should == SpecNamedNode
    end
  end

  describe '#relationships_by_name' do
    
    class MockNamedRelationships3 < SpecNamedNode
      register_relationship_desc(:self, "testing", :has_part, :type=>SpecNamedNode)
      create_relationship_name_methods("testing")
      register_relationship_desc(:self, "testing2", :has_member, :type=>SpecNamedNode)
      create_relationship_name_methods("testing2")
      register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNamedNode)
    end

    it 'should provide #relationships_by_name' do
      @test_object.should respond_to(:relationships_by_name)
    end
    
    it 'should return current named relationships' do
      @test_object2 = MockNamedRelationships3.new
      @test_object2.pid = increment_pid
      @test_object3 = MockNamedRelationships3.new
      @test_object3.pid = increment_pid
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockNamedRelationships3)}) 
      @test_object2.expects(:relationships).returns({:self=>{:has_model=>[r.object],:has_part=>[],:has_member=>[]},:inbound=>{:has_part=>[]}}).at_least_once
      #should return expected named relationships
      @test_object2.relationships_by_name.should == {:self=>{"testing"=>[],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
      r3 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@test_object})
      @test_object3.expects(:relationships).returns({:self=>{:has_model=>[r.object],:has_part=>[r3.object],:has_member=>[]},:inbound=>{:has_part=>[]}}).at_least_once
      @test_object3.relationships_by_name.should == {:self=>{"testing"=>[r3.object],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
    end 
  end

  it 'should provide #relationship_names' do
    @test_object.should respond_to(:relationship_names)
  end
  
  describe '#relationship_names' do
    class MockRelationshipNames < SpecNamedNode
      register_relationship_desc(:self, "testing", :has_part, :type=>SpecNamedNode)
      create_relationship_name_methods("testing")
      register_relationship_desc(:self, "testing2", :has_member, :type=>SpecNamedNode)
      create_relationship_name_methods("testing2")
      register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNamedNode)
      register_relationship_desc(:inbound, "testing_inbound2", :has_member, :type=>SpecNamedNode)
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
  
  it 'should provide #outbound_relationships_by_name' do
    @test_object.should respond_to(:outbound_relationships_by_name)
  end
  
  describe '#outbound_relationships_by_name' do
    it 'should return hash of outbound relationship names to arrays of object uri' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      @test_object2.expects(:relationships).returns({:self=>{:has_part=>[],:has_member=>[],:inbound=>{:has_part=>[],:has_member=>[]}}}).at_least_once
      @test_object2.outbound_relationships_by_name.should == {"testing"=>[],
                                                            "testing2"=>[]} 
    end
  end
  
  it 'should provide #inbound_relationships_by_name' do
    #testing execution of this in integration since touches solr
    @test_object.should respond_to(:inbound_relationships_by_name)
  end
  
  it 'should provide #find_relationship_by_name' do
    @test_object.should respond_to(:find_relationship_by_name)
  end
  
  describe '#find_relationship_by_name' do
    it 'should return an array of object uri for a given relationship name' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_model, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockRelationshipNames))
      @test_object3 = SpecNamedNode.new 
      @test_object3.pid = increment_pid
      @test_object4 = SpecNamedNode.new 
      @test_object4.pid = increment_pid
      #add relationships that mirror 'testing' and 'testing2'
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_part, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:has_member, :object=>@test_object4)      
      @test_object2.expects(:relationships).returns({:self=>{:has_part=>[r3.object]},:has_member=>[r4.object],:has_model=>[r.object]}).at_least_once
     @test_object2.find_relationship_by_name("testing").should == [r3.object] 
    end
  end

  describe "relationship_query" do
    class MockNamedRelationshipQuery < SpecNamedNode
      register_relationship_desc(:inbound, "testing_inbound_query", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
      register_relationship_desc(:inbound, "testing_inbound_no_query_param", :is_part_of, :type=>SpecNamedNode)
      register_relationship_desc(:self, "testing_outbound_query", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
      register_relationship_desc(:self, "testing_outbound_no_query_param", :is_part_of, :type=>SpecNamedNode)
      #for bidirectional relationship testing need to register both outbound and inbound names
      register_relationship_desc(:self, "testing_bi_query_outbound", :has_part, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
      register_relationship_desc(:inbound, "testing_bi_query_inbound", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
      register_relationship_desc(:self, "testing_bi_no_query_param_outbound", :has_part, :type=>SpecNamedNode)
      register_relationship_desc(:inbound, "testing_bi_no_query_param_inbound", :is_part_of, :type=>SpecNamedNode)
    end
    
    before(:each) do
      @mockrelsquery = MockNamedRelationshipQuery.new
    end
    
    it "should call bidirectional_relationship_query if a bidirectional relationship" do
      rels_ids = ["info:fedora/changeme:1","info:fedora/changeme:2","info:fedora/changeme:3","info:fedora/changeme:4"]
      @mockrelsquery.expects(:outbound_relationships).returns({:has_part=>rels_ids}).at_least_once
      ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
      @mockrelsquery.expects(:pid).returns("changeme:5")
      MockNamedRelationshipQuery.expects(:bidirectional_relationship_query).with("changeme:5","testing_bi_query",ids)
      @mockrelsquery.relationship_query("testing_bi_query")
    end
    
    it "should call outbound_relationship_query if an outbound relationship" do
      rels_ids = ["info:fedora/changeme:1","info:fedora/changeme:2","info:fedora/changeme:3","info:fedora/changeme:4"]
      @mockrelsquery.expects(:outbound_relationships).returns({:is_part_of=>rels_ids}).at_least_once
      ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
      MockNamedRelationshipQuery.expects(:outbound_relationship_query).with("testing_outbound_no_query_param",ids)
      @mockrelsquery.relationship_query("testing_outbound_no_query_param")
    end
    
    it "should call inbound_relationship_query if an inbound relationship" do
      @mockrelsquery.expects(:pid).returns("changeme:5")
      MockNamedRelationshipQuery.expects(:inbound_relationship_query).with("changeme:5","testing_inbound_query")
      @mockrelsquery.relationship_query("testing_inbound_query")
    end
  end
    
  describe ActiveFedora::RelationshipsHelper::ClassMethods do

     after(:each) do
      begin
        @test_object2.delete
      rescue
      end
    end

    describe '#relationships_desc' do
      it 'should initialize relationships_desc to a new hash containing self' do
        @test_object2 = SpecNamedNode.new
        @test_object2.pid = increment_pid
        @test_object2.relationships_desc.should == {:self=>{}}
      end
    end
      
    describe '#register_relationship_desc_subject' do
    
      class MockRegisterNamedSubject < SpecNamedNode
        register_relationship_desc_subject :test
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedSubject.new
        @test_object2.pid = increment_pid
        @test_object2.relationships_desc.should == {:self=>{}, :test=>{}}
      end 
    end
  
    describe '#register_relationship_desc' do
    
      class MockRegisterNamedRelationship < SpecNamedNode
        register_relationship_desc :self, "testing", :is_part_of, :type=>SpecNamedNode
        register_relationship_desc :inbound, "testing2", :has_part, :type=>SpecNamedNode
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedRelationship.new 
        @test_object2.pid = increment_pid
        @test_object2.relationships_desc.should == {:inbound=>{"testing2"=>{:type=>SpecNamedNode, :predicate=>:has_part}}, :self=>{"testing"=>{:type=>SpecNamedNode, :predicate=>:is_part_of}}}
      end 
    end

    describe "#is_bidirectional_relationship?" do
      
      class MockIsBiRegisterNamedRelationship < SpecNamedNode
        register_relationship_desc(:self, "testing_outbound", :is_part_of, :type=>SpecNamedNode)
        register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNamedNode)
        register_relationship_desc(:self, "testing2", :is_member_of,{})
      end

      it "should return true if both inbound and outbound predicates exist, otherwise false" do
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing").should == true
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing2").should == false
        #the inbound and outbound internal relationships will not be bidirectional by themselves
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_inbound").should == false
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_outbound").should == false
      end
    end

    describe '#relationship_has_query_params' do
      class RelsHasQueryParams < SpecNamedNode
        register_relationship_desc :self, "testing", :is_part_of, :query_params=>{:q=>{:testing=>"value"}}
        register_relationship_desc :self, "no_query_testing", :is_part_of
        register_relationship_desc :inbound, "inbound_testing", :has_part, :query_params=>{:q=>{:in_testing=>"value_in"}}
        register_relationship_desc :inbound, "inbound_testing_no_query", :has_part
      end

      it 'should return true if an object has an inbound relationship with query params' do
        RelsHasQueryParams.relationship_has_query_params?(:inbound,"inbound_testing").should == true
      end

      it 'should return false if an object does not have inbound relationship with query params' do
        RelsHasQueryParams.relationship_has_query_params?(:inbound,"inbound_testing_no_query").should == false
      end

      it 'should return true if an object has an outbound relationship with query params' do
        RelsHasQueryParams.relationship_has_query_params?(:self,"testing").should == true
      end

      it 'should return false if an object does not have outbound relationship with query params' do
        RelsHasQueryParams.relationship_has_query_params?(:self,"testing_no_query").should == false
      end
    end

    describe '#create_relationship_name_methods' do
      class MockCreateNamedRelationshipMethods < SpecNamedNode
        register_relationship_desc :self, "testing", :is_part_of, :type=>SpecNamedNode
        create_relationship_name_methods "testing"
      end
      
      it 'should create an append and remove method for each outbound relationship' do
        @test_object2 = MockCreateNamedRelationshipMethods.new
        @test_object2.pid = increment_pid 
        @test_object2.should respond_to(:testing_append)
        @test_object2.should respond_to(:testing_remove)
        #test execution in base_spec since method definitions include methods in ActiveFedora::Base
      end
    end

    describe '#create_bidirectional_relationship_name_methods' do
      class MockCreateNamedRelationshipMethods < SpecNamedNode
        register_relationship_desc(:self, "testing_outbound", :is_part_of, :type=>SpecNamedNode)
        create_bidirectional_relationship_name_methods "testing", "testing_outbound"
      end
      
      it 'should create an append and remove method for each outbound relationship' do
        @test_object2 = MockCreateNamedRelationshipMethods.new
        @test_object2.pid = increment_pid 
        @test_object2.should respond_to(:testing_append)
        @test_object2.should respond_to(:testing_remove)
        #test execution in base_spec since method definitions include methods in ActiveFedora::Base
      end
    end
    
    describe '#def predicate_exists_with_different_relationship_name?' do
      
      it 'should return true if a predicate exists for same subject and different name but not different subject' do
        class MockPredicateExists < SpecNamedNode
          register_relationship_desc :self, "testing", :has_part, :type=>SpecNamedNode
          register_relationship_desc :self, "testing2", :has_member, :type=>SpecNamedNode
          register_relationship_desc :inbound, "testing_inbound", :is_part_of, :type=>SpecNamedNode
      
          predicate_exists_with_different_relationship_name?(:self,"testing",:has_part).should == false
          predicate_exists_with_different_relationship_name?(:self,"testing3",:has_part).should == true
          predicate_exists_with_different_relationship_name?(:inbound,"testing",:has_part).should == false
          predicate_exists_with_different_relationship_name?(:self,"testing2",:has_member).should == false
          predicate_exists_with_different_relationship_name?(:self,"testing3",:has_member).should == true
          predicate_exists_with_different_relationship_name?(:inbound,"testing2",:has_member).should == false
          predicate_exists_with_different_relationship_name?(:self,"testing_inbound",:is_part_of).should == false
          predicate_exists_with_different_relationship_name?(:inbound,"testing_inbound",:is_part_of).should == false
          predicate_exists_with_different_relationship_name?(:inbound,"testing_inbound2",:is_part_of).should == true
        end
      end
    end

     #
    # HYDRA-541
    #
      
    describe "bidirectional_relationship_query" do
      class MockBiNamedRelationshipQuery < SpecNamedNode
        register_relationship_desc(:self, "testing_query_outbound", :has_part, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        register_relationship_desc(:inbound, "testing_query_inbound", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        create_bidirectional_relationship_name_methods("testing","testing_outbound")
        register_relationship_desc(:self, "testing_no_query_param_outbound", :has_part, :type=>SpecNamedNode)
        register_relationship_desc(:inbound, "testing_no_query_param_inbound", :is_part_of, :type=>SpecNamedNode)
        create_bidirectional_relationship_name_methods("testing_no_query_param","testing_no_query_param_outbound")
      end

      #
      # HYDRA-541
      #
      it "should rely on outbound query if inbound query is empty" do
        query = MockBiNamedRelationshipQuery.bidirectional_relationship_query("PID",:testing_query,[])
        query.should_not include("OR ()")
        query2 = MockBiNamedRelationshipQuery.bidirectional_relationship_query("PID",:testing_no_query_param,[])
        query2.should_not include("OR ()")
      end

      it "should return a properly formatted query for a relationship that has a query param defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4","changeme:5"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:info\\:fedora/SpecialPart)"
        end
        expected_string << " OR "
        expected_string << "(is_part_of_s:info\\:fedora/changeme\\:6 AND has_model_s:info\\:fedora/SpecialPart)"
        MockBiNamedRelationshipQuery.bidirectional_relationship_query("changeme:6","testing_query",ids).should == expected_string
      end

      it "should return a properly formatted query for a relationship that does not have a query param defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4","changeme:5"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "id:" + id.gsub(/(:)/, '\\:')
        end
        expected_string << " OR "
        expected_string << "(is_part_of_s:info\\:fedora/changeme\\:6)"
        MockBiNamedRelationshipQuery.bidirectional_relationship_query("changeme:6","testing_no_query_param",ids).should == expected_string
      end
    end

    describe "inbound_relationship_query" do
      class MockInboundNamedRelationshipQuery < SpecNamedNode
        register_relationship_desc(:inbound, "testing_inbound_query", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        register_relationship_desc(:inbound, "testing_inbound_no_query_param", :is_part_of, :type=>SpecNamedNode)
      end

      it "should return a properly formatted query for a relationship that has a query param defined" do
        MockInboundNamedRelationshipQuery.inbound_relationship_query("changeme:1","testing_inbound_query").should == "is_part_of_s:info\\:fedora/changeme\\:1 AND has_model_s:info\\:fedora/SpecialPart"
      end
      
      it "should return a properly formatted query for a relationship that does not have a query param defined" do
        MockInboundNamedRelationshipQuery.inbound_relationship_query("changeme:1","testing_inbound_no_query_param").should == "is_part_of_s:info\\:fedora/changeme\\:1"
      end
    end

    describe "outbound_relationship_query" do
      class MockOutboundNamedRelationshipQuery < SpecNamedNode
        register_relationship_desc(:self, "testing_query", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        register_relationship_desc(:self,"testing_no_query_param", :is_part_of, :type=>SpecNamedNode)
      end

      it "should return a properly formatted query for a relationship that has a query param defined" do
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
        expected_string = ""
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:info\\:fedora/SpecialPart)"
        end
        MockOutboundNamedRelationshipQuery.outbound_relationship_query("testing_query",ids).should == expected_string
      end

      it "should return a properly formatted query for a relationship that does not have a query param defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "id:" + id.gsub(/(:)/, '\\:')
        end
        MockOutboundNamedRelationshipQuery.outbound_relationship_query("testing_no_query_param",ids).should == expected_string
      end
    end 
  end
end
