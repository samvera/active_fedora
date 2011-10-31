require File.join( File.dirname(__FILE__), "../spec_helper" )

class MockAFBaseRelationship < ActiveFedora::Base
  has_relationship "testing", :has_part, :type=>MockAFBaseRelationship
  has_relationship "testing2", :has_member, :type=>MockAFBaseRelationship
  has_relationship "testing_inbound", :has_part, :type=>MockAFBaseRelationship, :inbound=>true
  has_relationship "testing_inbound2", :has_member, :type=>MockAFBaseRelationship, :inbound=>true
  has_bidirectional_relationship "testing_bidirectional", :has_collection_member, :is_member_of_collection
  #next 2 used to test objects on opposite end of bidirectional relationship
  has_relationship "testing_inbound3", :has_collection_member, :inbound=>true
  has_relationship "testing3", :is_member_of_collection
end

class MockAFBaseDatastream < ActiveFedora::Base
  has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
  has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
end

class MockAFBaseFromSolr < ActiveFedora::Base
  has_relationship "testing", :has_part, :type=>MockAFBaseFromSolr
  has_relationship "testing2", :has_member, :type=>MockAFBaseFromSolr
  has_relationship "testing_inbound", :has_part, :type=>MockAFBaseFromSolr, :inbound=>true
  has_relationship "testing_inbound2", :has_member, :type=>MockAFBaseFromSolr, :inbound=>true
  
  has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
    m.field "holding_id", :string
  end
  
  has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
    m.field "created", :date, :xml_node => "created"
    m.field "language", :string, :xml_node => "language"
    m.field "creator", :string, :xml_node => "creator"
    # Created remaining fields
    m.field "geography", :string, :xml_node => "geography"
    m.field "title", :string, :xml_node => "title"
  end
end

describe "Datastreams synched together" do
  before do
    class DSTest < ActiveFedora::Base
      def configure_defined_datastreams
        super
        unless self.datastreams.keys.include? 'test_ds'
         add_file_datastream("XXX",:dsid=>'test_ds', :mimeType=>'text/html')
        end
      end
    end
  end
  it "Should update datastream" do
    @nc = DSTest.new
    @nc.save
    @nc.test_ds.content.should == 'XXX'
    ds  = @nc.datastreams['test_ds']
    ds.content = "Foobar"
    @nc.save
    DSTest.find(@nc.pid).datastreams['test_ds'].content.should == 'Foobar'
    DSTest.find(@nc.pid).test_ds.content.should == 'Foobar'
  end

end


