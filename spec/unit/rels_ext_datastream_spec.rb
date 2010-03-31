require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require 'ftools'

describe ActiveFedora::RelsExtDatastream do
  
  before(:all) do
    @pid = "test:sample_pid"
    @test_relationship1 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "demo:10")  
    @test_relationship2 = ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_part_of, :object => "demo:11")  
    @test_relationship3 = ActiveFedora::Relationship.new(:subject => @pid, :predicate => :has_part, :object => "demo:12")  
  
    @sample_xml = REXML::Document.new(@sample_xml_string)
  end
  
  before(:each) do
      @test_ds = ActiveFedora::RelsExtDatastream.new(:pid => @pid)
  end
  
  it "should respond to #new" do  
    ActiveFedora::RelsExtDatastream.should respond_to(:new)
  end
  
  describe "#new" do
    it "should create a datsatream with DSID of RELS-EXT" do
      test_datastream = ActiveFedora::RelsExtDatastream.new
      test_datastream.dsid.should eql("RELS-EXT")  
    end
  end
  
  it 'should respond to #save' do
    @test_ds.should respond_to(:save)
  end
  
  describe '#save' do
    
    it "should call super.save" do
      # Funny jiggering to mock super when RelsExt datstream calls super.save
      Fedora::Repository.instance.expects(:save).returns(mock("boo"))
      @test_ds.save
    end
    
    it "should generate new rdf/xml as the datastream content if the object has been changed" do
      @test_ds.dirty = true
      @test_ds.expects(:to_rels_ext)
      @test_ds.expects(:content=)
      # Funny jiggering to mock super when RelsExt datstream calls super.save
      Fedora::Repository.instance.expects(:save).returns(mock("boo"))
      @test_ds.save
    end
  
  end
  
  describe "#from_xml" do
    before(:all) do
      @test_obj = ActiveFedora::Base.new
      @test_obj.add_relationship(:is_member_of, "demo:10")
      @test_obj.add_relationship(:is_part_of, "demo:11")
      @test_obj.save
    end
    after(:all) do
      @test_obj.delete
    end
    it "should load RELS-EXT relationships into relationships hash" do
      @test_obj.relationships.should == {:self=>{:is_member_of=>["info:fedora/demo:10"], :is_part_of=>["info:fedora/demo:11"], :has_model=>["info:fedora/afmodel:ActiveFedora_Base"]}}
      doc = REXML::Document.new(@test_obj.inner_object.object_xml)
      el = doc.elements["/foxml:digitalObject//foxml:datastream[@ID='RELS-EXT']"]
      new_ds = ActiveFedora::RelsExtDatastream.new
      new_ds.relationships.should == {:self=>{}}
      ActiveFedora::RelsExtDatastream.from_xml(new_ds,el)
      new_ds.relationships.should == @test_obj.relationships
    end
  end
  
  
  describe ".to_solr" do
    
    it "should provide .to_solr and return a SolrDocument" do
      @test_ds.should respond_to(:to_solr)
      @test_ds.to_solr.should be_kind_of(Solr::Document)
    end
    
    it "should serialize the relationships into a Solr::Document" do
      @test_ds.add_relationship(@test_relationship1)
      @test_ds.add_relationship(@test_relationship2)
      @test_ds.add_relationship(@test_relationship3)
      solr_doc = @test_ds.to_solr
      solr_doc[:is_member_of_s].should == "info:fedora/demo:10"
      solr_doc[:is_part_of_s].should == "info:fedora/demo:11"
      solr_doc[:has_part_s].should == "info:fedora/demo:12"
    end
  end
  
  it "should treat :self and self.pid as equivalent subjects"
  
end
