require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'

describe ActiveFedora::SemanticNode do
  
  before(:all) do 
    class SpecNode 
      include ActiveFedora::SemanticNode
      has_relationship "collection_members", :has_collection_member
    end
    @node = SpecNode.new
    class SNSpecModel < ActiveFedora::Base
      has_relationship("parts", :is_part_of, :inbound => true)
      has_relationship("containers", :is_member_of)
      has_bidirectional_relationship("bi_containers", :is_member_of, :has_member)
    end
    class SpecNodeQueryParam < ActiveFedora::Base
      has_relationship("parts", :is_part_of, :inbound => true)
      has_relationship("special_parts", :is_part_of, :inbound => true, :query_params=>{:q=>{"has_model_s"=>"info:fedora/SpecialPart"}})
      has_relationship("containers", :is_member_of)
      has_relationship("special_containers", :is_member_of, :query_params=>{:q=>{"has_model_s"=>"info:fedora/SpecialContainer"}})
      has_bidirectional_relationship("bi_containers", :is_member_of, :has_member)
      has_bidirectional_relationship("bi_special_containers", :is_member_of, :has_member, :query_params=>{:q=>{"has_model_s"=>"info:fedora/SpecialContainer"}})
    end
    
    @test_object = SNSpecModel.new
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
    @container3 = ActiveFedora::Base.new()    
    @container3.save
    @container4 = ActiveFedora::Base.new()    
    @container4.save
    
    @test_object.add_relationship(:is_member_of, @container1)
    @test_object.add_relationship(:is_member_of, @container2)
    @test_object.add_relationship(:is_member_of, @container3)
    @test_object.save

    @container4.add_relationship(:has_member,@test_object)
    @container4.save

    @special_container = ActiveFedora::Base.new()
    @special_container.add_relationship(:has_model,"SpecialContainer")
    @special_container.save

    @special_container3 = ActiveFedora::Base.new()
    @special_container3.add_relationship(:has_model,"SpecialContainer")
    @special_container3.save

    @special_container4 = ActiveFedora::Base.new()
    @special_container4.add_relationship(:has_model,"SpecialContainer")
    @special_container4.save

    #even though adding container3 and 3 special containers, it should only include the special containers when returning via named finder methods
    #also should only return special part similarly
    @test_object_query = SpecNodeQueryParam.new
    @test_object_query.add_relationship(:is_member_of, @container3)
    @test_object_query.add_relationship(:is_member_of, @special_container)
    @test_object_query.add_relationship(:is_member_of, @special_container3)
    @test_object_query.add_relationship(:is_member_of, @special_container4)
    @test_object_query.save

    @special_container2 = ActiveFedora::Base.new()
    @special_container2.add_relationship(:has_model,"SpecialContainer")
    @special_container2.add_relationship(:has_member,@test_object_query.pid)
    @special_container2.save

    @part3 = ActiveFedora::Base.new()
    @part3.add_relationship(:is_part_of, @test_object_query)
    @part3.save

    @special_part = ActiveFedora::Base.new()
    @special_part.add_relationship(:has_model,"SpecialPart")
    @special_part.add_relationship(:is_part_of, @test_object_query)
    @special_part.save
   
  end
  
  after(:all) do
    begin
    @part1.delete 
    rescue
    end
    begin
    @part2.delete
    rescue
    end
    begin
    @part3.delete
    rescue
    end
    begin
    @container1.delete
    rescue
    end
    begin
    @container2.delete
    rescue
    end
    begin
    @container3.delete
    rescue
    end
    begin
    @test_object.delete
    rescue
    end
    begin
    @test_object_query.delete
    rescue
    end
    begin
    @special_part.delete
    rescue
    end
    begin
    @special_container.delete
    rescue
    end
    begin
    @special_container2.delete
    rescue
    end
    Object.send(:remove_const, :SNSpecModel)

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
      ids.size.should == 2
      ids.include?(@part1.pid).should == true
      ids.include?(@part2.pid).should == true
    end
    it "should return an array of Base objects with some filtered out if using query params" do
      @test_object_query.special_parts_ids.should == [@special_part.pid]
    end

    it "should return an array of all Base objects with relationship if not using query params" do
      @test_object_query.parts_ids.size.should == 2
      @test_object_query.parts_ids.include?(@special_part.pid).should == true
      @test_object_query.parts_ids.include?(@part3.pid).should == true
    end

    it "should return a solr query for an inbound relationship" do
      @test_object_query.special_parts_query.should == "#{@test_object_query.named_relationship_predicates[:inbound]['special_parts']}_s:#{@test_object_query.internal_uri.gsub(/(:)/, '\\:')} AND has_model_s:info\\:fedora/SpecialPart"
    end
  end

  describe "inbound named relationship query" do
    it "should return a properly formatted query for a relationship that has a query param defined" do
      SpecNodeQueryParam.inbound_named_relationship_query(@test_object_query.pid,"special_parts").should == "#{@test_object_query.named_relationship_predicates[:inbound]['special_parts']}_s:#{@test_object_query.internal_uri.gsub(/(:)/, '\\:')} AND has_model_s:info\\:fedora/SpecialPart"
    end

    it "should return a properly formatted query for a relationship that does not have a query param defined" do
      SpecNodeQueryParam.inbound_named_relationship_query(@test_object_query.pid,"parts").should == "is_part_of_s:#{@test_object_query.internal_uri.gsub(/(:)/, '\\:')}"
    end
  end

  describe "outbound named relationship query" do
    it "should return a properly formatted query for a relationship that has a query param defined" do
      expected_string = ""
      @test_object_query.containers_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:info\\:fedora/SpecialContainer)"
      end
      SpecNodeQueryParam.outbound_named_relationship_query("special_containers",@test_object_query.containers_ids).should == expected_string
    end

    it "should return a properly formatted query for a relationship that does not have a query param defined" do
      expected_string = ""
      @test_object_query.containers_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "id:" + id.gsub(/(:)/, '\\:')
      end
      SpecNodeQueryParam.outbound_named_relationship_query("containers",@test_object_query.containers_ids).should == expected_string
    end
  end

  describe "bidirectional named relationship query" do
    it "should return a properly formatted query for a relationship that has a query param defined" do
      expected_string = ""
      @test_object_query.bi_containers_outbound_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:info\\:fedora/SpecialContainer)"
      end
      expected_string << " OR "
      expected_string << "(#{@test_object_query.named_relationship_predicates[:inbound]['bi_special_containers_inbound']}_s:#{@test_object_query.internal_uri.gsub(/(:)/, '\\:')} AND has_model_s:info\\:fedora/SpecialContainer)"
      SpecNodeQueryParam.bidirectional_named_relationship_query(@test_object_query.pid,"bi_special_containers",@test_object_query.bi_containers_outbound_ids).should == expected_string
    end

    it "should return a properly formatted query for a relationship that does not have a query param defined" do
      expected_string = ""
      @test_object_query.bi_containers_outbound_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "id:" + id.gsub(/(:)/, '\\:')
      end
      expected_string << " OR "
      expected_string << "(#{@test_object_query.named_relationship_predicates[:inbound]['bi_special_containers_inbound']}_s:#{@test_object_query.internal_uri.gsub(/(:)/, '\\:')})"
      SpecNodeQueryParam.bidirectional_named_relationship_query(@test_object_query.pid,"bi_containers",@test_object_query.bi_containers_outbound_ids).should == expected_string
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
      ids.size.should == 3
      ids.include?(@container1.pid).should == true
      ids.include?(@container2.pid).should == true
      ids.include?(@container3.pid).should == true
      ids.include?(@container4.pid).should == false
    end

    it "should return an array of Base objects with some filtered out if using query params" do
      @test_object_query.special_containers_ids.size.should == 3
      @test_object_query.special_containers_ids.include?(@container3.pid).should == false
      @test_object_query.special_containers_ids.include?(@special_container.pid).should == true
      @test_object_query.special_containers_ids.include?(@special_container3.pid).should == true
      @test_object_query.special_containers_ids.include?(@special_container4.pid).should == true
    end

    it "should return an array of all Base objects with relationship if not using query params" do
      @test_object_query.containers_ids.size.should == 4
      @test_object_query.containers_ids.include?(@special_container2.pid).should == false
      @test_object_query.containers_ids.include?(@special_container.pid).should == true
      @test_object_query.containers_ids.include?(@container3.pid).should == true
      @test_object_query.containers_ids.include?(@special_container3.pid).should == true
      @test_object_query.containers_ids.include?(@special_container4.pid).should == true
    end

    it "should return a solr query for an outbound relationship" do
    end

    it "should return an array of Base objects with some filtered out if using query params" do
      @test_object_query.special_containers_ids.size.should == 3
      @test_object_query.special_containers_ids.include?(@container3.pid).should == false
      @test_object_query.special_containers_ids.include?(@special_container.pid).should == true
      @test_object_query.special_containers_ids.include?(@special_container3.pid).should == true
      @test_object_query.special_containers_ids.include?(@special_container4.pid).should == true
    end

    it "should return an array of all Base objects with relationship if not using query params" do
      @test_object_query.containers_ids.size.should == 4
      @test_object_query.containers_ids.include?(@special_container2.pid).should == false
      @test_object_query.containers_ids.include?(@special_container.pid).should == true
      @test_object_query.containers_ids.include?(@container3.pid).should == true
      @test_object_query.containers_ids.include?(@special_container3.pid).should == true
      @test_object_query.containers_ids.include?(@special_container4.pid).should == true
    end

    it "should return a solr query for an outbound relationship" do
      expected_string = ""
      @test_object_query.containers_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:info\\:fedora/SpecialContainer)"
      end
      @test_object_query.special_containers_query.should == expected_string
    end 
  end  

  describe "bidirectional relationship finders" do
    it "should return an array of Base objects" do
      containers = @test_object.bi_containers
      containers.length.should > 0
      containers.each do |container|
        container.should be_kind_of(ActiveFedora::Base)
      end  
    end
    it "_ids should return an array of pids" do
      ids = @test_object.bi_containers_ids
      ids.size.should == 4
      ids.include?(@container1.pid).should == true
      ids.include?(@container2.pid).should == true
      ids.include?(@container3.pid).should == true
      ids.include?(@container4.pid).should == true
    end

    it "should return an array of Base objects with some filtered out if using query params" do
      ids = @test_object_query.bi_special_containers_ids
      ids.size.should == 4
      ids.include?(@container1.pid).should == false
      ids.include?(@container2.pid).should == false
      ids.include?(@container3.pid).should == false
      ids.include?(@special_container.pid).should == true
      ids.include?(@special_container2.pid).should == true
      ids.include?(@special_container3.pid).should == true
      ids.include?(@special_container4.pid).should == true
    end

    it "should return an array of all Base objects with relationship if not using query params" do
      ids = @test_object_query.bi_containers_ids
      ids.size.should == 5
      ids.include?(@container3.pid).should == true
      ids.include?(@special_container.pid).should == true
      ids.include?(@special_container2.pid).should == true
      ids.include?(@special_container3.pid).should == true
      ids.include?(@special_container4.pid).should == true
    end

    it "should return a solr query for a bidirectional relationship" do
      expected_string = ""
      @test_object_query.bi_containers_outbound_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:info\\:fedora/SpecialContainer)"
      end
      expected_string << " OR "
      expected_string << "(#{@test_object_query.named_relationship_predicates[:inbound]['bi_special_containers_inbound']}_s:#{@test_object_query.internal_uri.gsub(/(:)/, '\\:')} AND has_model_s:info\\:fedora/SpecialContainer)"
      @test_object_query.bi_special_containers_query.should == expected_string
    end
  end

  #putting this test here instead of named_relationships_helper because testing that named_relationships hash gets refreshed if the relationships hash is changed
  describe "named_relationships" do
    class MockSemNamedRelationships
      include ActiveFedora::SemanticNode
      has_relationship "testing", :has_part
      has_relationship "testing2", :has_member
      has_relationship "testing_inbound", :has_part, :inbound=>true
    end

    it 'should automatically update the named_relationships if relationships has changed (no refresh of named_relationships hash unless relationships hash has changed' do
      @test_object2 = MockSemNamedRelationships.new
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockSemNamedRelationships)}) 
      @test_object2.add_relationship(r)
      #should return expected named relationships
      @test_object2.named_relationships.should == {:self=>{"testing"=>[],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
      r3 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@test_object})
      @test_object2.add_relationship(r3)
      @test_object2.named_relationships.should == {:self=>{"testing"=>[r3.object],"testing2"=>[]},:inbound=>{"testing_inbound"=>[]}}
      r4 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_member,:object=>"3"})
      @test_object2.add_relationship(r4)
      @test_object2.named_relationships.should == {:self=>{"testing"=>[r3.object],"testing2"=>[r4.object]},:inbound=>{"testing_inbound"=>[]}}
    end
  end
end
