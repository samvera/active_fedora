require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'xmlsimple'

class SpecNamedNode
  include ActiveFedora::NamedRelationshipHelper
  
  attr_accessor :pid
end

describe ActiveFedora::NamedRelationshipHelper do
  
  def increment_pid
    @@last_pid += 1    
  end
    
  describe ActiveFedora::NamedRelationshipHelper::ClassMethods do

     after(:each) do
      begin
        @test_object2.delete
      rescue
      end
    end

    describe '#named_relationships_desc' do
      it 'should initialize named_relationships_desc to a new hash containing self' do
        @test_object2 = SpecNamedNode.new
        @test_object2.pid = increment_pid
        @test_object2.named_relationships_desc.should == {:self=>{}}
      end
    end
      
    describe '#register_named_subject' do
    
      class MockRegisterNamedSubject < SpecNamedNode
        register_named_subject :test
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedSubject.new
        @test_object2.pid = increment_pid
        @test_object2.named_relationships_desc.should == {:self=>{}, :test=>{}}
      end 
    end
  
    describe '#register_named_relationship' do
    
      class MockRegisterNamedRelationship < SpecNamedNode
        register_named_relationship :self, "testing", :is_part_of, :type=>SpecNamedNode
        register_named_relationship :inbound, "testing2", :has_part, :type=>SpecNamedNode
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedRelationship.new 
        @test_object2.pid = increment_pid
        @test_object2.named_relationships_desc.should == {:inbound=>{"testing2"=>{:type=>SpecNamedNode, :predicate=>:has_part}}, :self=>{"testing"=>{:type=>SpecNamedNode, :predicate=>:is_part_of}}}
      end 
    end

<<<<<<< HEAD
    describe "#is_bidirectional_relationship?" do
      
      class MockIsBiRegisterNamedRelationship < SpecNamedNode
        register_named_relationship(:self, "testing_outbound", :is_part_of, :type=>SpecNamedNode)
        register_named_relationship(:inbound, "testing_inbound", :has_part, :type=>SpecNamedNode)
        register_named_relationship(:self, "testing2", :is_member_of,{})
      end

      it "should return true if both inbound and outbound predicates exist, otherwise false" do
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing").should == true
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing2").should == false
        #the inbound and outbound internal relationships will not be bidirectional by themselves
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_inbound").should == false
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_outbound").should == false
      end
    end

=======
>>>>>>> Moved remaining named relationship methods from Semantic Node to NamedRelationshipHelper
    describe '#relationship_has_query_params' do
      class RelsHasQueryParams < SpecNamedNode
        register_named_relationship :self, "testing", :is_part_of, :query_params=>{:q=>{:testing=>"value"}}
        register_named_relationship :self, "no_query_testing", :is_part_of
        register_named_relationship :inbound, "inbound_testing", :has_part, :query_params=>{:q=>{:in_testing=>"value_in"}}
        register_named_relationship :inbound, "inbound_testing_no_query", :has_part
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
<<<<<<< HEAD

    describe '#create_named_relationship_methods' do
      class MockCreateNamedRelationshipMethods < SpecNamedNode
        register_named_relationship :self, "testing", :is_part_of, :type=>SpecNamedNode
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
      class MockCreateNamedRelationshipMethods < SpecNamedNode
        register_named_relationship(:self, "testing_outbound", :is_part_of, :type=>SpecNamedNode)
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
=======
>>>>>>> Moved remaining named relationship methods from Semantic Node to NamedRelationshipHelper
    
    describe '#def named_predicate_exists_with_different_name?' do
      
      it 'should return true if a predicate exists for same subject and different name but not different subject' do
        class MockPredicateExists < SpecNamedNode
          register_named_relationship :self, "testing", :has_part, :type=>SpecNamedNode
          register_named_relationship :self, "testing2", :has_member, :type=>SpecNamedNode
          register_named_relationship :inbound, "testing_inbound", :is_part_of, :type=>SpecNamedNode
      
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
<<<<<<< HEAD

     #
    # HYDRA-541
    #
      
    describe "bidirectional_named_relationship_query" do
      class MockBiNamedRelationshipQuery < SpecNamedNode
        register_named_relationship(:self, "testing_query_outbound", :has_part, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        register_named_relationship(:inbound, "testing_query_inbound", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        create_bidirectional_named_relationship_methods("testing","testing_outbound")
        register_named_relationship(:self, "testing_no_query_param_outbound", :has_part, :type=>SpecNamedNode)
        register_named_relationship(:inbound, "testing_no_query_param_inbound", :is_part_of, :type=>SpecNamedNode)
        create_bidirectional_named_relationship_methods("testing_no_query_param","testing_no_query_param_outbound")
      end

      #
      # HYDRA-541
      #
      it "should rely on outbound query if inbound query is empty" do
        query = MockBiNamedRelationshipQuery.bidirectional_named_relationship_query("PID",:testing_query,[])
        query.should_not include("OR ()")
        query2 = MockBiNamedRelationshipQuery.bidirectional_named_relationship_query("PID",:testing_no_query_param,[])
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
        MockBiNamedRelationshipQuery.bidirectional_named_relationship_query("changeme:6","testing_query",ids).should == expected_string
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
        MockBiNamedRelationshipQuery.bidirectional_named_relationship_query("changeme:6","testing_no_query_param",ids).should == expected_string
      end
    end

    describe "inbound_named_relationship_query" do
      class MockInboundNamedRelationshipQuery < SpecNamedNode
        register_named_relationship(:inbound, "testing_inbound_query", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        register_named_relationship(:inbound, "testing_inbound_no_query_param", :is_part_of, :type=>SpecNamedNode)
      end

      it "should return a properly formatted query for a relationship that has a query param defined" do
        MockInboundNamedRelationshipQuery.inbound_named_relationship_query("changeme:1","testing_inbound_query").should == "is_part_of_s:info\\:fedora/changeme\\:1 AND has_model_s:info\\:fedora/SpecialPart"
      end
      
      it "should return a properly formatted query for a relationship that does not have a query param defined" do
        MockInboundNamedRelationshipQuery.inbound_named_relationship_query("changeme:1","testing_inbound_no_query_param").should == "is_part_of_s:info\\:fedora/changeme\\:1"
      end
    end

    describe "outbound_named_relationship_query" do
      class MockOutboundNamedRelationshipQuery < SpecNamedNode
        register_named_relationship(:self, "testing_query", :is_part_of, :type=>SpecNamedNode, :query_params=>{:q=>{:has_model_s=>"info:fedora/SpecialPart"}})
        register_named_relationship(:self,"testing_no_query_param", :is_part_of, :type=>SpecNamedNode)
      end

      it "should return a properly formatted query for a relationship that has a query param defined" do
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
        expected_string = ""
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:info\\:fedora/SpecialPart)"
        end
        MockOutboundNamedRelationshipQuery.outbound_named_relationship_query("testing_query",ids).should == expected_string
      end

      it "should return a properly formatted query for a relationship that does not have a query param defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "id:" + id.gsub(/(:)/, '\\:')
        end
        MockOutboundNamedRelationshipQuery.outbound_named_relationship_query("testing_no_query_param",ids).should == expected_string
      end
    end 
=======
>>>>>>> Moved remaining named relationship methods from Semantic Node to NamedRelationshipHelper
  end
end
