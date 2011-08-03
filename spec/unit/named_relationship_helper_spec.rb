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
  end
end
