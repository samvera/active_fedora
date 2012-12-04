require 'spec_helper'

@@last_pid = 0

describe ActiveFedora::Relationships do
    def increment_pid
      @@last_pid += 1    
    end
    
    before(:all) do
      @part_of_sample = "is_part_of_s:#{solr_uri("info:fedora/test:sample_pid")}"
      @constituent_of_sample = "is_constituent_of_s:#{solr_uri("info:fedora/test:sample_pid")}"
      @is_part_query = "has_model_s:#{solr_uri("info:fedora/SpecialPart")}"
    end

    before(:each) do
      class SpecNode
        include ActiveFedora::Relationships
        include ActiveFedora::SemanticNode
        include ActiveFedora::Model
        
        attr_accessor :pid
        def init_with(inner_obj)
          self.pid = inner_obj.pid
          self
        end
        def self.connection_for_pid(pid)
        end

        def internal_uri
          'info:fedora/' + pid.to_s
        end
      end
    end
    after(:each) do
      Object.send(:remove_const, :SpecNode)
    end

    it 'should provide #has_relationship' do
      SpecNode.should  respond_to(:has_relationship)
      SpecNode.should  respond_to(:has_relationship)
    end
    describe '#relationships' do
      
      it "should return a hash" do
        SpecNode.relationships.class.should == Hash
      end

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
        #local_node.internal_uri = "info:fedora/#{@pid}"
        local_node.pid = @pid
        
        local_node.expects(:rels_ext).returns(stub("rels_ext", :content_will_change! => true, :content=>'')).at_least_once
        local_node.add_relationship(:is_member_of, "info:fedora/container:A")
        local_node.add_relationship(:is_member_of, "info:fedora/container:B")

        containers_result = local_node.containers_ids
        containers_result.should be_instance_of(Array)
        containers_result.should include("container:A")
        containers_result.should include("container:B")
      end
      
      describe "has_relationship" do
        before do
          class MockHasRelationship 
            include ActiveFedora::SemanticNode
            include ActiveFedora::Relationships
            has_relationship "testing", :has_part, :type=>String
            has_relationship "testing2", :has_member, :type=>String
            has_relationship "testing_inbound", :has_part, :type=>String, :inbound=>true
            attr_accessor :pid
            def internal_uri
              'info:fedora/' + pid.to_s
            end
          end
        end
        after(:each) do
          Object.send(:remove_const, :MockHasRelationship)
        end
          
        it 'should create relationship descriptions both inbound and outbound' do
          @test_object2 = MockHasRelationship.new
          @test_object2.pid = increment_pid
          @test_object2.stubs(:testing_inbound).returns({})
          @test_object2.expects(:rels_ext).returns(stub("rels_ext", :content_will_change! => true, :content =>'')).at_least_once
          @test_object2.add_relationship(:has_model, SpecNode.to_class_uri)
          @test_object2.should respond_to(:testing_append)
          @test_object2.should respond_to(:testing_remove)
          @test_object2.should respond_to(:testing2_append)
          @test_object2.should respond_to(:testing2_remove)
          #make sure append/remove method not created for inbound rel
          @test_object2.should_not respond_to(:testing_inbound_append)
          @test_object2.should_not respond_to(:testing_inbound_remove)
          
          @test_object2.class.relationships_desc.should == 
          {:inbound=>{"testing_inbound"=>{:type=>String, 
                                         :predicate=>:has_part, 
                                          :inbound=>true, 
                                          :singular=>nil}}, 
           :self=>{"testing"=>{:type=>String, 
                               :predicate=>:has_part, 
                               :inbound=>false, 
                               :singular=>nil},
                   "testing2"=>{:type=>String, 
                                :predicate=>:has_member, 
                                :inbound=>false, 
                                :singular=>nil}}}
        end
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
      
      it "resulting finder should search against solr and use Model#find to build an array of objects" do
        @sample_solr_hits = [{"id"=>"_PID1_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                              {"id"=>"_PID2_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]},
                              {"id"=>"_PID3_", "has_model_s"=>["info:fedora/afmodel:AudioRecord"]}]
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new()
        local_node.expects(:pid).returns("test:sample_pid")
        SpecNode.expects(:relationships_desc).returns({:inbound=>{"parts"=>{:predicate=>:is_part_of}}}).at_least_once()
        ActiveFedora::SolrService.expects(:query).with(@part_of_sample, :rows=>25).returns(@sample_solr_hits)
        local_node.parts_ids.should == ["_PID1_", "_PID2_", "_PID3_"]
      end
      
      it "resulting finder should accept :solr as :response_format value and return the raw Solr Result" do
        solr_result = mock("solr result")
        SpecNode.create_inbound_relationship_finders("constituents", :is_constituent_of, :inbound => true)
        local_node = SpecNode.new
        mock_repo = mock("repo")
        mock_repo.expects(:find).never
        local_node.expects(:pid).returns("test:sample_pid")
        SpecNode.expects(:relationships_desc).returns({:inbound=>{"constituents"=>{:predicate=>:is_constituent_of}}}).at_least_once()
        instance = stub(:conn=>stub(:conn))
        ActiveFedora::SolrService.expects(:query).with(@constituent_of_sample, :raw=>true, :rows=>101).returns(solr_result)
        local_node.constituents(:response_format => :solr, :rows=>101).should == solr_result
      end
      
      
      it "resulting _ids finder should search against solr and return an array of fedora PIDs" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        local_node.expects(:pid).returns("test:sample_pid")
        SpecNode.expects(:relationships_desc).returns({:inbound=>{"parts"=>{:predicate=>:is_part_of}}}).at_least_once() 
        ActiveFedora::SolrService.expects(:query).with(@part_of_sample, :rows=>25).returns([Hash["id"=>"pid1"], Hash["id"=>"pid2"]])
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
        it "should read from relationships array and use Repository.find to build an array of objects" do
          SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
          local_node = SpecNode.new
          local_node.expects(:ids_for_outbound).with(:is_member_of).returns(["my:_PID1_", "my:_PID2_", "my:_PID3_"])

          #ActiveFedora::ContentModel.expects(:known_models_for).returns([SpecNode]).times(3)
          ActiveFedora::SolrService.expects(:query).with("id:my\\:_PID1_ OR id:my\\:_PID2_ OR id:my\\:_PID3_").returns([{"id"=> "my:_PID1_", "has_model_s"=>["info:fedora/afmodel:SpecNode"]},
                         {"id"=> "my:_PID2_", "has_model_s"=>["info:fedora/afmodel:SpecNode"]}, 
                         {"id"=> "my:_PID3_", "has_model_s"=>["info:fedora/afmodel:SpecNode"]}])
          ActiveFedora::DigitalObject.expects(:find).with(SpecNode, 'my:_PID1_').returns(stub("inner obj", :'new?'=>false, :pid=>'my:_PID1_'))
          ActiveFedora::DigitalObject.expects(:find).with(SpecNode, 'my:_PID2_').returns(stub("inner obj", :'new?'=>false, :pid=>'my:_PID2_'))
          ActiveFedora::DigitalObject.expects(:find).with(SpecNode, 'my:_PID3_').returns(stub("inner obj", :'new?'=>false, :pid=>'my:_PID3_'))
          local_node.containers.map(&:pid).should == ["my:_PID1_", "my:_PID2_", "my:_PID3_"]
        end
      
        it "should accept :solr as :response_format value and return the raw Solr Result" do
          solr_result = mock("solr result")
          SpecNode.create_outbound_relationship_finders("constituents", :is_constituent_of)
          local_node = SpecNode.new
          mock_repo = mock("repo")
          mock_repo.expects(:find).never
          local_node.expects(:rels_ext).returns(stub('rels-ext', :content=>''))
          ActiveFedora::SolrService.expects(:query).returns(solr_result)
          local_node.constituents(:response_format => :solr).should == solr_result
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
          local_node.expects(:rels_ext).returns(stub("rels_ext", :content_will_change! => true, :content=>'')).at_least_once
          local_node.add_relationship(:is_member_of, "demo:10")
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
        @pid = "test:sample_pid"
        @local_node.pid = @pid
        #@local_node.internal_uri = @uri
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
        ActiveFedora::SolrService.expects(:query).with("#{id_array_query} OR (#{@part_of_sample})", :rows=>25).returns(solr_result)
        @local_node.all_parts(:response_format=>:solr)
      end

      it "should register both inbound and outbound predicate components" do
        @local_node.class.relationships[:inbound].has_key?(:is_part_of).should == true
        @local_node.class.relationships[:self].has_key?(:has_part).should == true
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
        model_def = SpecNode.to_class_uri
        @local_node.expects(:rels_ext).returns(stub("rels_ext", :content_will_change! => true, :content=>'')).at_least_once
        @local_node.add_relationship(:has_model, model_def)
        @local_node2.expects(:rels_ext).returns(stub("rels_ext", :content_will_change! => true, :content=>'')).at_least_once
        @local_node2.add_relationship(:has_model, model_def)
        @local_node.add_relationship(:has_part, @local_node2)
        @local_node2.add_relationship(:has_part, @local_node)
        @local_node.ids_for_outbound(:has_part).should == [@local_node2.pid]
        @local_node.ids_for_outbound(:has_model).should == ['afmodel:SpecNode']
        @local_node2.ids_for_outbound(:has_part).should == [@local_node.pid]
        @local_node2.ids_for_outbound(:has_model).should == ['afmodel:SpecNode']
        @local_node.relationships_by_name(false).should == {:self=>{"all_parts_outbound"=>[@local_node2.internal_uri]},:inbound=>{"all_parts_inbound"=>[]}}
        @local_node2.relationships_by_name(false).should == {:self=>{"all_parts_outbound"=>[@local_node.internal_uri]},:inbound=>{"all_parts_inbound"=>[]}}
      end
    end

  
  it 'should provide #inbound_relationship_names' do
    SpecNode.new.should respond_to(:inbound_relationship_names)
  end
  
  describe '#inbound_relationship_names' do
    before do
      class MockRelationshipNames < SpecNode
        include ActiveFedora::Relationships
        register_relationship_desc(:self, "testing", :has_part, :type=>SpecNode)
        create_relationship_name_methods("testing")
        register_relationship_desc(:self, "testing2", :has_member, :type=>SpecNode)
        create_relationship_name_methods("testing2")
        register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNode)
        register_relationship_desc(:inbound, "testing_inbound2", :has_member, :type=>SpecNode)
      end
    end
    it 'should return an array of inbound relationship names for this model' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      @test_object2.inbound_relationship_names.include?("testing_inbound").should == true
      @test_object2.inbound_relationship_names.include?("testing_inbound2").should == true
      @test_object2.inbound_relationship_names.size.should == 2
    end
  end
  
  it 'should provide #outbound_relationship_names' do
    SpecNode.new.should respond_to(:outbound_relationship_names)
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
  
  it 'should provide #inbound_relationships_by_name' do
    #testing execution of this in integration since touches solr
    SpecNode.new.should respond_to(:inbound_relationships_by_name)
  end
  
  it 'should provide #find_relationship_by_name' do
    SpecNode.new.should respond_to(:find_relationship_by_name)
  end
  
  describe '#find_relationship_by_name' do
    it 'should return an array of object uri for a given relationship name' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      @test_object3 = SpecNode.new 
      @test_object3.pid = increment_pid
      @test_object4 = SpecNode.new 
      @test_object4.pid = increment_pid
      #add relationships that mirror 'testing' and 'testing2'
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(MockRelationshipNames.to_class_uri))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_member),  RDF::URI.new(@test_object4.internal_uri))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new(@test_object3.internal_uri))
      @test_object2.expects(:relationships).returns(graph).at_least_once
     @test_object2.find_relationship_by_name("testing").should == [@test_object3.internal_uri] 
    end
  end

  describe "relationship_query" do
    before do
      class MockNamedRelationshipQuery < SpecNode
        register_relationship_desc(:inbound, "testing_inbound_query", :is_part_of, :type=>SpecNode, :solr_fq=>"has_model_s:info\\:fedora/SpecialPart")
        register_relationship_desc(:inbound, "testing_inbound_no_solr_fq", :is_part_of, :type=>SpecNode)
        register_relationship_desc(:self, "testing_outbound_query", :is_part_of, :type=>SpecNode, :solr_fq=>"has_model_s:info\\:fedora/SpecialPart")
        register_relationship_desc(:self, "testing_outbound_no_solr_fq", :is_part_of, :type=>SpecNode)
        #for bidirectional relationship testing need to register both outbound and inbound names
        register_relationship_desc(:self, "testing_bi_query_outbound", :has_part, :type=>SpecNode, :solr_fq=>"has_model_s:info\\:fedora/SpecialPart")
        register_relationship_desc(:inbound, "testing_bi_query_inbound", :is_part_of, :type=>SpecNode, :solr_fq=>"has_model_s:info\\:fedora/SpecialPart")
        register_relationship_desc(:self, "testing_bi_no_solr_fq_outbound", :has_part, :type=>SpecNode)
        register_relationship_desc(:inbound, "testing_bi_no_solr_fq_inbound", :is_part_of, :type=>SpecNode)
      end
    end
    after do
      Object.send(:remove_const, :MockNamedRelationshipQuery)
    end
    
    before(:each) do
      @mockrelsquery = MockNamedRelationshipQuery.new
    end
    
    it "should call bidirectional_relationship_query if a bidirectional relationship" do
      ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
      @mockrelsquery.expects(:ids_for_outbound).with(:has_part).returns(ids).at_least_once
      @mockrelsquery.expects(:pid).returns("changeme:5")
      MockNamedRelationshipQuery.expects(:bidirectional_relationship_query).with("changeme:5","testing_bi_query",ids)
      @mockrelsquery.relationship_query("testing_bi_query")
    end
    
    it "should call outbound_relationship_query if an outbound relationship" do
      ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
      @mockrelsquery.expects(:ids_for_outbound).with(:is_part_of).returns(ids).at_least_once
      MockNamedRelationshipQuery.expects(:outbound_relationship_query).with("testing_outbound_no_solr_fq",ids)
      @mockrelsquery.relationship_query("testing_outbound_no_solr_fq")
    end
    
    it "should call inbound_relationship_query if an inbound relationship" do
      @mockrelsquery.expects(:pid).returns("changeme:5")
      MockNamedRelationshipQuery.expects(:inbound_relationship_query).with("changeme:5","testing_inbound_query")
      @mockrelsquery.relationship_query("testing_inbound_query")
    end
  end

  describe '#relationship_predicates' do
    before do
      class MockNamedRelationshipPredicates < SpecNode
        register_relationship_desc(:self, "testing", :has_part, :type=>SpecNode)
        create_relationship_name_methods("testing")
        register_relationship_desc(:self, "testing2", :has_member, :type=>SpecNode)
        create_relationship_name_methods("testing2")
        register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNode)
      end
    end
    after do
      Object.send(:remove_const, :MockNamedRelationshipPredicates)
    end

    it 'should provide #relationship_predicates' do
      SpecNode.new.should respond_to(:relationship_predicates)
    end
    
    it 'should return a map of subject to relationship name to fedora ontology relationship predicate' do
      @test_object2 = MockNamedRelationshipPredicates.new
      @test_object2.relationship_predicates.should == {:self=>{"testing"=>:has_part,"testing2"=>:has_member},
                                                            :inbound=>{"testing_inbound"=>:has_part}}
      
    end 
  end
  
  describe '#conforms_to?' do
    before do
      @test_object = SpecNode.new
    end
    it 'should provide #conforms_to?' do
      @test_object.should respond_to(:conforms_to?)
    end
    
    it 'should check if current object is the kind of model class supplied' do
      #has_model relationship does not get created until save called
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(SpecNode.to_class_uri))
      @test_object.expects(:relationships).returns(graph).at_least_once
      @test_object.conforms_to?(SpecNode).should == true
    end
  end
  
  describe '#assert_conforms_to' do
    before do
      @test_object = SpecNode.new
    end
    it 'should provide #assert_conforms_to' do
      @test_object.should respond_to(:assert_conforms_to)
    end

    it 'should correctly assert if an object is the type of model supplied' do
      @test_object3 = SpecNode.new
      @test_object3.pid = increment_pid
      #has_model relationship does not get created until save called so need to add the has model rel here, is fine since not testing save
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(SpecNode.to_class_uri))
      @test_object.expects(:relationships).returns(graph).at_least_once
      @test_object3.assert_conforms_to('object',@test_object,SpecNode)
    end
  end
  
  it 'should provide #class_from_name' do
    SpecNode.new.should respond_to(:class_from_name)
  end
  
  describe '#class_from_name' do
    it 'should return a class constant for a string passed in' do
      SpecNode.new.class_from_name("SpecNode").should == SpecNode
    end
  end

  describe '#relationships_by_name' do
    
    before do
      class MockNamedRelationships3 < SpecNode
        register_relationship_desc(:self, "testing", :has_part, :type=>SpecNode)
        create_relationship_name_methods("testing")
        register_relationship_desc(:self, "testing2", :has_member, :type=>SpecNode)
        create_relationship_name_methods("testing2")
        register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNode)
      end
    end
    after do
      Object.send(:remove_const, :MockNamedRelationships3)
    end

    it 'should provide #relationships_by_name' do
      @test_object = SpecNode.new
      @test_object.should respond_to(:relationships_by_name)
    end
    
    it 'should return current named relationships' do
      @test_object = SpecNode.new
      @test_object.pid = increment_pid
      @test_object2 = MockNamedRelationships3.new
      @test_object2.pid = increment_pid
      @test_object3 = MockNamedRelationships3.new
      @test_object3.pid = increment_pid
      model_pid = MockNamedRelationships3.to_class_uri
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(model_pid))
      @test_object2.expects(:relationships).returns(graph).at_least_once
      #should return expected named relationships
      @test_object2.relationships_by_name.should == {:self=>{"testing"=>[],"testing2"=>[]}}
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(model_pid))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new(@test_object.internal_uri))
      @test_object3.expects(:relationships).returns(graph).at_least_once
      @test_object3.relationships_by_name.should == {:self=>{"testing"=>[@test_object.internal_uri],"testing2"=>[]}}
    end 
  end
  describe '#relationship_has_solr_filter_query' do
    before do
      class RelsHasSolrFilter < SpecNode
        register_relationship_desc :self, "testing", :is_part_of, :solr_fq=>"testing:value"
        register_relationship_desc :self, "no_query_testing", :is_part_of
        register_relationship_desc :inbound, "inbound_testing", :has_part, :solr_fq=>"in_testing:value_in"
        register_relationship_desc :inbound, "inbound_testing_no_query", :has_part
      end
      @test_object = RelsHasSolrFilter.new
    end
    after do
      Object.send(:remove_const, :RelsHasSolrFilter)
    end

    it 'should return true if an object has an inbound relationship with solr filter query' do
      @test_object.relationship_has_solr_filter_query?(:inbound,"inbound_testing").should == true
    end

    it 'should return false if an object does not have inbound relationship with solr filter query' do
      @test_object.relationship_has_solr_filter_query?(:inbound,"inbound_testing_no_query").should == false
    end

    it 'should return true if an object has an outbound relationship with solr filter query' do
      @test_object.relationship_has_solr_filter_query?(:self,"testing").should == true
    end

    it 'should return false if an object does not have outbound relationship with solr filter query' do
      @test_object.relationship_has_solr_filter_query?(:self,"testing_no_query").should == false
    end
  end

  describe ActiveFedora::Relationships::ClassMethods do

     after(:each) do
      begin
        @test_object2.delete
      rescue
      end
    end

    describe '#relationships_desc' do
      it 'should initialize relationships_desc to a new hash containing self' do
        @test_object2 = SpecNode.new
        @test_object2.pid = increment_pid
        @test_object2.relationships_desc.should == {:self=>{}}
      end
    end
      
    describe '#register_relationship_desc_subject' do
    
      before do
        class MockRegisterNamedSubject < SpecNode
          register_relationship_desc_subject :test
        end
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedSubject.new
        @test_object2.pid = increment_pid
        @test_object2.relationships_desc.should == {:self=>{}, :test=>{}}
      end 
    end
  
    describe '#register_relationship_desc' do
    
      before do
        class MockRegisterNamedRelationship < SpecNode
          register_relationship_desc :self, "testing", :is_part_of, :type=>SpecNode
          register_relationship_desc :inbound, "testing2", :has_part, :type=>SpecNode
        end
      end
    
      it 'should add a new named subject to the named relationships only if it does not already exist' do
        @test_object2 = MockRegisterNamedRelationship.new 
        @test_object2.pid = increment_pid
        @test_object2.relationships_desc.should == {:inbound=>{"testing2"=>{:type=>SpecNode, :predicate=>:has_part}}, :self=>{"testing"=>{:type=>SpecNode, :predicate=>:is_part_of}}}
      end 
    end

    describe "#is_bidirectional_relationship?" do
      
      before do
        class MockIsBiRegisterNamedRelationship < SpecNode
          register_relationship_desc(:self, "testing_outbound", :is_part_of, :type=>SpecNode)
          register_relationship_desc(:inbound, "testing_inbound", :has_part, :type=>SpecNode)
          register_relationship_desc(:self, "testing2", :is_member_of,{})
        end
      end

      it "should return true if both inbound and outbound predicates exist, otherwise false" do
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing").should == true
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing2").should == false
        #the inbound and outbound internal relationships will not be bidirectional by themselves
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_inbound").should == false
        MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_outbound").should == false
      end
    end


    describe '#create_relationship_name_methods' do
      before do
        class MockCreateNamedRelationshipMethods < SpecNode
          register_relationship_desc :self, "testing", :is_part_of, :type=>SpecNode
          create_relationship_name_methods "testing"
        end
      end
      after do
        Object.send(:remove_const, :MockCreateNamedRelationshipMethods)
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
      before do
        class MockCreateNamedRelationshipMethods < SpecNode
          register_relationship_desc(:self, "testing_outbound", :is_part_of, :type=>SpecNode)
          create_bidirectional_relationship_name_methods "testing", "testing_outbound"
        end
      end
      after do
        Object.send(:remove_const, :MockCreateNamedRelationshipMethods)
      end
      
      it 'should create an append and remove method for each outbound relationship' do
        @test_object2 = MockCreateNamedRelationshipMethods.new
        @test_object2.pid = increment_pid 
        @test_object2.should respond_to(:testing_append)
        @test_object2.should respond_to(:testing_remove)
        #test execution in base_spec since method definitions include methods in ActiveFedora::Base
      end
    end
    

     #
    # HYDRA-541
    #
      
    describe "bidirectional_relationship_query" do
      before do
        class MockBiNamedRelationshipQuery < SpecNode
          register_relationship_desc(:self, "testing_query_outbound", :has_part, :type=>SpecNode, :solr_fq=>"has_model_s:info\\:fedora\\/SpecialPart")
          register_relationship_desc(:inbound, "testing_query_inbound", :is_part_of, :type=>SpecNode, :solr_fq=>"has_model_s:info\\:fedora\\/SpecialPart")
          create_bidirectional_relationship_name_methods("testing","testing_outbound")
          register_relationship_desc(:self, "testing_no_solr_fq_outbound", :has_part, :type=>SpecNode)
          register_relationship_desc(:inbound, "testing_no_solr_fq_inbound", :is_part_of, :type=>SpecNode)
          create_bidirectional_relationship_name_methods("testing_no_solr_fq","testing_no_solr_fq_outbound")
        end
      end
      after do
        Object.send(:remove_const, :MockBiNamedRelationshipQuery)
      end

      #
      # HYDRA-541
      #
      it "should rely on outbound query if inbound query is empty" do
        query = MockBiNamedRelationshipQuery.bidirectional_relationship_query("PID",:testing_query,[])
        query.should_not include("OR ()")
        query2 = MockBiNamedRelationshipQuery.bidirectional_relationship_query("PID",:testing_no_solr_fq,[])
        query2.should_not include("OR ()")
      end

      it "should return a properly formatted query for a relationship that has a solr filter query defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4","changeme:5"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND #{@is_part_query})"
        end
        expected_string << " OR "
        expected_string << "(is_part_of_s:info\\:fedora\\/changeme\\:6 AND #{@is_part_query})"
        MockBiNamedRelationshipQuery.bidirectional_relationship_query("changeme:6","testing_query",ids).should == expected_string
      end

      it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4","changeme:5"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "id:" + id.gsub(/(:)/, '\\:')
        end
        expected_string << " OR "
        expected_string << "(is_part_of_s:info\\:fedora\\/changeme\\:6)"
        MockBiNamedRelationshipQuery.bidirectional_relationship_query("changeme:6","testing_no_solr_fq",ids).should == expected_string
      end
    end

    describe "inbound_relationship_query" do
      before do
        class MockInboundNamedRelationshipQuery < SpecNode
          register_relationship_desc(:inbound, "testing_inbound_query", :is_part_of, :type=>SpecNode, :solr_fq=>"has_model_s:#{solr_uri("info:fedora/SpecialPart")}")
          register_relationship_desc(:inbound, "testing_inbound_no_solr_fq", :is_part_of, :type=>SpecNode)
        end
      end
      after(:each) do
        Object.send(:remove_const, :MockInboundNamedRelationshipQuery)
      end

      it "should return a properly formatted query for a relationship that has a solr filter query defined" do
        MockInboundNamedRelationshipQuery.inbound_relationship_query("changeme:1","testing_inbound_query").should == "is_part_of_s:info\\:fedora\\/changeme\\:1 AND #{@is_part_query}"
      end
      
      it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
        MockInboundNamedRelationshipQuery.inbound_relationship_query("changeme:1","testing_inbound_no_solr_fq").should == "is_part_of_s:info\\:fedora\\/changeme\\:1"
      end
    end




    describe "outbound_relationship_query" do
      before do
        class MockOutboundNamedRelationshipQuery < SpecNode
          register_relationship_desc(:self, "testing_query", :is_part_of, :type=>SpecNode, :solr_fq=>"has_model_s:#{solr_uri("info:fedora/SpecialPart")}")
          register_relationship_desc(:self,"testing_no_solr_fq", :is_part_of, :type=>SpecNode)
        end
      end
      after(:each) do
        Object.send(:remove_const, :MockOutboundNamedRelationshipQuery)
      end

      it "should return a properly formatted query for a relationship that has a solr filter query defined" do
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
        expected_string = ""
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND has_model_s:#{solr_uri("info:fedora/SpecialPart")})"
        end
        MockOutboundNamedRelationshipQuery.outbound_relationship_query("testing_query",ids).should == expected_string
      end

      it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "id:" + id.gsub(/(:)/, '\\:')
        end
        MockOutboundNamedRelationshipQuery.outbound_relationship_query("testing_no_solr_fq",ids).should == expected_string
      end
    end 
  end
end
