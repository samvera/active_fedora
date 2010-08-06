require File.join( File.dirname(__FILE__), "../spec_helper" )

class MockAFBaseRelationship < ActiveFedora::Base
  has_relationship "testing", :has_part, :type=>MockAFBaseRelationship
  has_relationship "testing2", :has_member, :type=>MockAFBaseRelationship
  has_relationship "testing_inbound", :has_part, :type=>MockAFBaseRelationship, :inbound=>true
  has_relationship "testing_inbound2", :has_member, :type=>MockAFBaseRelationship, :inbound=>true
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
  end
  
  
  it "calling constructor should create a new Fedora Object" do    
    @test_object.should have(0).errors
    @test_object.pid.should_not be_nil
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
      rexml = REXML::Document.new(@test_object.datastreams_in_fedora["RELS-EXT"].content)
      # Purpose: confirm that the isMemberOf entries exist and have real RDF in them
      rexml.root.elements["rdf:Description/hasModel"].attributes["rdf:resource"].should == 'info:fedora/afmodel:ActiveFedora_Base'
    end
    it "should merge attributes from fedora into attributes hash" do
      inner_object = @test_object2.inner_object
      inner_object.attributes.should == {:pid=>@test_object2.pid}
      @test_object2.save
      inner_object.attributes.should have_key(:state)
      inner_object.attributes.should have_key(:create_date)
      inner_object.attributes.should have_key(:modified_date)
      inner_object.attributes.should have_key(:owner_id)
      inner_object.state.should == "A"
      inner_object.owner_id.should == "fedoraAdmin"
    end
  end
  
  describe "#load_instance" do
    it "should return an object loaded from fedora" do
      result = ActiveFedora::Base.load_instance(@test_object.pid)
      result.should be_instance_of(ActiveFedora::Base)
    end
  end
  
  describe ".datastreams_in_fedora" do
    it "should return a Hash of datastreams from fedora" do
      datastreams = @test_object.datastreams_in_fedora
      datastreams.should be_an_instance_of(Hash) 
      datastreams.each_value do |ds| 
        ds.should be_a_kind_of(ActiveFedora::Datastream)
      end
      @test_object.datastreams_in_fedora["DC"].should be_an_instance_of(ActiveFedora::Datastream)
      datastreams["DC"].should_not be_nil
      datastreams["DC"].should be_an_instance_of(ActiveFedora::Datastream)       
    end
    it "should initialize the datastream pointers with @new_object=false" do
      datastreams = @test_object.datastreams_in_fedora
      datastreams.each_value do |ds| 
        ds.new_object?.should be_false
      end
    end
  end
  
  describe ".metadata_streams" do
    it "should return all of the datastreams from the object that are kinds of MetadataDatastreams " do
      mds1 = ActiveFedora::MetadataDatastream.new(:dsid => "md1")
      mds2 = ActiveFedora::QualifiedDublinCoreDatastream.new(:dsid => "qdc")
      fds = ActiveFedora::Datastream.new(:dsid => "fds")
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
      fds1 = ActiveFedora::Datastream.new(:dsid => "fds1")
      fds2 = ActiveFedora::Datastream.new(:dsid => "fds2")
      mds = ActiveFedora::MetadataDatastream.new(:dsid => "mds")
      @test_object.add_datastream(fds1)  
      @test_object.add_datastream(fds2)
      @test_object.add_datastream(mds)    
      
      result = @test_object.file_streams
      result.length.should == 2
      result.should include(fds1)
      result.should include(fds2)
    end
    it "should skip DC and RELS-EXT datastreams" do
      fds1 = ActiveFedora::Datastream.new(:dsid => "fds1")
      dc = ActiveFedora::Datastream.new(:dsid => "DC")
      rels_ext = ActiveFedora::RelsExtDatastream.new
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
      test_object.datastreams["RELS-EXT"].should == nil
      test_object.rels_ext
      test_object.datastreams_in_memory["RELS-EXT"].should_not == nil
      test_object.datastreams_in_memory["RELS-EXT"].class.should == ActiveFedora::RelsExtDatastream
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
      rexml = REXML::Document.new(@test_object.datastreams_in_fedora["RELS-EXT"].content)
      # Purpose: confirm that the isMemberOf entries exist and have real RDF in them
      rexml.root.elements["rdf:Description/isMemberOf[@rdf:resource='info:fedora/demo:5']"].attributes["xmlns"].should == 'info:fedora/fedora-system:def/relations-external#'
      rexml.root.elements["rdf:Description/isMemberOf[@rdf:resource='info:fedora/demo:10']"].attributes["xmlns"].should == 'info:fedora/fedora-system:def/relations-external#'
    end
  end
  
  describe '.add_datastream' do
  
    it "should be able to add datastreams" do
      ds = ActiveFedora::Datastream.new(:dsID => 'DS1', :dsLabel => 'hello', :altIDs => '3333', 
        :controlGroup => 'M', :blob => fixture('dino.jpg'))
      @test_object.add_datastream(ds).should be_true
    end
      
    it "adding and saving should add the datastream to the datastreams_in_fedora array" do
      ds = ActiveFedora::Datastream.new(:dsid => 'DS1', :dsLabel => 'hello', :altIDs => '3333', 
        :controlGroup => 'M', :blob => fixture('dino.jpg'))
      @test_object.datastreams.should_not have_key("DS1")
      @test_object.add_datastream(ds)
      ds.save
      @test_object.datastreams_in_fedora.should have_key("DS1")
    end
    
  end
  
  it "should retrieve blobs that match the saved blobs" do
    ds = ActiveFedora::Datastream.new(:dsid => 'DS1', :dsLabel => 'hello', :altIDs => '3333', 
      :controlGroup => 'M', :blob => fixture('dino.jpg'))
    @test_object.add_datastream(ds)
    ds.save
    @test_object.datastreams_in_fedora["DS1"].content.should == ds.content
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
        @test_object2.new_object = true
        @test_object2.save
        @test_object3 = MockAFBaseRelationship.new
        @test_object3.new_object = true
        @test_object3.save
        @test_object4 = MockAFBaseRelationship.new
        @test_object4.new_object = true
        @test_object4.save
        @test_object5 = MockAFBaseRelationship.new
        @test_object5.new_object = true
        @test_object5.save
        #append to named relationship 'testing'
        @test_object2.add_named_relationship("testing",@test_object3)
        @test_object2.add_named_relationship("testing2",@test_object4)
        @test_object5.add_named_relationship("testing",@test_object2)
        @test_object5.add_named_relationship("testing2",@test_object3)
        @test_object2.save
        @test_object5.save
        r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
        r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
        r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
        r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
        model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
        #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
        @test_object2.named_relationships(false).should == {:self=>{"testing"=>[r3.object],
                                                              "testing2"=>[r4.object]},
                                                            :inbound=>{"testing_inbound"=>[r5.object],"testing_inbound2"=>[]}}
        @test_object3.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                           :inbound=>{"testing_inbound"=>[r2.object],
                                                                      "testing_inbound2"=>[r5.object]}}
        @test_object4.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                            :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[r2.object]}}
        @test_object5.named_relationships(false).should == {:self=>{"testing"=>[r2.object],
                                                                    "testing2"=>[r3.object]},
                                                            :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[]}}
        @test_object2.delete
        #need to reload since removed from rels_ext in memory
        @test_object5 = MockAFBaseRelationship.load_instance(@test_object5.pid)
      
        #check any test_object2 inbound rels gone from source
        @test_object3.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                            :inbound=>{"testing_inbound"=>[],
                                                                       "testing_inbound2"=>[r5.object]}}
        @test_object4.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                            :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[]}}
        @test_object5.named_relationships(false).should == {:self=>{"testing"=>[],
                                                                  "testing2"=>[r3.object]},
                                                            :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[]}}
   
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
      @test_object.relationships.should == {:self=>{:has_model=>[model_rel.object],
                                                    :has_part=>[r.object]}}
      @test_object.remove_relationship(:has_part,@test_object2)
      @test_object.save
      @test_object = ActiveFedora::Base.load_instance(@pid)
      @test_object.relationships.should == {:self=>{:has_model=>[model_rel.object]}}
    end
  end

  describe '#relationships' do
    it 'should return internal relationships with no parameters and include inbound if false passed in' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.new_object = true
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
      @test_object2.relationships(false).should == {:self=>{:has_model=>[model_rel.object],
                                                            :has_part=>[r3.object],
                                                            :has_member=>[r4.object]},
                                                    :inbound=>{:has_part=>[r5.object]}}
      @test_object3.relationships(false).should == {:self=>{:has_model=>[model_rel.object]},
                                                    :inbound=>{:has_part=>[r2.object],
                                                               :has_member=>[r5.object]}}
      @test_object4.relationships(false).should == {:self=>{:has_model=>[model_rel.object]},
                                                    :inbound=>{:has_member=>[r2.object]}}
      @test_object5.relationships(false).should == {:self=>{:has_model=>[model_rel.object],
                                                            :has_part=>[r2.object],
                                                            :has_member=>[r3.object]},
                                                    :inbound=>{}}
      #all inbound should now be empty if no parameter supplied to relationships
      @test_object2.relationships.should == {:self=>{:has_model=>[model_rel.object],
                                                            :has_part=>[r3.object],
                                                            :has_member=>[r4.object]}}
      @test_object3.relationships.should == {:self=>{:has_model=>[model_rel.object]}}
      @test_object4.relationships.should == {:self=>{:has_model=>[model_rel.object]}}
      @test_object5.relationships.should == {:self=>{:has_model=>[model_rel.object],
                                                            :has_part=>[r2.object],
                                                            :has_member=>[r3.object]}}
    end
  end
  
  describe '#inbound_relationships' do
    it 'should return a hash of inbound relationships' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.new_object = true
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
      @test_object2.inbound_relationships.should == {:has_part=>[r5.object]}
      @test_object3.inbound_relationships.should == {:has_part=>[r2.object],:has_member=>[r5.object]}
      @test_object4.inbound_relationships.should == {:has_member=>[r2.object]}
      @test_object5.inbound_relationships.should == {}
    end
  end
  
  describe '#named_inbound_relationships' do
    it 'should return a hash of inbound relationship names to array of objects' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.new_object = true
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
      @test_object2.named_inbound_relationships.should == {"testing_inbound"=>[r5.object],"testing_inbound2"=>[]}
      @test_object3.named_inbound_relationships.should == {"testing_inbound"=>[r2.object],"testing_inbound2"=>[r5.object]}
      @test_object4.named_inbound_relationships.should == {"testing_inbound"=>[],"testing_inbound2"=>[r2.object]}
      @test_object5.named_inbound_relationships.should == {"testing_inbound"=>[],"testing_inbound2"=>[]}
    end
  end
  
  describe '#named_relationships' do
    it '' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.new_object = true
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
      @test_object2.named_relationships(false).should == {:self=>{"testing"=>[r3.object],
                                                            "testing2"=>[r4.object]},
                                                    :inbound=>{"testing_inbound"=>[r5.object],"testing_inbound2"=>[]}}
      @test_object3.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[r2.object],
                                                               "testing_inbound2"=>[r5.object]}}
      @test_object4.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[r2.object]}}
      @test_object5.named_relationships(false).should == {:self=>{"testing"=>[r2.object],
                                                                  "testing2"=>[r3.object]},
                                                          :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[]}}
      #all inbound should now be empty if no parameter supplied to relationships
      @test_object2.named_relationships.should == {:self=>{"testing"=>[r3.object],
                                                            "testing2"=>[r4.object]}}
      @test_object3.named_relationships.should == {:self=>{"testing"=>[],"testing2"=>[]}}
      @test_object4.named_relationships.should == {:self=>{"testing"=>[],"testing2"=>[]}}
      @test_object5.named_relationships.should == {:self=>{"testing"=>[r2.object],
                                                           "testing2"=>[r3.object]}}
    end
  end
  
  describe '#add_named_relationship' do
    it 'should add a named relationship to an object' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.add_named_relationship("testing",@test_object3)
      @test_object2.add_named_relationship("testing2",@test_object4)
      @test_object5.add_named_relationship("testing",@test_object2)
      @test_object5.add_named_relationship("testing2",@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      @test_object2.named_relationships(false).should == {:self=>{"testing"=>[r3.object],
                                                            "testing2"=>[r4.object]},
                                                    :inbound=>{"testing_inbound"=>[r5.object],"testing_inbound2"=>[]}}
      @test_object3.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[r2.object],
                                                               "testing_inbound2"=>[r5.object]}}
      @test_object4.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[r2.object]}}
      @test_object5.named_relationships(false).should == {:self=>{"testing"=>[r2.object],
                                                                  "testing2"=>[r3.object]},
                                                          :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[]}}
    end
  end
  
  describe '#remove_named_relationship' do
    it 'should remove an existing relationship from an object' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.add_named_relationship("testing",@test_object3)
      @test_object2.add_named_relationship("testing2",@test_object4)
      @test_object5.add_named_relationship("testing",@test_object2)
      @test_object5.add_named_relationship("testing2",@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      @test_object2.named_relationships(false).should == {:self=>{"testing"=>[r3.object],
                                                            "testing2"=>[r4.object]},
                                                    :inbound=>{"testing_inbound"=>[r5.object],"testing_inbound2"=>[]}}
      @test_object3.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[r2.object],
                                                               "testing_inbound2"=>[r5.object]}}
      @test_object4.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[r2.object]}}
      @test_object5.named_relationships(false).should == {:self=>{"testing"=>[r2.object],
                                                                  "testing2"=>[r3.object]},
                                                          :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[]}}
      @test_object2.remove_named_relationship("testing",@test_object3)
      @test_object2.save
      #check now removed for both outbound and inbound
      @test_object2.named_relationships(false).should == {:self=>{"testing"=>[],
                                                            "testing2"=>[r4.object]},
                                                    :inbound=>{"testing_inbound"=>[r5.object],"testing_inbound2"=>[]}}
      @test_object3.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[],
                                                               "testing_inbound2"=>[r5.object]}}
      @test_object4.named_relationships(false).should == {:self=>{"testing"=>[],"testing2"=>[]},
                                                    :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[r2.object]}}
      @test_object5.named_relationships(false).should == {:self=>{"testing"=>[r2.object],
                                                                  "testing2"=>[r3.object]},
                                                          :inbound=>{"testing_inbound"=>[],"testing_inbound2"=>[]}}
   
    end
  end

  describe '#named_relationship' do
    it 'should find relationships based on name passed in for inbound or outbound' do
      @test_object2 = MockAFBaseRelationship.new
      @test_object2.new_object = true
      @test_object2.save
      @test_object3 = MockAFBaseRelationship.new
      @test_object3.new_object = true
      @test_object3.save
      @test_object4 = MockAFBaseRelationship.new
      @test_object4.new_object = true
      @test_object4.save
      @test_object5 = MockAFBaseRelationship.new
      @test_object5.new_object = true
      @test_object5.save
      #append to named relationship 'testing'
      @test_object2.add_named_relationship("testing",@test_object3)
      @test_object2.add_named_relationship("testing2",@test_object4)
      @test_object5.add_named_relationship("testing",@test_object2)
      @test_object5.add_named_relationship("testing2",@test_object3)
      @test_object2.save
      @test_object5.save
      r2 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object2)
      r3 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      r4 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object4)
      r5 = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object5)
      model_rel = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>ActiveFedora::ContentModel.pid_from_ruby_class(MockAFBaseRelationship))
      @test_object2.named_relationship("testing").should == [r3.object]
      @test_object2.named_relationship("testing2").should == [r4.object]
      @test_object2.named_relationship("testing_inbound").should == [r5.object]
      @test_object2.named_relationship("testing_inbound2").should == []
      @test_object3.named_relationship("testing").should == []
      @test_object3.named_relationship("testing2").should == []
      @test_object3.named_relationship("testing_inbound").should == [r2.object]
      @test_object3.named_relationship("testing_inbound2").should == [r5.object]
      @test_object4.named_relationship("testing").should == []
      @test_object4.named_relationship("testing2").should == []
      @test_object4.named_relationship("testing_inbound").should == []
      @test_object4.named_relationship("testing_inbound2").should == [r2.object]
      @test_object5.named_relationship("testing").should == [r2.object]
      @test_object5.named_relationship("testing2").should == [r3.object]
      @test_object5.named_relationship("testing_inbound").should == []
      @test_object5.named_relationship("testing_inbound2").should == []
      
    end
  end

end
