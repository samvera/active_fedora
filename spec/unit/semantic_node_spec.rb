require 'spec_helper'

require 'xmlsimple'

@@last_pid = 0

class SpecNode2
  include ActiveFedora::RelationshipsHelper
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
      
    before(:all) do
      @pid = "test:sample_pid"
      @uri = "info:fedora/#{@pid}"
      @sample_solr_hits = [{"id"=>"_PID1_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                            {"id"=>"_PID2_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                            {"id"=>"_PID3_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]}]
    end
    
    before(:each) do
      class SpecNode
        include ActiveFedora::RelationshipsHelper
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
      @node.stubs(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>''))
      @node.pid = increment_pid
      @test_object = SpecNode2.new
      @test_object.pid = increment_pid    
      @test_object.stubs(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>''))
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
        local_node.should respond_to(:parts_query)
        # local_node.should respond_to(:parts)
        local_node.should_not respond_to(:containers)
        SpecNode.has_relationship("containers", :is_member_of)  
        local_node.should respond_to(:containers_ids)
        local_node.should respond_to(:containers_query)
      end
      
      it "should add a subject and predicate to the relationships array" do
        SpecNode.has_relationship("parents", :is_part_of)
        SpecNode.relationships.should have_key(:self)
        SpecNode.relationships[:self].should have_key(:is_part_of)
      end
      
      it "should use :inbound as the subject if :inbound => true" do
        SpecNode.has_relationship("parents", :is_part_of, :inbound => true)
        SpecNode.relationships.should have_key(:inbound)
        SpecNode.relationships[:inbound].should have_key(:is_part_of)
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
        
        # local_node.add_relationship(ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/container:A") )
        # local_node.add_relationship(ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/container:B") )
        local_node.expects(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>'')).at_least_once
        local_node.add_relationship(:is_member_of, "info:fedora/container:A")
        local_node.add_relationship(:is_member_of, "info:fedora/container:B")

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
        
      it 'should create relationship descriptions both inbound and outbound' do
        @test_object2 = MockHasRelationship.new
        @test_object2.pid = increment_pid
        @test_object2.stubs(:testing_inbound).returns({})
        @test_object2.expects(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content =>'')).at_least_once
        @test_object2.add_relationship(:has_model, ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode2))
        @test_object2.should respond_to(:testing_append)
        @test_object2.should respond_to(:testing_remove)
        @test_object2.should respond_to(:testing2_append)
        @test_object2.should respond_to(:testing2_remove)
        #make sure append/remove method not created for inbound rel
        @test_object2.should_not respond_to(:testing_inbound_append)
        @test_object2.should_not respond_to(:testing_inbound_remove)
        
        @test_object2.relationships_desc.should == 
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
        local_node.should respond_to(:containers_query)
      end
      
      it "resulting finder should search against solr and use Model#load_instance to build an array of objects" do
        solr_result = (mock("solr result", :is_a? => true, :hits => @sample_solr_hits))
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new()
        local_node.expects(:pid).returns("test:sample_pid")
        SpecNode.expects(:relationships_desc).returns({:inbound=>{"parts"=>{:predicate=>:is_part_of}}}).at_least_once()
        ActiveFedora::SolrService.instance.conn.expects(:query).with("is_part_of_s:info\\:fedora/test\\:sample_pid", :rows=>25).returns(solr_result)
        local_node.parts.map(&:pid).should == ["_PID1_", "_PID2_", "_PID3_"]
      end
      
      it "resulting finder should accept :solr as :response_format value and return the raw Solr Result" do
        solr_result = mock("solr result")
        SpecNode.create_inbound_relationship_finders("constituents", :is_constituent_of, :inbound => true)
        local_node = SpecNode.new
        mock_repo = mock("repo")
        mock_repo.expects(:find_model).never
        local_node.expects(:pid).returns("test:sample_pid")
        SpecNode.expects(:relationships_desc).returns({:inbound=>{"constituents"=>{:predicate=>:is_constituent_of}}}).at_least_once()
        ActiveFedora::SolrService.instance.conn.expects(:query).with("is_constituent_of_s:info\\:fedora/test\\:sample_pid", :rows=>101).returns(solr_result)
        local_node.constituents(:response_format => :solr, :rows=>101).should equal(solr_result)
      end
      
      
      it "resulting _ids finder should search against solr and return an array of fedora PIDs" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        local_node.expects(:pid).returns("test:sample_pid")
        SpecNode.expects(:relationships_desc).returns({:inbound=>{"parts"=>{:predicate=>:is_part_of}}}).at_least_once() 
        ActiveFedora::SolrService.instance.conn.expects(:query).with("is_part_of_s:info\\:fedora/test\\:sample_pid", :rows=>25).returns(mock("solr result", :hits => [Hash["id"=>"pid1"], Hash["id"=>"pid2"]]))
        local_node.parts(:response_format => :id_array).should == ["pid1", "pid2"]
      end
      
      it "resulting _ids finder should call the basic finder with :result_format => :id_array" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        local_node.expects(:parts).with(:response_format => :id_array)
        local_node.parts_ids
      end

      it "resulting _query finder should call relationship_query" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        local_node.expects(:relationship_query).with("parts")
        local_node.parts_query
      end
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
        local_node.should respond_to(:containers_query)
      end
      
      describe " resulting finder" do
        it "should read from relationships array and use Repository.find_model to build an array of objects" do
          SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
          local_node = SpecNode.new
          local_node.expects(:ids_for_outbound).with(:is_member_of).returns(["my:_PID1_", "my:_PID2_", "my:_PID3_"])
          mock_repo = mock("repo")
          solr_result = mock("solr result", :is_a? => true)
          solr_result.expects(:hits).returns(
                        [{"id"=> "my:_PID1_", "has_model_s"=>["info:fedora/afmodel:SpecNode"]},
                         {"id"=> "my:_PID2_", "has_model_s"=>["info:fedora/afmodel:SpecNode"]}, 
                         {"id"=> "my:_PID3_", "has_model_s"=>["info:fedora/afmodel:SpecNode"]}])

          ActiveFedora::SolrService.instance.conn.expects(:query).with("id:my\\:_PID1_ OR id:my\\:_PID2_ OR id:my\\:_PID3_").returns(solr_result)
          local_node.containers.map(&:pid).should == ["my:_PID1_", "my:_PID2_", "my:_PID3_"]
        end
      
        it "should accept :solr as :response_format value and return the raw Solr Result" do
          solr_result = mock("solr result")
          SpecNode.create_outbound_relationship_finders("constituents", :is_constituent_of)
          local_node = SpecNode.new
          mock_repo = mock("repo")
          mock_repo.expects(:find_model).never
          local_node.expects(:rels_ext).returns(stub('rels-ext', :content=>''))
          ActiveFedora::SolrService.instance.conn.expects(:query).returns(solr_result)
          local_node.constituents(:response_format => :solr).should equal(solr_result)
        end
        
        it "(:response_format => :id_array) should read from relationships array" do
          SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
          local_node = SpecNode.new
          local_node.expects(:ids_for_outbound).with(:is_member_of).returns([])
          local_node.containers_ids
        end
      
        it "(:response_format => :id_array) should return an array of fedora PIDs" do
          SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
          local_node = SpecNode.new
          local_node.expects(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>'')).at_least_once
          local_node.add_relationship(@test_relationship1.predicate, @test_relationship1.object)
          result = local_node.containers_ids
          result.should be_instance_of(Array)
          result.should include("demo:10")
        end
        
      end
      
      describe " resulting _ids finder" do
        it "should call the basic finder with :result_format => :id_array" do
          SpecNode.create_outbound_relationship_finders("parts", :is_part_of)
          local_node = SpecNode.new
          local_node.expects(:parts).with(:response_format => :id_array)
          local_node.parts_ids
        end
      end

      it "resulting _query finder should call relationship_query" do
        SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
        local_node = SpecNode.new
        local_node.expects(:relationship_query).with("containers")
        local_node.containers_query
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
        @local_node.expects(:ids_for_outbound).with(:has_part).returns(["mypid:1"])
        id_array_query = ActiveFedora::SolrService.construct_query_for_pids(["mypid:1"])
        solr_result = mock("solr result")
        ActiveFedora::SolrService.instance.conn.expects(:query).with("#{id_array_query} OR (is_part_of_s:info\\:fedora/test\\:sample_pid)", :rows=>25).returns(solr_result)
        @local_node.all_parts(:response_format=>:solr)
      end

      it "should register both inbound and outbound predicate components" do
        @local_node.class.relationships[:inbound].has_key?(:is_part_of).should == true
        @local_node.class.relationships[:self].has_key?(:has_part).should == true
      end
    
      it "should register relationship names for inbound, outbound" do
        @local_node.relationship_names.include?("all_parts_inbound").should == true
        @local_node.relationship_names.include?("all_parts_outbound").should == true
      end

      it "should register finder methods for the bidirectional relationship name" do
        @local_node.should respond_to(:all_parts)
        @local_node.should respond_to(:all_parts_ids)
        @local_node.should respond_to(:all_parts_query)
        @local_node.should respond_to(:all_parts_from_solr)
      end

      it "resulting _query finder should call relationship_query" do
        SpecNode.create_bidirectional_relationship_finders("containers", :is_member_of, :has_member)
        local_node = SpecNode.new
        local_node.expects(:relationship_query).with("containers")
        local_node.containers_query
      end
    end
    
    describe "#has_bidirectional_relationship" do
      it "should ..." do
        SpecNode.expects(:create_bidirectional_relationship_finders).with("all_parts", :has_part, :is_part_of, {})
        SpecNode.has_bidirectional_relationship("all_parts", :has_part, :is_part_of)
      end

      it "should have relationships_by_name and relationships hashes contain bidirectionally related objects" do
        SpecNode.has_bidirectional_relationship("all_parts", :has_part, :is_part_of)
        @local_node = SpecNode.new
        @local_node.pid = "mypid1"
        @local_node2 = SpecNode.new
        @local_node2.pid = "mypid2"
        r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(SpecNode)}) 
        @local_node.expects(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>'')).at_least_once
        @local_node.add_relationship(r.predicate, r.object)
        @local_node2.expects(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>'')).at_least_once
        @local_node2.add_relationship(r.predicate, r.object)
        r2 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@local_node2})
        @local_node.add_relationship(r2.predicate, r2.object)
        r3 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>@local_node})
        @local_node2.add_relationship(r3.predicate, r3.object)
        @local_node.ids_for_outbound(:has_part).should == [@local_node2.pid]
        @local_node.ids_for_outbound(:has_model).should == ['afmodel:SpecNode']
        @local_node2.ids_for_outbound(:has_part).should == [@local_node.pid]
        @local_node2.ids_for_outbound(:has_model).should == ['afmodel:SpecNode']
        @local_node.relationships_by_name(false).should == {:self=>{"all_parts_outbound"=>[r2.object]},:inbound=>{"all_parts_inbound"=>[]}}
        @local_node2.relationships_by_name(false).should == {:self=>{"all_parts_outbound"=>[r3.object]},:inbound=>{"all_parts_inbound"=>[]}}
      end
    end
    
    describe ".add_relationship" do
      it "should add relationship to the relationships graph" do
        @node.add_relationship(@test_relationship.predicate, @test_relationship.object)
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
        @node.add_relationship(@test_relationship.predicate, @test_relationship.object, true)
        @node.ids_for_outbound("isMemberOf").should == ['demo:9']
      end
      
      it "adding relationship to an instance should not affect class-level relationships hash" do 
        local_test_node1 = SpecNode.new
        local_test_node2 = SpecNode.new
        local_test_node1.expects(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>'')).at_least_once
        local_test_node1.add_relationship(@test_relationship1.predicate, @test_relationship1.object)
        local_test_node2.expects(:rels_ext).returns(stub('rels-ext', :content=>''))
        
        local_test_node1.ids_for_outbound(:is_member_of).should == ["demo:10"]
        local_test_node2.ids_for_outbound(:is_member_of).should == []
      end
      
    end
    
    describe '#relationships' do
      
      it "should return a hash" do
        SpecNode.relationships.class.should == Hash
      end

    end
    
    it "should provide .outbound_relationships" do 
      @node.should respond_to(:outbound_relationships)
    end
    
      
    describe '#remove_relationship' do
      it 'should remove a relationship from the relationships hash' do
        r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>"info:fedora/3"})
        r2 = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_part,:object=>"info:fedora/4"})
        @test_object.expects(:rels_ext).returns(stub("rels_ext", :dirty= => true, :content=>'')).times(4)
        @test_object.add_relationship(r.predicate, r.object)
        @test_object.add_relationship(r2.predicate, r2.object)
        #check both are there
        @test_object.ids_for_outbound(:has_part).should include "3", "4"
        @test_object.remove_relationship(r.predicate, r.object)
        #check returns false if relationship does not exist and does nothing with different predicate
        rBad = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_member,:object=>"info:fedora/4"})
        @test_object.remove_relationship(rBad.predicate, rBad.object)
        #check only one item removed
        @test_object.ids_for_outbound(:has_part).should == ['4']
        @test_object.remove_relationship(r2.predicate, r2.object)
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
