require 'spec_helper'

require 'active_fedora'
require "rexml/document"


describe ActiveFedora::RelsExtDatastream do

  before(:all) do
    @sample_relationships_hash = Hash.new(:is_member_of => ["info:fedora/demo:5", "info:fedora/demo:10"])
    @sample_xml_string = <<-EOS
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      <rdf:Description rdf:about="info:fedora/changeme:475">
        <isMemberOf xmlns="info:fedora/fedora-system:def/relations-external#" rdf:resource="info:fedora/demo:5"></isMemberOf>
        <isMemberOf xmlns="info:fedora/fedora-system:def/relations-external#" rdf:resource="info:fedora/demo:10"></isMemberOf>
      </rdf:Description>
    </rdf:RDF>
    EOS

    @sample_xml = REXML::Document.new(@sample_xml_string)
  end

  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_datastream = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
    @test_datastream.model = @test_object
    @test_object.save
  end

  after(:each) do
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


  describe '#serialize!' do

    it "should generate new rdf/xml as the datastream content" do
      @test_object.add_datastream(@test_datastream)
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:5")
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:10")
      rexml1 = REXML::Document.new(@test_datastream.to_rels_ext())
      @test_datastream.serialize!
      rexml2 = REXML::Document.new(@test_object.datastreams["RELS-EXT"].content)
      expect(rexml1.root.elements["rdf:Description"].inspect).to eql(rexml2.root.elements["rdf:Description"].inspect)
    end

  end

  it "should load relationships from fedora into parent object" do
    class SpecNode; include ActiveFedora::SemanticNode; end
    ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace].each_key do |p|
      @test_object.add_relationship(p, "info:fedora/demo:#{rand(100)}")
    end
    @test_object.save
    # make sure that _something_ was actually added to the object's relationships hash
    expect(@test_object.ids_for_outbound(:is_member_of).size).to eq(1)
    new_rels = ActiveFedora::Base.find(@test_object.pid).relationships

    new_rels.to_a.each do |stmt|
      expect(@test_object.relationships).to have_statement(stmt)
    end


    @test_object.relationships.to_a.each do |stmt|
      expect(new_rels).to have_statement(stmt)
    end

 #   new_rels.should == @test_object.relationships
  end

  describe '#from_solr' do
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
    before do
      class MockAFRelsSolr < ActiveFedora::Base
        include ActiveFedora::FileManagement
        has_relationship "testing", :has_part, :type=>MockAFRelsSolr
        has_relationship "testing2", :has_member, :type=>MockAFRelsSolr
        has_relationship "testing_inbound", :has_part, :type=>MockAFRelsSolr, :inbound=>true
        has_relationship "testing_inbound2", :has_member, :type=>MockAFRelsSolr, :inbound=>true
      end
    end
    it "should respond_to from_solr" do
      expect(@test_datastream.respond_to?(:from_solr)).to be_truthy
    end

    it 'should populate the relationships hash based on data in solr only for any possible fedora predicates' do
      @test_object2 = MockAFRelsSolr.new
      #@test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFRelsSolr.new
      #@test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFRelsSolr.new
      #@test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFRelsSolr.new
      #@test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.testing_append(@test_object3)
      @test_object2.testing2_append(@test_object4)
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      @test_object2.save
      @test_object5.save
      model_rel = MockAFRelsSolr.to_class_uri
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      #get solr doc for @test_object2
      solr_doc = MockAFRelsSolr.find_with_conditions(:id=>@test_object2.pid).first
      test_from_solr_object2 = MockAFRelsSolr.new
      test_from_solr_object2.rels_ext.from_solr(solr_doc)
      solr_doc = MockAFRelsSolr.find_with_conditions(:id=>@test_object3.pid).first
      test_from_solr_object3 = MockAFRelsSolr.new
      test_from_solr_object3.rels_ext.from_solr(solr_doc)
      solr_doc = MockAFRelsSolr.find_with_conditions(:id=>@test_object4.pid).first
      test_from_solr_object4 = MockAFRelsSolr.new
      test_from_solr_object4.rels_ext.from_solr(solr_doc)
      solr_doc = MockAFRelsSolr.find_with_conditions(:id=>@test_object5.pid).first
      test_from_solr_object5 = MockAFRelsSolr.new
      test_from_solr_object5.rels_ext.from_solr(solr_doc)

      expect(test_from_solr_object2.object_relations[:has_part]).to include @test_object3.internal_uri
      expect(test_from_solr_object2.object_relations[:has_member]).to include @test_object4.internal_uri
      expect(test_from_solr_object2.object_relations[:has_model]).to include model_rel

      expect(test_from_solr_object2.relationships_by_name).to eq({:self=>{"testing"=>[@test_object3.internal_uri],"testing2"=>[@test_object4.internal_uri], "collection_members"=>[], "part_of"=>[], "parts_outbound"=>[@test_object3.internal_uri]}})
      expect(test_from_solr_object3.object_relations[:has_model]).to include model_rel
      expect(test_from_solr_object3.relationships_by_name).to eq({:self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}})
      expect(test_from_solr_object4.object_relations[:has_model]).to include model_rel
      expect(test_from_solr_object4.relationships_by_name).to eq({:self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}})

      expect(test_from_solr_object5.object_relations[:has_model]).to include model_rel
      expect(test_from_solr_object5.object_relations[:has_part]).to include @test_object2.internal_uri
      expect(test_from_solr_object5.object_relations[:has_member]).to include @test_object3.internal_uri

      expect(test_from_solr_object5.relationships_by_name).to eq({:self=>{"testing2"=>[@test_object3.internal_uri], "collection_members"=>[], "part_of"=>[], "testing"=>[@test_object2.internal_uri], "parts_outbound"=>[@test_object2.internal_uri]}})
    end
  end
end
