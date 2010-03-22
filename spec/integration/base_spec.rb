require File.join( File.dirname(__FILE__), "../spec_helper" )

describe ActiveFedora::Base do
  
  before(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_object.save
  end
  
  after(:each) do
    @test_object.delete
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

end
