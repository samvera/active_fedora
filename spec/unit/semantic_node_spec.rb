require 'spec_helper'

require 'xmlsimple'

@@last_pid = 0

class SpecNode2
  include ActiveFedora::Relationships
  include ActiveFedora::SemanticNode
  
  attr_accessor :pid
  def internal_uri
    'info:fedora/' + pid.to_s
  end
end

describe ActiveFedora::SemanticNode do

  
  describe "with a bunch of objects" do
    def increment_pid
      @@last_pid += 1    
    end
    
    before(:each) do
      class SpecNode
        include ActiveFedora::Relationships
        include ActiveFedora::SemanticNode
        
        attr_accessor :pid
        def initialize (params={}) 
          self.pid = params[:pid]
        end
        def internal_uri
          'info:fedora/' + pid.to_s
        end
      end
    
      class AudioRecord
        attr_accessor :pid
        def initialize (params={}) 
          self.pid = params[:pid]
        end
        def internal_uri
          'info:fedora/' + pid.to_s
        end
      end
      
      @node = SpecNode.new
      @node.stub(:rels_ext).and_return(stub("rels_ext", :content_will_change! => true, :content=>''))
      @node.pid = increment_pid
      @test_object = SpecNode2.new
      @test_object.pid = increment_pid    
      @test_object.stub(:rels_ext).and_return(stub("rels_ext", :content_will_change! => true, :content=>''))
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
   

    it 'should provide .internal_uri' do
      @node.should  respond_to(:internal_uri)
    end
    
    
    describe ".add_relationship" do
      it "should add relationship to the relationships graph" do
        @node.add_relationship("isMemberOf", 'demo:9')
        @node.ids_for_outbound("isMemberOf").should == ['demo:9']
      end
      it "should not be written into the graph until it is saved" do
        @n1 = ActiveFedora::Base.new
        @node.add_relationship(:has_part, @n1)
        @node.relationships.statements.to_a.first.object.to_s.should == 'info:fedora/__DO_NOT_USE__' 
        @n1.save
        @node.relationships.statements.to_a.first.object.to_s.should == @n1.internal_uri
      end

      it "should add a literal relationship to the relationships graph" do
        @node.add_relationship("isMemberOf", 'demo:9', true)
        @node.relationships("isMemberOf").should == ['demo:9']
      end
      
      it "adding relationship to an instance should not affect class-level relationships hash" do 
        local_test_node1 = SpecNode.new
        local_test_node2 = SpecNode.new
        local_test_node1.stub(:rels_ext).and_return(stub("rels_ext", :content_will_change! => true, :content=>''))
        local_test_node1.add_relationship(:is_member_of, 'demo:10')
        local_test_node2.stub(:rels_ext).and_return(stub('rels-ext', :content=>''))
        
        local_test_node1.relationships(:is_member_of).should == ["demo:10"]
        local_test_node2.relationships(:is_member_of).should == []
      end
      
    end

    describe ".clear_relationship" do
      before do
        @node.add_relationship(:is_member_of, 'demo:9')
        @node.add_relationship(:is_member_of, 'demo:7')
        @node.add_relationship(:is_brother_of, 'demo:9')
      end
      it "should clear the specified relationship" do
        @node.clear_relationship(:is_member_of)
        @node.relationships(:is_member_of).should == []
        @node.relationships(:is_brother_of).should == ['demo:9']
      end
      
    end
    
    
    it "should provide .outbound_relationships" do 
      @node.should respond_to(:outbound_relationships)
    end
    
      
    describe '#remove_relationship' do
      it 'should remove a relationship from the relationships hash' do
        @test_object.stub(:rels_ext).and_return(stub("rels_ext", :content_will_change! => true, :content=>''))
        @test_object.add_relationship(:has_part, "info:fedora/3")
        @test_object.add_relationship(:has_part, "info:fedora/4")
        #check both are there
        @test_object.ids_for_outbound(:has_part).should include "3", "4"
        @test_object.remove_relationship(:has_part, "info:fedora/3")
        #check returns false if relationship does not exist and does nothing with different predicate
        @test_object.remove_relationship(:has_member,"info:fedora/4")
        #check only one item removed
        @test_object.ids_for_outbound(:has_part).should == ['4']
        @test_object.remove_relationship(:has_part,"info:fedora/4")
        #check last item removed and predicate removed since now emtpy
        @test_object.ids_for_outbound(:has_part).should == []

        @test_object.relationships_are_dirty.should == true
        
      end
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
  end
end