describe ActiveFedora::Base do
  
  before(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
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
  
  describe ".initialize" do
    it "calling constructor should create a new Fedora Object" do    
      @test_object.should have(0).errors
      @test_object.pid.should_not be_nil
    end

    it "passing namespace to constructor with no pid should generate a pid with the supplied namespace" do
      @test_object2 = ActiveFedora::Base.new({:namespace=>"randomNamespace"})
      #@test_object2.pid.match('changeme:\d+').to_a.first.should == @test_object2.pid
      # will be nil if match failed, otherwise will equal pid
      @test_object2.pid.match('randomNamespace:\d+').to_a.first.should == @test_object2.pid
    end
  end
  
  describe ".save" do
    before(:each) do
      @test_object2 = ActiveFedora::Base.new
    end

    after(:each) do
      @test_object2.delete
    end
    
    it "should set the CMA hasModel relationship in the Rels-EXT" do 
      @test_object2.save
      rexml = REXML::Document.new(@test_object2.datastreams["RELS-EXT"].content)
      # Purpose: confirm that the isMemberOf entries exist and have real RDF in them
      rexml.root.elements["rdf:Description/ns0:hasModel"].attributes["rdf:resource"].should == 'info:fedora/afmodel:ActiveFedora_Base'
    end
    it "should merge attributes from fedora into attributes hash" do
      inner_object = @test_object2.inner_object
      inner_object.pid.should == @test_object2.pid
      @test_object2.save
      inner_object.should respond_to(:state)
      inner_object.should respond_to(:lastModifiedDate)
      inner_object.should respond_to(:ownerId)
      inner_object.state.should == "A"
      inner_object.ownerId.should == "fedoraAdmin"
    end
  end
  
  describe "#load_instance" do
    it "should return an object loaded from fedora" do
      result = ActiveFedora::Base.load_instance(@test_object.pid)
      result.should be_instance_of(ActiveFedora::Base)
    end
  end
  
  describe ".datastreams" do
    it "should return a Hash of datastreams from fedora" do
      datastreams = @test_object.datastreams
      datastreams.should be_a_kind_of(Hash) 
      datastreams.each_value do |ds| 
        ds.should be_a_kind_of(ActiveFedora::Datastream)
      end
      @test_object.datastreams["DC"].should be_an_instance_of(ActiveFedora::Datastream)
      datastreams["DC"].should_not be_nil
      datastreams["DC"].should be_an_instance_of(ActiveFedora::Datastream)       
    end
    it "should initialize the datastream pointers with @new_object=false" do
      datastreams = @test_object.datastreams
      datastreams.each_value do |ds| 
        ds.new_object?.should be_false
      end
    end
  end
  
  describe ".metadata_streams" do
    it "should return all of the datastreams from the object that are kinds of MetadataDatastreams " do
      mds1 = ActiveFedora::MetadataDatastream.new(@test_object.inner_object, "md1")
      mds2 = ActiveFedora::QualifiedDublinCoreDatastream.new(@test_object.inner_object, "qdc")
      fds = ActiveFedora::Datastream.new(@test_object.inner_object, "fds")
      @test_object.add_datastream(mds1)
      @test_object.add_datastream(mds2)
      @test_object.add_datastream(fds)      
      
      result = @test_object.metadata_streams
      result.length.should == 2
      result.should include(mds1)
      result.should include(mds2)
    end
  end
  
  describe ".file_streams" do
    it "should return all of the datastreams from the object that are kinds of MetadataDatastreams" do
      fds1 = ActiveFedora::Datastream.new(@test_object.inner_object, "fds1")
      fds2 = ActiveFedora::Datastream.new(@test_object.inner_object, "fds2")
      mds = ActiveFedora::MetadataDatastream.new(@test_object.inner_object, "mds")
      @test_object.add_datastream(fds1)  
      @test_object.add_datastream(fds2)
      @test_object.add_datastream(mds)    
      
      result = @test_object.file_streams
      result.length.should == 2
      result.should include(fds1)
      result.should include(fds2)
    end
    it "should skip DC and RELS-EXT datastreams" do
      fds1 = ActiveFedora::Datastream.new(@test_object.inner_object,"fds1")
      dc = ActiveFedora::Datastream.new(@test_object.inner_object, "DC")
      rels_ext = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
      @test_object.add_datastream(fds1)  
      @test_object.add_datastream(dc)
      @test_object.add_datastream(rels_ext)    
      @test_object.file_streams.should  == [fds1]
    end
  end
  
  describe ".dc" do
    it "should expose the DC datastream" do
      dc = @test_object.dc
      dc.should be_a_kind_of(ActiveFedora::Datastream)
      #dc["identifier"].should_not be_nil
      rexml = REXML::Document.new(dc.content)
      rexml.root.elements["dc:identifier"].get_text.should_not be_nil
      #dc.elements["dc:identifier"].should_not be_nil
    end
  end

  
  describe '.rels_ext' do
    it "should retrieve RelsExtDatastream object via rels_ext method" do
      @test_object.rels_ext.should be_instance_of(ActiveFedora::RelsExtDatastream)
    end
    
    it 'should create the RELS-EXT datastream if it doesnt exist' do
      test_object = ActiveFedora::Base.new
      #test_object.datastreams["RELS-EXT"].should == nil
      test_object.rels_ext
      test_object.datastreams["RELS-EXT"].should_not == nil
      test_object.datastreams["RELS-EXT"].class.should == ActiveFedora::RelsExtDatastream
    end
  end

  describe '.add_relationship' do
    it "should update the RELS-EXT datastream and relationships should end up in Fedora when the object is saved" do
      test_relationships = [ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:5"), 
                                ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:10"),
                                ActiveFedora::Relationship.new(:subject => :self, :predicate => :conforms_to, :object => "info:fedora/afmodel:OralHistory")]
      test_relationships.each do |rel|
        @test_object.add_relationship(rel.predicate, rel.object)
      end
      @test_object.save
      rexml = REXML::Document.new(@test_object.datastreams["RELS-EXT"].content)
      # Purpose: confirm that the isMemberOf entries exist and have real RDF in them
      rexml.root.attributes["xmlns:ns1"].should == 'info:fedora/fedora-system:def/relations-external#'
      rexml.root.elements["rdf:Description/ns1:isMemberOf[@rdf:resource='info:fedora/demo:5']"].should_not be_nil
      rexml.root.elements["rdf:Description/ns1:isMemberOf[@rdf:resource='info:fedora/demo:10']"].should_not be_nil
    end
  end

  describe '.add_file_datastream' do

   it "should set the correct mimeType if :mime_type, :mimeType, or :content_type passed in and path does not contain correct extension" do
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object.add_file_datastream(f)
     @test_object.save
     test_obj = ActiveFedora::Base.load_instance(@test_object.pid)
     #check case where nothing passed in does not have correct mime type
     test_obj.datastreams["DS1"].mimeType.should == "application/octet-stream"
     @test_object2 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object2.add_file_datastream(f,{:mimeType=>"image/jpeg"})
     @test_object2.save
     test_obj = ActiveFedora::Base.load_instance(@test_object2.pid)
     test_obj.datastreams["DS1"].mimeType.should == "image/jpeg"
     @test_object3 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object3.add_file_datastream(f,{:mime_type=>"image/jpeg"})
     @test_object3.save
     test_obj = ActiveFedora::Base.load_instance(@test_object3.pid)
     test_obj.datastreams["DS1"].mimeType.should == "image/jpeg"
     @test_object4 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object4.add_file_datastream(f,{:content_type=>"image/jpeg"})
     @test_object4.save
     test_obj = ActiveFedora::Base.load_instance(@test_object4.pid)
     test_obj.datastreams["DS1"].mimeType.should == "image/jpeg"
   end
  end
  
  describe '.add_datastream' do
  
    it "should be able to add datastreams" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1')
      # ds = ActiveFedora::Datastream.new(:dsID => 'DS1', :dsLabel => 'hello', :altIDs => '3333', 
      #   :controlGroup => 'M', :blob => fixture('dino.jpg'))
      @test_object.add_datastream(ds).should be_true
    end
      
    it "adding and saving should add the datastream to the datastreams array" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1') 
      ds.content = fixture('dino.jpg').read
      # ds = ActiveFedora::Datastream.new(:dsid => 'DS1', :dsLabel => 'hello', :altIDs => '3333', 
      #   :controlGroup => 'M', :blob => fixture('dino.jpg'))
      @test_object.datastreams.should_not have_key("DS1")
      @test_object.add_datastream(ds)
      ds.save
      @test_object.datastreams.should have_key("DS1")
    end
    
  end
  
  it "should retrieve blobs that match the saved blobs" do
    ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1')
    ds.content = "foo"
    new_ds = ds.save
    @test_object.add_datastream(new_ds)
    @test_object.class.find(@test_object.pid).datastreams["DS1"].content.should == new_ds.content
  end
  
  describe ".create_date" do 
    it "should return W3C date" do 
      @test_object.create_date.should_not be_nil
    end
  end
  
  describe ".modified_date" do 
    it "should return nil before saving and a W3C date after saving" do       
      @test_object.modified_date.should_not be_nil
    end  
  end
  
  describe "delete" do
    
    it "should delete the object from Fedora and Solr" do
      ActiveFedora::Base.find_by_solr(@test_object.pid).hits.first["id"].should == @test_object.pid
      @test_object.delete
      ActiveFedora::Base.find_by_solr(@test_object.pid).hits.should be_empty
    end

    describe '#delete' do
      it 'if inbound relationships exist should remove relationships from those inbound targets as well when deleting this object' do
        @test_object2 = MockAFBaseRelationship.new
#        @test_object2.new_object = true
        @test_object2.save
        @test_object3 = MockAFBaseRelationship.new
#        @test_object3.new_object = true
        @test_object3.save
        @test_object4 = MockAFBaseRelationship.new
#        @test_object4.new_object = true
        @test_object4.save
        @test_object5 = MockAFBaseRelationship.new
#        @test_object5.new_object = true
        @test_object5.save
        #append to relationship by 'testing'
        @test_object2.add_relationship_by_name("testing",@test_object3)
        @test_object2.add_relationship_by_name("testing2",@test_object4)
        @test_object5.add_relationship_by_name("testing",@test_object2)
        @test_object5.add_relationship_by_name("testing2",@test_object3)
        @test_object2.save
        @test_object5.save
        r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
        r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
        r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
        r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
        model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
        #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
        @test_object2.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r5.object], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r4.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r3.object], "parts_outbound"=>[r3.object], "testing_bidirectional_outbound"=>[]}}
        @test_object3.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r2.object], "testing_inbound2"=>[r5.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
        @test_object4.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r2.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
        @test_object5.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r3.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object], "testing_bidirectional_outbound"=>[]}}
        @test_object2.delete
        #need to reload since removed from rels_ext in memory
        @test_object5 = MockAFBaseRelationship.load_instance(@test_object5.pid)
      
        #check any test_object2 inbound rels gone from source
        @test_object3.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r5.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
        @test_object4.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
        @test_object5.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r3.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
    end
  end
    
  end

  describe '#remove_relationship' do
    it 'should remove a relationship from an object after a save' do
      @test_object2 = ActiveFedora::Base.new
      @test_object.add_relationship(:has_part,@test_object2)
      @test_object.save
      @pid = @test_object.pid
      begin
        @test_object = ActiveFedora::Base.load_instance(@pid)
      rescue => e
        puts "#{e.message}\n#{e.backtrace}"
        raise e
      end
      #use dummy relationships just to get correct formatting for expected objects
      r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(ActiveFedora::Base))
