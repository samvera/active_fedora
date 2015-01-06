require 'spec_helper'

require 'active_fedora'

describe ActiveFedora::SemanticNode do
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
  before(:all) do
    class SNSpecNode < ActiveFedora::Base
      include ActiveFedora::FileManagement
    end
    @node = SNSpecNode.new
    class SNSpecModel < ActiveFedora::Base
      include ActiveFedora::Relationships
      has_relationship("parts", :is_part_of, :inbound => true)
      has_relationship("containers", :is_member_of)
      has_bidirectional_relationship("bi_containers", :is_member_of, :has_member)
    end
    class SpecNodeSolrFilterQuery < ActiveFedora::Base
      include ActiveFedora::Relationships
      has_relationship("parts", :is_part_of, :inbound => true)
      has_relationship("special_parts", :is_part_of, :inbound => true, :solr_fq=>"#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}:info\\:fedora\\/afmodel\\:SpecialPart")
      has_relationship("containers", :is_member_of)
      has_relationship("special_containers", :is_member_of, :solr_fq=>"#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}:info\\:fedora\\/afmodel\\:SpecialContainer")
      has_bidirectional_relationship("bi_containers", :is_member_of, :has_member)
      has_bidirectional_relationship("bi_special_containers", :is_member_of, :has_member, :solr_fq=>"#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}:info\\:fedora\\/afmodel\\:SpecialContainer")
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

    class SpecialContainer < ActiveFedora::Base; end;
    class SpecialPart < ActiveFedora::Base; end;
    @special_container = ActiveFedora::Base.new()
    @special_container.add_relationship(:has_model, SpecialContainer.to_class_uri)
    @special_container.save

    @special_container3 = ActiveFedora::Base.new()
    @special_container3.add_relationship(:has_model, SpecialContainer.to_class_uri)
    @special_container3.save

    @special_container4 = ActiveFedora::Base.new()
    @special_container4.add_relationship(:has_model, SpecialContainer.to_class_uri)
    @special_container4.save

    #even though adding container3 and 3 special containers, it should only include the special containers when returning via relationship name finder methods
    #also should only return special part similarly
    @test_object_query = SpecNodeSolrFilterQuery.new
    @test_object_query.add_relationship(:is_member_of, @container3)
    @test_object_query.add_relationship(:is_member_of, @special_container)
    @test_object_query.add_relationship(:is_member_of, @special_container3)
    @test_object_query.add_relationship(:is_member_of, @special_container4)
    @test_object_query.save

    @special_container2 = ActiveFedora::Base.new()
    @special_container2.add_relationship(:has_model, SpecialContainer.to_class_uri)
    @special_container2.add_relationship(:has_member, 'info:fedora/'+@test_object_query.pid)
    @special_container2.save

    @part3 = ActiveFedora::Base.new()
    @part3.add_relationship(:is_part_of, @test_object_query)
    @part3.save

    @special_part = ActiveFedora::Base.new()
    @special_part.add_relationship(:has_model, SpecialPart.to_class_uri)
    @special_part.add_relationship(:is_part_of, @test_object_query)
    @special_part.save

    @special_container_query = "#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}:#{solr_uri("info:fedora/afmodel:SpecialContainer")}"
    @special_part_query = "#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}:#{solr_uri("info:fedora/afmodel:SpecialPart")}"
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
      spec_node = SNSpecNode.new
      expect(spec_node.collection_members).to eq([])

      spec_node.add_relationship(:has_collection_member, @test_object.pid)
      collection_members = spec_node.collection_members
      expect(collection_members.length).to eq(1)
      expect(collection_members.first.pid).to eq(@test_object.pid)
      expect(collection_members.first.class).to eq(@test_object.class)
    end
  end

  describe "inbound relationship finders" do
    describe "when inheriting from parents" do
      before do
        class Test1 < ActiveFedora::Base
          include ActiveFedora::FileManagement
        end
        @part4 = Test1.new()
        @part4.parts

        class Test2 < ActiveFedora::Base
          include ActiveFedora::FileManagement
        end
        class Test3 < Test2
          include ActiveFedora::Relationships
          has_relationship "testing", :has_member
        end

        class Test4 < Test3
          include ActiveFedora::Relationships
          has_relationship "testing_inbound", :is_member_of, :inbound=>true
        end

        class Test5 < Test4
          include ActiveFedora::Relationships
          has_relationship "testing_inbound", :is_part_of, :inbound=>true
        end

        @test_object2 = Test2.new
        @test_object2.save
      end
      it "should have relationships defined" do
        expect(Test1.relationships_desc).to have_key(:inbound)
        expect(Test2.relationships_desc).to have_key(:inbound)
        expect(Test2.relationships_desc[:inbound]["parts_inbound"]).to eq({:inbound=>true, :predicate=>:is_part_of, :singular=>nil})
      end

      it "should have relationships defined from more than one ancestor class" do
        expect(Test4.relationships_desc[:self]).to have_key("collection_members")
        expect(Test4.relationships_desc[:self]).to have_key("testing")
        expect(Test4.relationships_desc[:inbound]).to have_key("testing_inbound")
      end

      it "should override a parents relationship description if defined in the child" do
        #check parent description
        expect(Test4.relationships_desc[:inbound]["testing_inbound"][:predicate]).to eq(:is_member_of)
        #check child with overwritten relationship description has different predicate
        expect(Test5.relationships_desc[:inbound]["testing_inbound"][:predicate]).to eq(:is_part_of)
      end

      it "should not have relationships bleeding over from other sibling classes" do
        expect(SpecNodeSolrFilterQuery.relationships_desc[:inbound]).to have_key("bi_special_containers_inbound")
        expect(Test1.relationships_desc[:inbound]).not_to have_key("bi_special_containers_inbound")
        expect(Test2.relationships_desc[:inbound]).not_to have_key("bi_special_containers_inbound")
      end
      it "should return an empty set" do
        expect(@test_object2.parts).to eq([])
        expect(@test_object2.parts_outbound).to eq([])
      end
      it "should return stuff" do
        @part4.add_relationship(:is_part_of, @test_object2)
        @test_object2.add_relationship(:has_part, @test_object)
        @part4.save
        expect(@test_object2.parts_inbound.map(&:pid)).to eq([@part4.pid])
        expect(@test_object2.parts_outbound.map(&:pid)).to eq([@test_object.pid])
        expect(@test_object2.parts.map(&:pid)).to eq([@part4.pid, @test_object.pid])
      end
      after do
        @test_object2.delete
        begin
          @part4.delete
        rescue
        end
      end
    end
    it "should return an array of Base objects" do
      parts = @test_object.parts
      parts.each do |part|
        expect(part).to be_kind_of(ActiveFedora::Base)
      end
    end
    it "_ids should return an array of pids" do
      ids = @test_object.parts_ids
      expect(ids.size).to eq(2)
      expect(ids.include?(@part1.pid)).to eq(true)
      expect(ids.include?(@part2.pid)).to eq(true)
    end
    it "should return an array of Base objects with some filtered out if using solr_fq" do
      expect(@test_object_query.special_parts_ids).to eq([@special_part.pid])
    end

    it "should return an array of all Base objects with relationship if not using solr_fq" do
      expect(@test_object_query.parts_ids.size).to eq(2)
      expect(@test_object_query.parts_ids.include?(@special_part.pid)).to eq(true)
      expect(@test_object_query.parts_ids.include?(@part3.pid)).to eq(true)
    end

    it "should return a solr query for an inbound relationship" do
      expect(@test_object_query.special_parts_query).to eq("#{ActiveFedora::SolrService.solr_name(@test_object_query.relationship_predicates[:inbound]['special_parts'], :symbol)}:#{solr_uri(@test_object_query.internal_uri)} AND #{@special_part_query}")
    end
  end

  describe "inbound relationship query" do
    it "should return a properly formatted query for a relationship that has a solr filter query defined" do
      expect(SpecNodeSolrFilterQuery.inbound_relationship_query(@test_object_query.pid,"special_parts")).to eq("#{ActiveFedora::SolrService.solr_name(@test_object_query.relationship_predicates[:inbound]['special_parts'], :symbol)}:#{solr_uri(@test_object_query.internal_uri)} AND #{@special_part_query}")
    end

    it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
      expect(SpecNodeSolrFilterQuery.inbound_relationship_query(@test_object_query.pid,"parts")).to eq("#{ActiveFedora::SolrService.solr_name('is_part_of', :symbol)}:#{solr_uri(@test_object_query.internal_uri)}")
    end
  end

  describe "outbound relationship query" do
    it "should return a properly formatted query for a relationship that has a solr filter query defined" do
      expected_string = ""
      @test_object_query.containers_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND #{@special_container_query})"
      end
      expect(SpecNodeSolrFilterQuery.outbound_relationship_query("special_containers",@test_object_query.containers_ids)).to eq(expected_string)
    end

    it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
      expected_string = ""
      @test_object_query.containers_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "id:" + id.gsub(/(:)/, '\\:')
      end
      expect(SpecNodeSolrFilterQuery.outbound_relationship_query("containers",@test_object_query.containers_ids)).to eq(expected_string)
    end
  end

  describe "bidirectional relationship query" do
    it "should return a properly formatted query for a relationship that has a solr filter query defined" do
      expected_string = ""
      @test_object_query.bi_containers_outbound_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND #{@special_container_query})"
      end
      expected_string << " OR "
      expected_string << "(#{ActiveFedora::SolrService.solr_name(@test_object_query.relationship_predicates[:inbound]['bi_special_containers_inbound'], :symbol)}:#{solr_uri(@test_object_query.internal_uri)} AND #{@special_container_query})"
      expect(SpecNodeSolrFilterQuery.bidirectional_relationship_query(@test_object_query.pid,"bi_special_containers",@test_object_query.bi_containers_outbound_ids)).to eq(expected_string)
    end

    it "should return a properly formatted query for a relationship that does not have a solr filter query defined" do
      expected_string = ""
      @test_object_query.bi_containers_outbound_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "id:" + id.gsub(/(:)/, '\\:')
      end
      expected_string << " OR "
      expected_string << "(#{ActiveFedora::SolrService.solr_name(@test_object_query.relationship_predicates[:inbound]['bi_special_containers_inbound'], :symbol)}:#{solr_uri(@test_object_query.internal_uri)})"
      expect(SpecNodeSolrFilterQuery.bidirectional_relationship_query(@test_object_query.pid,"bi_containers",@test_object_query.bi_containers_outbound_ids)).to eq(expected_string)
    end
  end

  describe "outbound relationship finders" do
    it "should return an array of Base objects" do
      containers = @test_object.containers
      expect(containers.length).to be > 0
      containers.each do |container|
        expect(container).to be_kind_of(ActiveFedora::Base)
      end
    end
    it "_ids should return an array of pids" do
      ids = @test_object.containers_ids
      expect(ids.size).to eq(3)
      expect(ids.include?(@container1.pid)).to eq(true)
      expect(ids.include?(@container2.pid)).to eq(true)
      expect(ids.include?(@container3.pid)).to eq(true)
      expect(ids.include?(@container4.pid)).to eq(false)
    end

    it "should return an array of Base objects with some filtered out if using solr_fq" do
      expect(@test_object_query.special_containers_ids.size).to eq(3)
      expect(@test_object_query.special_containers_ids.include?(@container3.pid)).to eq(false)
      expect(@test_object_query.special_containers_ids.include?(@special_container.pid)).to eq(true)
      expect(@test_object_query.special_containers_ids.include?(@special_container3.pid)).to eq(true)
      expect(@test_object_query.special_containers_ids.include?(@special_container4.pid)).to eq(true)
    end

    it "should return an array of all Base objects with relationship if not using solr_fq" do
      expect(@test_object_query.containers_ids.size).to eq(4)
      expect(@test_object_query.containers_ids.include?(@special_container2.pid)).to eq(false)
      expect(@test_object_query.containers_ids.include?(@special_container.pid)).to eq(true)
      expect(@test_object_query.containers_ids.include?(@container3.pid)).to eq(true)
      expect(@test_object_query.containers_ids.include?(@special_container3.pid)).to eq(true)
      expect(@test_object_query.containers_ids.include?(@special_container4.pid)).to eq(true)
    end

    it "should return a solr query for an outbound relationship" do
    end

    it "should return an array of Base objects with some filtered out if using solr_fq" do
      expect(@test_object_query.special_containers_ids.size).to eq(3)
      expect(@test_object_query.special_containers_ids.include?(@container3.pid)).to eq(false)
      expect(@test_object_query.special_containers_ids.include?(@special_container.pid)).to eq(true)
      expect(@test_object_query.special_containers_ids.include?(@special_container3.pid)).to eq(true)
      expect(@test_object_query.special_containers_ids.include?(@special_container4.pid)).to eq(true)
    end

    it "should return an array of all Base objects with relationship if not using solr_fq" do
      expect(@test_object_query.containers_ids.size).to eq(4)
      expect(@test_object_query.containers_ids.include?(@special_container2.pid)).to eq(false)
      expect(@test_object_query.containers_ids.include?(@special_container.pid)).to eq(true)
      expect(@test_object_query.containers_ids.include?(@container3.pid)).to eq(true)
      expect(@test_object_query.containers_ids.include?(@special_container3.pid)).to eq(true)
      expect(@test_object_query.containers_ids.include?(@special_container4.pid)).to eq(true)
    end

    it "should return a solr query for an outbound relationship" do
      expected_string = ""
      @test_object_query.containers_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND #{@special_container_query})"
      end
      expect(@test_object_query.special_containers_query).to eq(expected_string)
    end
  end

  describe "bidirectional relationship finders" do
    it "should return an array of Base objects" do
      containers = @test_object.bi_containers
      expect(containers.length).to be > 0
      containers.each do |container|
        expect(container).to be_kind_of(ActiveFedora::Base)
      end
    end
    it "_ids should return an array of pids" do
      ids = @test_object.bi_containers_ids
      expect(ids.size).to eq(4)
      expect(ids.include?(@container1.pid)).to eq(true)
      expect(ids.include?(@container2.pid)).to eq(true)
      expect(ids.include?(@container3.pid)).to eq(true)
      expect(ids.include?(@container4.pid)).to eq(true)
    end

    it "should return an array of Base objects with some filtered out if using solr_fq" do
      ids = @test_object_query.bi_special_containers_ids
      expect(ids.size).to eq(4)
      expect(ids.include?(@container1.pid)).to eq(false)
      expect(ids.include?(@container2.pid)).to eq(false)
      expect(ids.include?(@container3.pid)).to eq(false)
      expect(ids.include?(@special_container.pid)).to eq(true)
      expect(ids.include?(@special_container2.pid)).to eq(true)
      expect(ids.include?(@special_container3.pid)).to eq(true)
      expect(ids.include?(@special_container4.pid)).to eq(true)
    end

    it "should return an array of all Base objects with relationship if not using solr_fq" do
      expect(@test_object_query.bi_containers_ids).to include @container3.pid, @special_container.pid, @special_container2.pid, @special_container3.pid, @special_container4.pid

      expect(@test_object_query.bi_containers_ids.size).to eq(5)
    end

    it "should return a solr query for a bidirectional relationship" do
      expected_string = ""
      @test_object_query.bi_containers_outbound_ids.each_with_index do |id,index|
        expected_string << " OR " if index > 0
        expected_string << "(id:" + id.gsub(/(:)/, '\\:') + " AND #{@special_container_query})"
      end
      expected_string << " OR "
      expected_string << "(#{ActiveFedora::SolrService.solr_name(@test_object_query.relationship_predicates[:inbound]['bi_special_containers_inbound'], :symbol)}:#{solr_uri(@test_object_query.internal_uri)} AND #{@special_container_query})"
      expect(@test_object_query.bi_special_containers_query).to eq(expected_string)
    end
  end

  #putting this test here instead of relationships_helper because testing that relationships_by_name hash gets refreshed if the relationships hash is changed
  describe "relationships_by_name" do
    before do
      class MockSemNamedRelationships  < ActiveFedora::Base
        include ActiveFedora::FileManagement
        has_relationship "testing", :has_part
        has_relationship "testing2", :has_member
        has_relationship "testing_inbound", :has_part, :inbound=>true
      end
    end

    it 'should automatically update the relationships_by_name if relationships has changed (no refresh of relationships_by_name hash unless relationships hash has changed' do
      @test_object2 = MockSemNamedRelationships.new
      @test_object2.add_relationship(:has_model, MockSemNamedRelationships.to_class_uri)
      #should return expected named relationships
      expect(@test_object2.relationships_by_name).to eq({:self=>{"testing"=>[],"testing2"=>[], "collection_members"=>[], "part_of"=>[], "parts_outbound"=>[]}})
      @test_object2.add_relationship(:has_part, @test_object.internal_uri)
      expect(@test_object2.relationships_by_name).to eq({:self=>{"testing"=>[@test_object.internal_uri],"testing2"=>[], "collection_members"=>[], "part_of"=>[],  "parts_outbound"=>[@test_object.internal_uri]}})
      @test_object2.add_relationship(:has_member, "3", true)
      expect(@test_object2.relationships_by_name).to eq({:self=>{"testing"=>[@test_object.internal_uri],"testing2"=>["3"], "collection_members"=>[], "part_of"=>[],  "parts_outbound"=>[@test_object.internal_uri]}})
    end
  end
end
