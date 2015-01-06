require 'spec_helper'

@@last_pid = 0

describe ActiveFedora::Relationships do
    before(:all) do
      @behavior = ActiveFedora::Relationships.deprecation_behavior
      @c_behavior = ActiveFedora::Relationships::ClassMethods.deprecation_behavior
      ActiveFedora::Relationships.deprecation_behavior = :silence
      ActiveFedora::Relationships::ClassMethods.deprecation_behavior = :silence
    end

    after :all do
      ActiveFedora::Relationships.deprecation_behavior = @behavior
      ActiveFedora::Relationships::ClassMethods.deprecation_behavior = @c_behavior
    end

    def increment_pid
      @@last_pid += 1
    end

    before(:all) do
      @part_of_sample = ActiveFedora::SolrService.solr_name("is_part_of", :symbol) + ":#{solr_uri("info:fedora/test:sample_pid")}"
      @constituent_of_sample = ActiveFedora::SolrService.solr_name("is_constituent_of", :symbol) + ":#{solr_uri("info:fedora/test:sample_pid")}"
      @is_part_query = ActiveFedora::SolrService.solr_name("has_model", :symbol) + ":#{solr_uri("info:fedora/SpecialPart")}"
    end

    before(:each) do
      class SpecNode
        include ActiveFedora::Relationships
        include ActiveFedora::SemanticNode
        include ActiveFedora::Model
        extend ActiveFedora::Querying

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
      expect(SpecNode).to  respond_to(:has_relationship)
      expect(SpecNode).to  respond_to(:has_relationship)
    end
    describe '#relationships' do

      it "should return a hash" do
        expect(SpecNode.relationships.class).to eq(Hash)
      end

    end

    describe '#has_relationship' do
      it "should create finders based on provided relationship name" do
        SpecNode.has_relationship("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        expect(local_node).to respond_to(:parts_ids)
        expect(local_node).to respond_to(:parts_query)
        # local_node.should respond_to(:parts)
        expect(local_node).not_to respond_to(:containers)
        SpecNode.has_relationship("containers", :is_member_of)
        expect(local_node).to respond_to(:containers_ids)
        expect(local_node).to respond_to(:containers_query)
      end

      it "should add a subject and predicate to the relationships array" do
        SpecNode.has_relationship("parents", :is_part_of)
        expect(SpecNode.relationships).to have_key(:self)
        expect(SpecNode.relationships[:self]).to have_key(:is_part_of)
      end

      it "should use :inbound as the subject if :inbound => true" do
        SpecNode.has_relationship("parents", :is_part_of, :inbound => true)
        expect(SpecNode.relationships).to have_key(:inbound)
        expect(SpecNode.relationships[:inbound]).to have_key(:is_part_of)
      end

      it 'should create inbound relationship finders' do
        expect(SpecNode).to receive(:create_inbound_relationship_finders)
        SpecNode.has_relationship("parts", :is_part_of, :inbound => true)
      end

      it 'should create outbound relationship finders' do
        expect(SpecNode).to receive(:create_outbound_relationship_finders).exactly(2).times
        SpecNode.has_relationship("parts", :is_part_of, :inbound => false)
        SpecNode.has_relationship("container", :is_member_of)
      end

      it "should create outbound relationship finders that return an array of fedora PIDs" do
        SpecNode.has_relationship("containers", :is_member_of, :inbound => false)
        local_node = SpecNode.new
        #local_node.internal_uri = "info:fedora/#{@pid}"
        local_node.pid = @pid

        allow(local_node).to receive(:rels_ext).and_return(double("rels_ext", :content_will_change! => true, :content=>''))
        local_node.add_relationship(:is_member_of, "info:fedora/container:A")
        local_node.add_relationship(:is_member_of, "info:fedora/container:B")

        containers_result = local_node.containers_ids
        expect(containers_result).to be_instance_of(Array)
        expect(containers_result).to include("container:A")
        expect(containers_result).to include("container:B")
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
          allow(@test_object2).to receive(:testing_inbound).and_return({})
          allow(@test_object2).to receive(:rels_ext).and_return(double("rels_ext", :content_will_change! => true, :content =>''))
          @test_object2.add_relationship(:has_model, SpecNode.to_class_uri)
          expect(@test_object2).to respond_to(:testing_append)
          expect(@test_object2).to respond_to(:testing_remove)
          expect(@test_object2).to respond_to(:testing2_append)
          expect(@test_object2).to respond_to(:testing2_remove)
          #make sure append/remove method not created for inbound rel
          expect(@test_object2).not_to respond_to(:testing_inbound_append)
          expect(@test_object2).not_to respond_to(:testing_inbound_remove)

          expect(@test_object2.class.relationships_desc).to eq(
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
          )
        end
      end
    end

    describe '#create_inbound_relationship_finders' do

      it 'should respond to #create_inbound_relationship_finders' do
        expect(SpecNode).to respond_to(:create_inbound_relationship_finders)
      end

      it "should create finders based on provided relationship name" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        expect(local_node).to respond_to(:parts_ids)
        expect(local_node).not_to respond_to(:containers)
        SpecNode.create_inbound_relationship_finders("containers", :is_member_of, :inbound => true)
        expect(local_node).to respond_to(:containers_ids)
        expect(local_node).to respond_to(:containers)
        expect(local_node).to respond_to(:containers_from_solr)
        expect(local_node).to respond_to(:containers_query)
      end

      it "resulting finder should search against solr and use Model#find to build an array of objects" do
        @sample_solr_hits = [{"id"=>"_PID1_", ActiveFedora::SolrService.solr_name('has_model', :symbol)=>["info:fedora/afmodel:AudioRecord"]},
                              {"id"=>"_PID2_", ActiveFedora::SolrService.solr_name('has_model', :symbol)=>["info:fedora/afmodel:AudioRecord"]},
                              {"id"=>"_PID3_", ActiveFedora::SolrService.solr_name('has_model', :symbol)=>["info:fedora/afmodel:AudioRecord"]}]
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new()
        expect(local_node).to receive(:pid).and_return("test:sample_pid")
        allow(SpecNode).to receive(:relationships_desc).and_return({:inbound=>{"parts"=>{:predicate=>:is_part_of}}})
        expect(ActiveFedora::SolrService).to receive(:query).with(@part_of_sample, :rows=>25).and_return(@sample_solr_hits)
        expect(local_node.parts_ids).to eq(["_PID1_", "_PID2_", "_PID3_"])
      end

      it "resulting finder should accept :solr as :response_format value and return the raw Solr Result" do
        solr_result = double("solr result")
        SpecNode.create_inbound_relationship_finders("constituents", :is_constituent_of, :inbound => true)
        local_node = SpecNode.new
        mock_repo = double("repo")
        expect(mock_repo).to receive(:find).never
        expect(local_node).to receive(:pid).and_return("test:sample_pid")
        allow(SpecNode).to receive(:relationships_desc).and_return({:inbound=>{"constituents"=>{:predicate=>:is_constituent_of}}})
        instance = double(:conn=>double(:conn))
        expect(ActiveFedora::SolrService).to receive(:query).with(@constituent_of_sample, :raw=>true, :rows=>101).and_return(solr_result)
        expect(local_node.constituents(:response_format => :solr, :rows=>101)).to eq(solr_result)
      end


      it "resulting _ids finder should search against solr and return an array of fedora PIDs" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        expect(local_node).to receive(:pid).and_return("test:sample_pid")
        allow(SpecNode).to receive(:relationships_desc).and_return({:inbound=>{"parts"=>{:predicate=>:is_part_of}}})
        expect(ActiveFedora::SolrService).to receive(:query).with(@part_of_sample, :rows=>25).and_return([Hash["id"=>"pid1"], Hash["id"=>"pid2"]])
        expect(local_node.parts(:response_format => :id_array)).to eq(["pid1", "pid2"])
      end

      it "resulting _ids finder should call the basic finder with :result_format => :id_array" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        expect(local_node).to receive(:parts).with(:response_format => :id_array)
        local_node.parts_ids
      end

      it "resulting _query finder should call relationship_query" do
        SpecNode.create_inbound_relationship_finders("parts", :is_part_of, :inbound => true)
        local_node = SpecNode.new
        expect(local_node).to receive(:relationship_query).with("parts")
        local_node.parts_query
      end
    end

    describe '#create_outbound_relationship_finders' do

      it 'should respond to #create_outbound_relationship_finders' do
        expect(SpecNode).to respond_to(:create_outbound_relationship_finders)
      end

      it "should create finders based on provided relationship name" do
        SpecNode.create_outbound_relationship_finders("parts", :is_part_of)
        local_node = SpecNode.new
        expect(local_node).to respond_to(:parts_ids)
        #local_node.should respond_to(:parts)  #.with(:type => "AudioRecord")
        expect(local_node).not_to respond_to(:containers)
        SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
        expect(local_node).to respond_to(:containers_ids)
        expect(local_node).to respond_to(:containers)
        expect(local_node).to respond_to(:containers_from_solr)
        expect(local_node).to respond_to(:containers_query)
      end

      describe " resulting finder" do
        it "should read from relationships array and use Repository.find to build an array of objects" do
          SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
          local_node = SpecNode.new
          expect(local_node).to receive(:ids_for_outbound).with(:is_member_of).and_return(["my:_PID1_", "my:_PID2_", "my:_PID3_"])

          #ActiveFedora::ContentModel.should_receive(:known_models_for).and_return([SpecNode]).times(3)
          expect(ActiveFedora::SolrService).to receive(:query).with("id:my\\:_PID1_ OR id:my\\:_PID2_ OR id:my\\:_PID3_").and_return([{"id"=> "my:_PID1_", ActiveFedora::SolrService.solr_name('has_model', :symbol)=>["info:fedora/afmodel:SpecNode"]},
                         {"id"=> "my:_PID2_", ActiveFedora::SolrService.solr_name('has_model', :symbol)=>["info:fedora/afmodel:SpecNode"]},
                         {"id"=> "my:_PID3_", ActiveFedora::SolrService.solr_name('has_model', :symbol)=>["info:fedora/afmodel:SpecNode"]}])
          expect(ActiveFedora::DigitalObject).to receive(:find).with(SpecNode, 'my:_PID1_').and_return(double("inner obj", :'new?'=>false, :pid=>'my:_PID1_'))
          expect(ActiveFedora::DigitalObject).to receive(:find).with(SpecNode, 'my:_PID2_').and_return(double("inner obj", :'new?'=>false, :pid=>'my:_PID2_'))
          expect(ActiveFedora::DigitalObject).to receive(:find).with(SpecNode, 'my:_PID3_').and_return(double("inner obj", :'new?'=>false, :pid=>'my:_PID3_'))
          expect(local_node.containers.map(&:pid)).to eq(["my:_PID1_", "my:_PID2_", "my:_PID3_"])
        end

        it "should accept :solr as :response_format value and return the raw Solr Result" do
          solr_result = double("solr result")
          SpecNode.create_outbound_relationship_finders("constituents", :is_constituent_of)
          local_node = SpecNode.new
          mock_repo = double("repo")
          expect(mock_repo).to receive(:find).never
          expect(local_node).to receive(:rels_ext).and_return(double('rels-ext', :content=>''))
          expect(ActiveFedora::SolrService).to receive(:query).and_return(solr_result)
          expect(local_node.constituents(:response_format => :solr)).to eq(solr_result)
        end

        it "(:response_format => :id_array) should read from relationships array" do
          SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
          local_node = SpecNode.new
          expect(local_node).to receive(:ids_for_outbound).with(:is_member_of).and_return([])
          local_node.containers_ids
        end

        it "(:response_format => :id_array) should return an array of fedora PIDs" do
          SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
          local_node = SpecNode.new
          local_node.stub(:rels_ext => double("rels_ext", :content_will_change! => true, :content=>''))
          local_node.add_relationship(:is_member_of, "demo:10")
          result = local_node.containers_ids
          expect(result).to be_instance_of(Array)
          expect(result).to include("demo:10")
        end

      end

      describe " resulting _ids finder" do
        it "should call the basic finder with :result_format => :id_array" do
          SpecNode.create_outbound_relationship_finders("parts", :is_part_of)
          local_node = SpecNode.new
          expect(local_node).to receive(:parts).with(:response_format => :id_array)
          local_node.parts_ids
        end
      end

      it "resulting _query finder should call relationship_query" do
        SpecNode.create_outbound_relationship_finders("containers", :is_member_of)
        local_node = SpecNode.new
        expect(local_node).to receive(:relationship_query).with("containers")
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
        expect(@local_node).to respond_to(:all_parts_inbound)
        expect(@local_node).to respond_to(:all_parts_outbound)
      end
      it "should rely on inbound & outbound finders" do
        expect(@local_node).to receive(:all_parts_inbound).with(:rows => 25).and_return(["foo1"])
        expect(@local_node).to receive(:all_parts_outbound).with(:rows => 25).and_return(["foo2"])
        expect(@local_node.all_parts).to eq(["foo1", "foo2"])
      end
      it "(:response_format => :id_array) should rely on inbound & outbound finders" do
        expect(@local_node).to receive(:all_parts_inbound).with(:response_format=>:id_array, :rows => 34).and_return(["fooA"])
        expect(@local_node).to receive(:all_parts_outbound).with(:response_format=>:id_array, :rows => 34).and_return(["fooB"])
        expect(@local_node.all_parts(:response_format=>:id_array, :rows => 34)).to eq(["fooA", "fooB"])
      end
      it "(:response_format => :solr) should construct a solr query that combines inbound and outbound searches" do
        # get the id array for outbound relationships then construct solr query by combining id array with inbound relationship search
        expect(@local_node).to receive(:ids_for_outbound).with(:has_part).and_return(["mypid:1"])
        id_array_query = ActiveFedora::SolrService.construct_query_for_pids(["mypid:1"])
        solr_result = double("solr result")
        expect(ActiveFedora::SolrService).to receive(:query).with("#{id_array_query} OR (#{@part_of_sample})", :rows=>25).and_return(solr_result)
        @local_node.all_parts(:response_format=>:solr)
      end

      it "should register both inbound and outbound predicate components" do
        expect(@local_node.class.relationships[:inbound].has_key?(:is_part_of)).to eq(true)
        expect(@local_node.class.relationships[:self].has_key?(:has_part)).to eq(true)
      end

      it "should register finder methods for the bidirectional relationship name" do
        expect(@local_node).to respond_to(:all_parts)
        expect(@local_node).to respond_to(:all_parts_ids)
        expect(@local_node).to respond_to(:all_parts_query)
        expect(@local_node).to respond_to(:all_parts_from_solr)
      end

      it "resulting _query finder should call relationship_query" do
        SpecNode.create_bidirectional_relationship_finders("containers", :is_member_of, :has_member)
        local_node = SpecNode.new
        expect(local_node).to receive(:relationship_query).with("containers")
        local_node.containers_query
      end
    end

    describe "#has_bidirectional_relationship" do
      it "should ..." do
        expect(SpecNode).to receive(:create_bidirectional_relationship_finders).with("all_parts", :has_part, :is_part_of, {})
        SpecNode.has_bidirectional_relationship("all_parts", :has_part, :is_part_of)
      end

      it "should have relationships_by_name and relationships hashes contain bidirectionally related objects" do
        SpecNode.has_bidirectional_relationship("all_parts", :has_part, :is_part_of)
        @local_node = SpecNode.new
        @local_node.pid = "mypid1"
        @local_node2 = SpecNode.new
        @local_node2.pid = "mypid2"
        model_def = SpecNode.to_class_uri
        @local_node.stub(:rels_ext => double("rels_ext", :content_will_change! => true, :content=>''))
        @local_node.add_relationship(:has_model, model_def)
        @local_node2.stub(:rels_ext => double("rels_ext", :content_will_change! => true, :content=>''))
        @local_node2.add_relationship(:has_model, model_def)
        @local_node.add_relationship(:has_part, @local_node2)
        @local_node2.add_relationship(:has_part, @local_node)
        expect(@local_node.ids_for_outbound(:has_part)).to eq([@local_node2.pid])
        expect(@local_node.ids_for_outbound(:has_model)).to eq(['afmodel:SpecNode'])
        expect(@local_node2.ids_for_outbound(:has_part)).to eq([@local_node.pid])
        expect(@local_node2.ids_for_outbound(:has_model)).to eq(['afmodel:SpecNode'])
        expect(@local_node.relationships_by_name(false)).to eq({:self=>{"all_parts_outbound"=>[@local_node2.internal_uri]},:inbound=>{"all_parts_inbound"=>[]}})
        expect(@local_node2.relationships_by_name(false)).to eq({:self=>{"all_parts_outbound"=>[@local_node.internal_uri]},:inbound=>{"all_parts_inbound"=>[]}})
      end
    end


  it 'should provide #inbound_relationship_names' do
    expect(SpecNode.new).to respond_to(:inbound_relationship_names)
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
      expect(@test_object2.inbound_relationship_names.include?("testing_inbound")).to eq(true)
      expect(@test_object2.inbound_relationship_names.include?("testing_inbound2")).to eq(true)
      expect(@test_object2.inbound_relationship_names.size).to eq(2)
    end
  end

  it 'should provide #outbound_relationship_names' do
    expect(SpecNode.new).to respond_to(:outbound_relationship_names)
  end

  describe '#outbound_relationship_names' do
    it 'should return an array of outbound relationship names for this model' do
      @test_object2 = MockRelationshipNames.new
      @test_object2.pid = increment_pid
      expect(@test_object2.outbound_relationship_names.include?("testing")).to eq(true)
      expect(@test_object2.outbound_relationship_names.include?("testing2")).to eq(true)
      expect(@test_object2.outbound_relationship_names.size).to eq(2)
    end
  end

  it 'should provide #inbound_relationships_by_name' do
    #testing execution of this in integration since touches solr
    expect(SpecNode.new).to respond_to(:inbound_relationships_by_name)
  end

  it 'should provide #find_relationship_by_name' do
    expect(SpecNode.new).to respond_to(:find_relationship_by_name)
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
      @test_object2.stub(:relationships =>graph)
     expect(@test_object2.find_relationship_by_name("testing")).to eq([@test_object3.internal_uri])
    end
  end

  describe "relationship_query" do
    before do
      class MockNamedRelationshipQuery < SpecNode
        register_relationship_desc(:inbound, "testing_inbound_query", :is_part_of, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:info\\:fedora/SpecialPart")
        register_relationship_desc(:inbound, "testing_inbound_no_solr_fq", :is_part_of, :type=>SpecNode)
        register_relationship_desc(:self, "testing_outbound_query", :is_part_of, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:info\\:fedora/SpecialPart")
        register_relationship_desc(:self, "testing_outbound_no_solr_fq", :is_part_of, :type=>SpecNode)
        #for bidirectional relationship testing need to register both outbound and inbound names
        register_relationship_desc(:self, "testing_bi_query_outbound", :has_part, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:info\\:fedora/SpecialPart")
        register_relationship_desc(:inbound, "testing_bi_query_inbound", :is_part_of, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:info\\:fedora/SpecialPart")
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
      allow(@mockrelsquery).to receive(:ids_for_outbound).with(:has_part).and_return(ids)
      expect(@mockrelsquery).to receive(:pid).and_return("changeme:5")
      expect(MockNamedRelationshipQuery).to receive(:bidirectional_relationship_query).with("changeme:5","testing_bi_query",ids)
      @mockrelsquery.relationship_query("testing_bi_query")
    end

    it "should call outbound_relationship_query if an outbound relationship" do
      ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
      allow(@mockrelsquery).to receive(:ids_for_outbound).with(:is_part_of).and_return(ids)
      expect(MockNamedRelationshipQuery).to receive(:outbound_relationship_query).with("testing_outbound_no_solr_fq",ids)
      @mockrelsquery.relationship_query("testing_outbound_no_solr_fq")
    end

    it "should call inbound_relationship_query if an inbound relationship" do
      expect(@mockrelsquery).to receive(:pid).and_return("changeme:5")
      expect(MockNamedRelationshipQuery).to receive(:inbound_relationship_query).with("changeme:5","testing_inbound_query")
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
      expect(SpecNode.new).to respond_to(:relationship_predicates)
    end

    it 'should return a map of subject to relationship name to fedora ontology relationship predicate' do
      @test_object2 = MockNamedRelationshipPredicates.new
      expect(@test_object2.relationship_predicates).to eq({:self=>{"testing"=>:has_part,"testing2"=>:has_member},
                                                            :inbound=>{"testing_inbound"=>:has_part}})

    end
  end

  describe '#conforms_to?' do
    before do
      @test_object = SpecNode.new
    end
    it 'should provide #conforms_to?' do
      expect(@test_object).to respond_to(:conforms_to?)
    end

    it 'should check if current object is the kind of model class supplied' do
      #has_model relationship does not get created until save called
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(SpecNode.to_class_uri))
      allow(@test_object).to receive(:relationships).and_return(graph)
      expect(@test_object.conforms_to?(SpecNode)).to eq(true)
    end
  end

  describe '#assert_conforms_to' do
    before do
      @test_object = SpecNode.new
    end
    it 'should provide #assert_conforms_to' do
      expect(@test_object).to respond_to(:assert_conforms_to)
    end

    it 'should correctly assert if an object is the type of model supplied' do
      @test_object3 = SpecNode.new
      @test_object3.pid = increment_pid
      #has_model relationship does not get created until save called so need to add the has model rel here, is fine since not testing save
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(SpecNode.to_class_uri))
      allow(@test_object).to receive(:relationships).and_return(graph)
      @test_object3.assert_conforms_to('object',@test_object,SpecNode)
    end
  end

  it 'should provide #class_from_name' do
    expect(SpecNode.new).to respond_to(:class_from_name)
  end

  describe '#class_from_name' do
    it 'should return a class constant for a string passed in' do
      expect(SpecNode.new.class_from_name("SpecNode")).to eq(SpecNode)
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
      expect(@test_object).to respond_to(:relationships_by_name)
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
      allow(@test_object2).to receive(:relationships).and_return(graph)
      #should return expected named relationships
      expect(@test_object2.relationships_by_name).to eq({:self=>{"testing"=>[],"testing2"=>[]}})
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new(model_pid))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new(@test_object.internal_uri))
      allow(@test_object3).to receive(:relationships).and_return(graph)
      expect(@test_object3.relationships_by_name).to eq({:self=>{"testing"=>[@test_object.internal_uri],"testing2"=>[]}})
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
      expect(@test_object.relationship_has_solr_filter_query?(:inbound,"inbound_testing")).to eq(true)
    end

    it 'should return false if an object does not have inbound relationship with solr filter query' do
      expect(@test_object.relationship_has_solr_filter_query?(:inbound,"inbound_testing_no_query")).to eq(false)
    end

    it 'should return true if an object has an outbound relationship with solr filter query' do
      expect(@test_object.relationship_has_solr_filter_query?(:self,"testing")).to eq(true)
    end

    it 'should return false if an object does not have outbound relationship with solr filter query' do
      expect(@test_object.relationship_has_solr_filter_query?(:self,"testing_no_query")).to eq(false)
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
        expect(@test_object2.relationships_desc).to eq({:self=>{}})
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
        expect(@test_object2.relationships_desc).to eq({:self=>{}, :test=>{}})
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
        expect(@test_object2.relationships_desc).to eq({:inbound=>{"testing2"=>{:type=>SpecNode, :predicate=>:has_part}}, :self=>{"testing"=>{:type=>SpecNode, :predicate=>:is_part_of}}})
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
        expect(MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing")).to eq(true)
        expect(MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing2")).to eq(false)
        #the inbound and outbound internal relationships will not be bidirectional by themselves
        expect(MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_inbound")).to eq(false)
        expect(MockIsBiRegisterNamedRelationship.is_bidirectional_relationship?("testing_outbound")).to eq(false)
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
        expect(@test_object2).to respond_to(:testing_append)
        expect(@test_object2).to respond_to(:testing_remove)
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
        expect(@test_object2).to respond_to(:testing_append)
        expect(@test_object2).to respond_to(:testing_remove)
        #test execution in base_spec since method definitions include methods in ActiveFedora::Base
      end
    end


     #
    # HYDRA-541
    #

    describe "bidirectional_relationship_query" do
      before do
        class MockBiNamedRelationshipQuery < SpecNode
          register_relationship_desc(:self, "testing_query_outbound", :has_part, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:info\\:fedora\\/SpecialPart")
          register_relationship_desc(:inbound, "testing_query_inbound", :is_part_of, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:info\\:fedora\\/SpecialPart")
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
        expect(query).not_to include("OR ()")
        query2 = MockBiNamedRelationshipQuery.bidirectional_relationship_query("PID",:testing_no_solr_fq,[])
        expect(query2).not_to include("OR ()")
      end

      it "should return a properly formatted query for a relationship that has a solr filter query defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4","changeme:5"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND #{@is_part_query})"
        end
        expected_string << " OR "
        expected_string << "(#{ActiveFedora::SolrService.solr_name('is_part_of', :symbol)}:info\\:fedora\\/changeme\\:6 AND #{@is_part_query})"
        expect(MockBiNamedRelationshipQuery.bidirectional_relationship_query("changeme:6","testing_query",ids)).to eq(expected_string)
      end

      it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4","changeme:5"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "id:" + id.gsub(/(:)/, '\\:')
        end
        expected_string << " OR "
        expected_string << "(#{ActiveFedora::SolrService.solr_name('is_part_of', :symbol)}:info\\:fedora\\/changeme\\:6)"
        expect(MockBiNamedRelationshipQuery.bidirectional_relationship_query("changeme:6","testing_no_solr_fq",ids)).to eq(expected_string)
      end
    end

    describe "inbound_relationship_query" do
      before do
        class MockInboundNamedRelationshipQuery < SpecNode
          register_relationship_desc(:inbound, "testing_inbound_query", :is_part_of, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:#{solr_uri("info:fedora/SpecialPart")}")
          register_relationship_desc(:inbound, "testing_inbound_no_solr_fq", :is_part_of, :type=>SpecNode)
        end
      end
      after(:each) do
        Object.send(:remove_const, :MockInboundNamedRelationshipQuery)
      end

      it "should return a properly formatted query for a relationship that has a solr filter query defined" do
        expect(MockInboundNamedRelationshipQuery.inbound_relationship_query("changeme:1","testing_inbound_query")).to eq("#{ActiveFedora::SolrService.solr_name('is_part_of', :symbol)}:info\\:fedora\\/changeme\\:1 AND #{@is_part_query}")
      end

      it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
        expect(MockInboundNamedRelationshipQuery.inbound_relationship_query("changeme:1","testing_inbound_no_solr_fq")).to eq("#{ActiveFedora::SolrService.solr_name('is_part_of', :symbol)}:info\\:fedora\\/changeme\\:1")
      end
    end




    describe "outbound_relationship_query" do
      before do
        class MockOutboundNamedRelationshipQuery < SpecNode
          register_relationship_desc(:self, "testing_query", :is_part_of, :type=>SpecNode, :solr_fq=>"#{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:#{solr_uri("info:fedora/SpecialPart")}")
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
          expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND #{ActiveFedora::SolrService.solr_name('has_model', :symbol)}:#{solr_uri("info:fedora/SpecialPart")})"
        end
        expect(MockOutboundNamedRelationshipQuery.outbound_relationship_query("testing_query",ids)).to eq(expected_string)
      end

      it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
        expected_string = ""
        ids = ["changeme:1","changeme:2","changeme:3","changeme:4"]
        ids.each_with_index do |id,index|
          expected_string << " OR " if index > 0
          expected_string << "id:" + id.gsub(/(:)/, '\\:')
        end
        expect(MockOutboundNamedRelationshipQuery.outbound_relationship_query("testing_no_solr_fq",ids)).to eq(expected_string)
      end
    end
  end
end