#      @test_object.relationships.should == {:self=>{:has_model=>[model_rel.object], :has_part=>[r.object]}}
      stmt = @test_object.build_statement(@test_object.internal_uri, :has_part, r.object)
      @test_object.relationships.has_statement?(stmt).should be_true
      @test_object.remove_relationship(:has_part,@test_object2)
      @test_object.save
      @test_object = ActiveFedora::Base.load_instance(@pid)
      @test_object.relationships.has_statement?(stmt).should be_false
    end
  end

  describe '#relationships' do
    it 'should return internal relationships with no parameters and include inbound if false passed in' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.testing_append(@test_object3)
      @test_object2.testing2_append(@test_object4)
      @test_object2.testing3_append(@test_object5)
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      @test_object5.testing_bidirectional_append(@test_object4)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      stmt = @test_object2.build_statement(@test_object2.internal_uri, :has_model, model_rel.object)
      @test_object2.relationships.has_statement?(stmt).should be_true
      stmt = @test_object2.build_statement(@test_object2.internal_uri, :has_part, r3.object)
      @test_object2.relationships.has_statement?(stmt).should be_true
      stmt = @test_object2.build_statement(@test_object2.internal_uri, :has_member, r4.object)
      @test_object2.relationships.has_statement?(stmt).should be_true
      stmt = @test_object2.build_statement(@test_object2.internal_uri, :is_member_of_collection, r5.object)
      @test_object2.relationships.has_statement?(stmt).should be_true
      @test_object2.inbound_relationships.should == {:has_part=>[r5.object]}
      stmt = @test_object3.build_statement(@test_object3.internal_uri, :has_model, model_rel.object)
      @test_object3.relationships.has_statement?(stmt).should be_true
      @test_object3.inbound_relationships.should == {:has_part=>[r2.object],
                                                               :has_member=>[r5.object]}
      stmt = @test_object4.build_statement(@test_object4.internal_uri, :has_model, model_rel.object)
      @test_object4.relationships.has_statement?(stmt).should be_true
      @test_object4.inbound_relationships.should == {:has_member=>[r2.object],:has_collection_member=>[r5.object]}

      stmt = @test_object5.build_statement(@test_object5.internal_uri, :has_model, model_rel.object)
      @test_object5.relationships.has_statement?(stmt).should be_true
      stmt = @test_object5.build_statement(@test_object5.internal_uri, :has_part, r2.object)
      @test_object5.relationships.has_statement?(stmt).should be_true
      stmt = @test_object5.build_statement(@test_object5.internal_uri, :has_member, r3.object)
      @test_object5.relationships.has_statement?(stmt).should be_true
      stmt = @test_object5.build_statement(@test_object5.internal_uri, :has_collection_member, r4.object)
      @test_object5.relationships.has_statement?(stmt).should be_true
      @test_object5.inbound_relationships.should == {:is_member_of_collection=>[r2.object]}
      # @test_object2.outbound_relationships.should == {:has_model=>[model_rel.object],
      #                                                       :has_part=>[r3.object],
      #                                                       :has_member=>[r4.object],
      #                                                       :is_member_of_collection=>[r5.object]}
      # @test_object3.outbound_relationships.should == {:has_model=>[model_rel.object]}
      # @test_object4.outbound_relationships.should == {:has_model=>[model_rel.object]}
      # @test_object5.outbound_relationships.should == {:has_model=>[model_rel.object],
      #                                                       :has_part=>[r2.object],
      #                                                       :has_member=>[r3.object],
      #                                                       :has_collection_member=>[r4.object]}
    end
  end
  
  describe '#inbound_relationships' do
    it 'should return a hash of inbound relationships' do
      @test_object2 = MockAFBaseRelationship.new
      #@test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      #@test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      #@test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      #@test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.testing_append(@test_object3)
      @test_object2.testing2_append(@test_object4)
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      #@test_object5.testing_bidirectional_append(@test_object4)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      @test_object2.inbound_relationships.should == {:has_part=>[r5.object]}
      @test_object3.inbound_relationships.should == {:has_part=>[r2.object],:has_member=>[r5.object]}
      @test_object4.inbound_relationships.should == {:has_member=>[r2.object]}
      @test_object5.inbound_relationships.should == {}
    end
  end
  
  describe '#inbound_relationships_by_name' do
    it 'should return a hash of inbound relationship names to array of objects' do
      @test_object2 = MockAFBaseRelationship.new
      #@test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      #@test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      #@test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      #@test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.testing_append(@test_object3)
      @test_object2.testing2_append(@test_object4)
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      @test_object2.inbound_relationships_by_name.should == {"testing_inbound"=>[r5.object],"testing_inbound2"=>[],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []}
      @test_object3.inbound_relationships_by_name.should == {"testing_inbound"=>[r2.object],"testing_inbound2"=>[r5.object],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []}
      @test_object4.inbound_relationships_by_name.should == {"testing_inbound"=>[],"testing_inbound2"=>[r2.object],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []}
      @test_object5.inbound_relationships_by_name.should == {"testing_inbound"=>[],"testing_inbound2"=>[],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []}
    end
  end
  
  describe '#relationships_by_name' do
    it '' do
      @test_object2 = MockAFBaseRelationship.new
      #@test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      #@test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      #@test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      #@test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.testing_append(@test_object3)
      @test_object2.testing2_append(@test_object4)
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      @test_object2.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r5.object], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r4.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r3.object], "parts_outbound"=>[r3.object], "testing_bidirectional_outbound"=>[]}}
      @test_object3.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r2.object], "testing_inbound2"=>[r5.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object4.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r2.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object5.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r3.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object], "testing_bidirectional_outbound"=>[]}}
      #all inbound should now be empty if no parameter supplied to relationships
      @test_object2.relationships_by_name.should == {:self=>{"testing2"=>[r4.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r3.object], "parts_outbound"=>[r3.object], "testing_bidirectional_outbound"=>[]}}
      @test_object3.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object4.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object5.relationships_by_name.should == {:self=>{"testing2"=>[r3.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object], "testing_bidirectional_outbound"=>[]}}
    end
  end
  
  describe '#add_relationship_by_name' do
    it 'should add a named relationship to an object' do
      @test_object2 = MockAFBaseRelationship.new
      #@test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      #@test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      #@test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      #@test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.add_relationship_by_name("testing",@test_object3)
      @test_object2.add_relationship_by_name("testing2",@test_object4)
      @test_object5.add_relationship_by_name("testing",@test_object2)
      @test_object5.add_relationship_by_name("testing2",@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      @test_object2.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r5.object], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r4.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r3.object], "parts_outbound"=>[r3.object], "testing_bidirectional_outbound"=>[]}}
      @test_object3.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r2.object], "testing_inbound2"=>[r5.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object4.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r2.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object5.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r3.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object], "testing_bidirectional_outbound"=>[]}}
    end
  end
  
  describe '#remove_named_relationship' do
    it 'should remove an existing relationship from an object' do
      @test_object2 = MockAFBaseRelationship.new
      #@test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      #@test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      #@test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      #@test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.add_relationship_by_name("testing",@test_object3)
      @test_object2.add_relationship_by_name("testing2",@test_object4)
      @test_object5.add_relationship_by_name("testing",@test_object2)
      @test_object5.add_relationship_by_name("testing2",@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      @test_object2.relationships_by_name(false).should == {:self=>{"testing"=>[r3.object],
                                                            "testing2"=>[r4.object],
                                                            "testing_bidirectional_outbound"=>[],"testing3"=>[], 
                                                            "collection_members"=>[], "part_of"=>[], "parts_outbound"=>[r3.object]},
                                                    :inbound=>{"testing_inbound"=>[r5.object],"testing_inbound2"=>[],
          "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound"=>[]}}
      @test_object3.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r2.object], "testing_inbound2"=>[r5.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object4.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r2.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object5.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r3.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object], "testing_bidirectional_outbound"=>[]}}
      @test_object2.remove_relationship_by_name("testing",@test_object3)
      @test_object2.save
      #check now removed for both outbound and inbound
      @test_object2.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[r5.object], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r4.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object3.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r5.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object4.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r2.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      @test_object5.relationships_by_name(false).should == {:inbound=>{"testing_inbound3"=>[], "testing_bidirectional_inbound"=>[], "parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r3.object], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object], "testing_bidirectional_outbound"=>[]}}
    end
  end

  describe '#find_relationship_by_name' do
    it 'should find relationships based on name passed in for inbound or outbound' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.add_relationship_by_name("testing",@test_object3)
      @test_object2.add_relationship_by_name("testing2",@test_object4)
      @test_object5.add_relationship_by_name("testing",@test_object2)
      @test_object5.add_relationship_by_name("testing2",@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      @test_object2.find_relationship_by_name("testing").should == [r3.object]
      @test_object2.find_relationship_by_name("testing2").should == [r4.object]
      @test_object2.find_relationship_by_name("testing_inbound").should == [r5.object]
      @test_object2.find_relationship_by_name("testing_inbound2").should == []
      @test_object3.find_relationship_by_name("testing").should == []
      @test_object3.find_relationship_by_name("testing2").should == []
      @test_object3.find_relationship_by_name("testing_inbound").should == [r2.object]
      @test_object3.find_relationship_by_name("testing_inbound2").should == [r5.object]
      @test_object4.find_relationship_by_name("testing").should == []
      @test_object4.find_relationship_by_name("testing2").should == []
      @test_object4.find_relationship_by_name("testing_inbound").should == []
      @test_object4.find_relationship_by_name("testing_inbound2").should == [r2.object]
      @test_object5.find_relationship_by_name("testing").should == [r2.object]
      @test_object5.find_relationship_by_name("testing2").should == [r3.object]
      @test_object5.find_relationship_by_name("testing_inbound").should == []
      @test_object5.find_relationship_by_name("testing_inbound2").should == []
      
    end
  end
  
  #
  # Named datastream specs
  #
  describe '#add_named_datastream' do
    it 'should add a datastream with the given name to the object in fedora' do
      @test_object2 = MockAFBaseDatastream.new
#      @test_object2.new_object = true
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stubs(:original_filename).returns("dino.jpg")
      f.stubs(:content_type).returns("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f, :label=>"testDS"})
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      ds = @test_object2.thumbnail.first
      ds2 = @test_object2.high.first
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.load_instance(@test_object2.pid)
      @test_object2.named_datastreams.keys.size.should == 2
      @test_object2.named_datastreams.keys.include?("thumbnail").should == true
      @test_object2.named_datastreams.keys.include?("high").should == true
      @test_object2.named_datastreams["thumbnail"].size.should == 1
      @test_object2.named_datastreams["high"].size.should == 1
      t2_thumb1 = @test_object2.named_datastreams["thumbnail"].first
      t2_thumb1.dsid.should == ds.dsid
      t2_thumb1.mimeType.should == ds.mimeType
      t2_thumb1.pid.should == ds.pid
      t2_thumb1.dsLabel.should == ds.dsLabel
      t2_thumb1.controlGroup.should == ds.controlGroup
      t2_high1 = @test_object2.named_datastreams["high"].first
      t2_high1.dsid.should == ds2.dsid
      t2_high1.mimeType.should == ds2.mimeType
      t2_high1.pid.should == ds2.pid
      t2_high1.dsLabel.should == ds2.dsLabel
      t2_high1.controlGroup.should == ds2.controlGroup
    end
  end
  
  describe '#add_named_file_datastream' do
    it 'should add a file datastream with the given name to the object in fedora' do
      @test_object2 = MockAFBaseDatastream.new
#      @test_object2.new_object = true
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f.stubs(:content_type).returns("image/jpeg")
      @test_object2.add_named_file_datastream("thumbnail",f)
      ds = @test_object2.thumbnail.first
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.load_instance(@test_object2.pid)
      @test_object2.named_datastreams["thumbnail"].size.should == 1
      t2_thumb1 = @test_object2.named_datastreams["thumbnail"].first
      t2_thumb1.dsid.should == "THUMB1"
      t2_thumb1.mimeType.should == "image/jpeg"
      t2_thumb1.pid.should == @test_object2.pid
      t2_thumb1.dsLabel.should == "minivan.jpg"
      t2_thumb1.controlGroup.should == "M"

# .attributes.should == {"label"=>ds.label,"dsid"=>ds.dsid,
#                                                                                  "mimeType"=>ds.attributes[:mimeType],
#                                                                                  :controlGroup=>ds.attributes[:controlGroup],
#                                                                                  :pid=>ds.pid, :dsID=>ds.dsid, :dsLabel=>ds.attributes[:dsLabel]}
    end
  end
  
  describe '#update_named_datastream' do
    it 'should update a named datastream to have a new file' do
      @test_object2 = MockAFBaseDatastream.new
#      @test_object2.new_object = true
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      minivan = f.read
      f.rewind
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      dino = f2.read
      f2.rewind
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      f2.stubs(:content_type).returns("image/jpeg")
      f2.stubs(:original_filename).returns("dino.jpg")
      #check raise exception if dsid not supplied
      @test_object2.add_named_datastream("thumbnail",{:file=>f})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.load_instance(@test_object2.pid)
      
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      ds = @test_object2.thumbnail.first
      ds.dsid.should == "THUMB1"
      ds.mimeType.should == "image/jpeg"
      ds.pid.should == @test_object2.pid
      ds.dsLabel.should == "minivan.jpg"
      ds.controlGroup.should == "M"

      ds.content.should == minivan 
      @test_object2.update_named_datastream("thumbnail",{:file=>f2,:dsid=>"THUMB1"})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.load_instance(@test_object2.pid)
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      ds2 = @test_object2.thumbnail.first
      ds2.dsid.should == "THUMB1"
      ds2.mimeType.should == "image/jpeg"
      ds2.pid.should == @test_object2.pid
      ds2.dsLabel.should == "dino.jpg"
      ds2.controlGroup.should == "M"
      (ds2.content == dino).should be_true
    end
  end
  
  describe '#named_datastreams_ids' do
    it 'should return a hash of datastream name to an array of dsids' do
      @test_object2 = MockAFBaseDatastream.new
#      @test_object2.new_object = true
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stubs(:original_filename).returns("dino.jpg")
      f.stubs(:content_type).returns("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f, :label=>"testDS"})
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f2})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.load_instance(@test_object2.pid)
      @test_object2.named_datastreams_ids.should == {"high"=>[], "thumbnail"=>["THUMB1", "THUMB2"]}
    end
  end
  
#   describe '#load_instance_from_solr' do
#     it 'should populate an instance of an ActiveFedora::Base object using solr instead of Fedora' do
#       
#       @test_object2 = MockAFBaseFromSolr.new
# #      @test_object2.new_object = true
#       attributes = {"holding_id"=>{0=>"Holding 1"},
#                     "language"=>{0=>"Italian"},
#                     "creator"=>{0=>"Linguist, A."},
#                     "geography"=>{0=>"Italy"},
#                     "title"=>{0=>"Italian and Spanish: A Comparison of Common Phrases"}}
#       @test_object2.update_indexed_attributes(attributes)
#       @test_object2.save
#       @test_object3 = MockAFBaseFromSolr.new
# #      @test_object3.new_object = true
#       attributes = {"holding_id"=>{0=>"Holding 2"},
#                     "language"=>{0=>"Spanish;Latin"},
#                     "creator"=>{0=>"Linguist, A."},
#                     "geography"=>{0=>"Spain"},
#                     "title"=>{0=>"A study of the evolution of Spanish from Latin"}}
#       @test_object3.update_indexed_attributes(attributes)
#       @test_object3.save
#       @test_object4 = MockAFBaseFromSolr.new
#       attributes = {"holding_id"=>{0=>"Holding 3"},
#                     "language"=>{0=>"Spanish;Latin"},
#                     "creator"=>{0=>"Linguist, A."},
#                     "geography"=>{0=>"Spain"},
#                     "title"=>{0=>"An obscure look into early nomadic tribes of Spain"}}
#       @test_object4.update_indexed_attributes(attributes)
# #      @test_object4.new_object = true
#       @test_object4.save
#       @test_object5 = MockAFBaseFromSolr.new
# #      @test_object5.new_object = true
#       @test_object5.save
#       
#       #append to named relationship 'testing'
#       @test_object2.testing_append(@test_object3)
#       @test_object2.testing2_append(@test_object4)
#       @test_object5.testing_append(@test_object2)
#       @test_object5.testing2_append(@test_object3)
#       @test_object2.save
#       @test_object5.save
#       r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
#       r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
#       r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
#       r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
#       model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseFromSolr))
#       #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
#       test_from_solr_object2 = MockAFBaseFromSolr.load_instance_from_solr(@test_object2.pid)
#       test_from_solr_object3 = MockAFBaseFromSolr.load_instance_from_solr(@test_object3.pid)
#       test_from_solr_object4 = MockAFBaseFromSolr.load_instance_from_solr(@test_object4.pid)
#       test_from_solr_object5 = MockAFBaseFromSolr.load_instance_from_solr(@test_object5.pid)
#       
#       # need to check pid, system create and system modify
#       test_from_solr_object2.pid.should == @test_object2.pid
#       test_from_solr_object3.pid.should == @test_object3.pid
#       test_from_solr_object4.pid.should == @test_object4.pid
#       test_from_solr_object5.pid.should == @test_object5.pid
#       
#       Time.parse(test_from_solr_object2.create_date).should == Time.parse(@test_object2.create_date)
#       Time.parse(test_from_solr_object3.create_date).should == Time.parse(@test_object3.create_date)
#       Time.parse(test_from_solr_object4.create_date).should == Time.parse(@test_object4.create_date)
#       Time.parse(test_from_solr_object5.create_date).should == Time.parse(@test_object5.create_date)
#       
#       Time.parse(test_from_solr_object2.modified_date).should == Time.parse(@test_object2.modified_date)
#       Time.parse(test_from_solr_object3.modified_date).should == Time.parse(@test_object3.modified_date)
#       Time.parse(test_from_solr_object4.modified_date).should == Time.parse(@test_object4.modified_date)
#       Time.parse(test_from_solr_object5.modified_date).should == Time.parse(@test_object5.modified_date)
# 
#       # need to test outbound and inbound relationships
#       test_from_solr_object2.relationships(false).should == {:self=>{:has_model=>[model_rel.object],
#                                                             :has_part=>[r3.object],
#                                                             :has_member=>[r4.object]},
#                                                     :inbound=>{:has_part=>[r5.object]}}
#       test_from_solr_object2.relationships_by_name(false).should == {:self=>{"testing"=>[r3.object],"testing2"=>[r4.object],
#         "collection_members"=>[],"part_of"=>[],"parts_outbound"=>[r3.object]},
#         :inbound=>{"testing_inbound"=>[r5.object],"testing_inbound2"=>[],"parts_inbound"=>[]}}
#       test_from_solr_object3.relationships(false).should == {:self=>{:has_model=>[model_rel.object]},
#                                                    :inbound=>{:has_part=>[r2.object],
#                                                                :has_member=>[r5.object]}}
#       test_from_solr_object3.relationships_by_name(false).should == {:self=>{"testing"=>[],"testing2"=>[], "collection_members"=>[],"part_of"=>[],"parts_outbound"=>[]},
#                                                                    :inbound=>{"testing_inbound"=>[r2.object],"testing_inbound2"=>[r5.object], "parts_inbound"=>[]}}                                                                  
#       test_from_solr_object4.relationships(false).should == {:self=>{:has_model=>[model_rel.object]},
#                                                     :inbound=>{:has_member=>[r2.object]}}
#       test_from_solr_object4.relationships_by_name(false).should == {:inbound=>{"parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[r2.object]}, :self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}}                       
#       test_from_solr_object5.relationships(false).should == {:self=>{:has_model=>[model_rel.object],
#                                                             :has_part=>[r2.object],
#                                                             :has_member=>[r3.object]},
#                                                     :inbound=>{}}
#       test_from_solr_object5.relationships_by_name(false).should == {:inbound=>{"parts_inbound"=>[], "testing_inbound"=>[], "testing_inbound2"=>[]}, :self=>{"testing2"=>[r3.object], "collection_members"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object]}}
#       #all inbound should now be empty if no parameter supplied to relationships
#       test_from_solr_object2.relationships.should == {:self=>{:has_part=>[r3.object],:has_member=>[r4.object],:has_model=>[model_rel.object]}}
#       test_from_solr_object2.relationships_by_name.should == {:self=>{"testing2"=>[r4.object], "collection_members"=>[], "part_of"=>[], "testing"=>[r3.object], "parts_outbound"=>[r3.object]}}
#       test_from_solr_object3.relationships.should == {:self=>{:has_model=>[model_rel.object]}}
#       test_from_solr_object3.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}}
#       test_from_solr_object4.relationships.should == {:self=>{:has_model=>[model_rel.object]}}
#       test_from_solr_object4.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}} 
#       test_from_solr_object5.relationships.should == {:self=>{:has_model=>[model_rel.object],
#                                                              :has_part=>[r2.object],
#                                                              :has_member=>[r3.object]}}
#       test_from_solr_object5.relationships_by_name.should == {:self=>{"testing2"=>[r3.object], "collection_members"=>[], "part_of"=>[], "testing"=>[r2.object], "parts_outbound"=>[r2.object]}}
#       # need to check metadata
#       test_from_solr_object2.fields[:language][:values].should == ["Italian"]
#       test_from_solr_object2.fields[:creator][:values].should == ["Linguist, A."]
#       test_from_solr_object2.fields[:geography][:values].should == ["Italy"]
#       test_from_solr_object2.fields[:title][:values].should == ["Italian and Spanish: A Comparison of Common Phrases"]
#       test_from_solr_object2.fields[:holding_id][:values].should == ["Holding 1"]
#       
#       test_from_solr_object3.fields[:language][:values].should == ["Spanish;Latin"]
#       test_from_solr_object3.fields[:creator][:values].should == ["Linguist, A."]
#       test_from_solr_object3.fields[:geography][:values].should == ["Spain"]
#       test_from_solr_object3.fields[:title][:values].should == ["A study of the evolution of Spanish from Latin"]
#       test_from_solr_object3.fields[:holding_id][:values].should == ["Holding 2"]
#       
#       test_from_solr_object4.fields[:language][:values].should == ["Spanish;Latin"]
#       test_from_solr_object4.fields[:creator][:values].should == ["Linguist, A."]
#       test_from_solr_object4.fields[:geography][:values].should == ["Spain"]
#       test_from_solr_object4.fields[:title][:values].should == ["An obscure look into early nomadic tribes of Spain"]
#       test_from_solr_object4.fields[:holding_id][:values].should == ["Holding 3"]
# 
#       #need to check system modified and system created values correct
#       # need to implement for nokogiri datastream as well
#       #false.should == true
#     end
#   end
#   
#   describe 'load_from_solr using relationship finders'
#     it 'resulting finder should accept :load_from_solr as :response_format and return object instantiated using load_instance_from_solr' do
# #      solr_result = mock("solr result")
# #      SpecNode.create_inbound_relationship_finders("constituents", :is_constituent_of, :inbound => true)
# #      local_node = SpecNode.new
# #      mock_repo = mock("repo")
# #      mock_repo.expects(:find_model).never
# #      SpecNode.expects(:load_instance_from_solr).times(1)
# #      local_node.expects(:internal_uri).returns("info:fedora/test:sample_pid")
# #      ActiveFedora::SolrService.instance.conn.expects(:query).with("is_constituent_of_s:info\\:fedora/test\\:sample_pid").returns(solr_result)
# #      local_node.constituents(:response_format => :solr).should equal(solr_result)
#     end
#     
#     it 'when an object is loaded via solr instead of fedora it should automatically load objects from finders from solr as well' do
#       @test_object2 = MockAFBaseFromSolr.new
#       @test_object2.save
#       @test_object3 = MockAFBaseFromSolr.new
#       @test_object3.save
#       @test_object2.testing_append(@test_object3)
#       @test_object2.save
#       
#       test_object2_from_solr = MockAFBaseFromSolr.load_instance_from_solr(@test_object2.pid)
#       test_object3_from_solr = MockAFBaseFromSolr.load_instance_from_solr(@test_object3.pid)
#       MockAFBaseFromSolr.expects(:load_instance_from_solr).times(4)
#       test_object2_from_solr.testing({:response_format=>:load_from_solr})
#       test_object3_from_solr.testing_inbound({:response_format=>:load_from_solr})
#       test_object2_from_solr.testing
#       test_object3_from_solr.testing_inbound
#     end
#   
#     it 'when a load_from_solr is not set it should not call load_instance_from_solr for finders unless passing option in' do
#       @test_object2 = MockAFBaseFromSolr.new
#       @test_object2.save
#       @test_object3 = MockAFBaseFromSolr.new
#       @test_object3.save
#       @test_object2.testing_append(@test_object3)
#       @test_object2.save
#       
#       MockAFBaseFromSolr.expects(:load_instance_from_solr).never()
#       @test_object2.testing
#       @test_object3.testing_inbound
#       
#       #now try calling with option
#       MockAFBaseFromSolr.expects(:load_instance_from_solr).twice()
#       @test_object2.testing({:response_format=>:load_from_solr})
#       @test_object3.testing_inbound({:response_format=>:load_from_solr})
#       
#       #now call other finder method
#       MockAFBaseFromSolr.expects(:load_instance_from_solr).twice()
#       @test_object2.testing_from_solr
#       @test_object3.testing_inbound_from_solr
#       
#     end

end
