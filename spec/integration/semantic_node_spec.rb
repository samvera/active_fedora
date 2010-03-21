require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'

describe ActiveFedora::SemanticNode do
  
  before(:all) do 
    class SpecNode 
      include ActiveFedora::SemanticNode
      has_relationship "collection_members", :has_collection_member
    end
    @node = SpecNode.new
    class SpecModel < ActiveFedora::Base
      has_relationship("parts", :is_part_of, :inbound => true)
      has_relationship("containers", :is_member_of)
    end
    
    @test_object = SpecModel.new
    @test_object.save
    
    @part1 = ActiveFedora::Base.new()
    @part1.add_relationship(:is_part_of, @test_object)
    @part1.save
    @part2 = ActiveFedora::Base.new()
    @part2.add_relationship(:is_part_of, @test_object)
    @part2.save
    
    
    @container1 = ActiveFedora::Base.new()
    @container1.save
    @container2 = ActiveFedora::Base.new()    
    @container2.save
    
    @test_object.add_relationship(:is_member_of, @container1)
    @test_object.add_relationship(:is_member_of, @container2)
    @test_object.save
  end
  
  after(:all) do
    @part1.delete 
    @part2.delete
    @container1.delete
    @container2.delete
    @test_object.delete
    
    Object.send(:remove_const, :SpecModel)

  end
  
  describe '#has_relationship' do
    it "should create useable finders" do
      spec_node = SpecNode.new
      spec_node.collection_members.should == []
      rel = ActiveFedora::Relationship.new(:subject => :self, :predicate => :has_collection_member, :object => @test_object.pid)  
      spec_node.add_relationship(rel)
      collection_members = spec_node.collection_members
      collection_members.length.should == 1
      collection_members.first.pid.should == @test_object.pid
      collection_members.first.class.should == @test_object.class
    end
    it "should create useable inbound finders if :inbound is set to true"
  end
  
  describe "inbound relationship finders" do
    it "should return an array of Base objects" do
      parts = @test_object.parts
      parts.each do |part|
        part.should be_kind_of(ActiveFedora::Base)
      end  
    end
    it "_ids should return an array of pids" do
      ids = @test_object.parts_ids
      ids.each do |id|
        id.should satisfy {|id| id == @part1.pid || @part2.pid}
      end  
    end
  end
  
  describe "outbound relationship finders" do
    it "should return an array of Base objects" do
      containers = @test_object.containers
      containers.length.should > 0
      containers.each do |container|
        container.should be_kind_of(ActiveFedora::Base)
      end  
    end
    it "_ids should return an array of pids" do
      ids = @test_object.containers_ids
      ids.each do |id|
        id.should satisfy {|id| id == @container1.pid || @container2.pid}
      end  
    end
  end
  
end
