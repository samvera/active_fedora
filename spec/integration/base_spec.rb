require 'spec_helper'

describe "A base object with metadata" do
  before :all do
    class MockAFBaseRelationship < ActiveFedora::Base
      has_metadata :name=>'foo', :type=>Hydra::ModsArticleDatastream
    end
  end
  after :all do
    Object.send(:remove_const, :MockAFBaseRelationship)
  end
  describe "a new document" do
    before do
      @obj = MockAFBaseRelationship.new

      @obj.foo.person = "bob"
      @obj.save
    end
    it "should save the datastream." do
      obj = ActiveFedora::Base.find(@obj.pid, :cast=>true)
      expect(obj.foo).not_to be_new
      expect(obj.foo.person).to eq(['bob'])
      person_field = ActiveFedora::SolrService.solr_name('person', :string, :searchable)
      expect(ActiveFedora::SolrService.query("id:#{@obj.pid.gsub(":", "\\:")}", :fl=>"id #{person_field}").first).to eq({"id"=>@obj.pid, person_field =>['bob']})
    end
  end

  describe "that already exists in the repo" do
    before do
      @release = MockAFBaseRelationship.create()
      @release.add_relationship(:is_governed_by, 'info:fedora/narmdemo:catalog-fixture')
      @release.add_relationship(:is_part_of, 'info:fedora/narmdemo:777')
      @release.foo.person = "test foo content"
      @release.save
    end
    describe "and has been changed" do
      before do
        @release.foo.person = 'frank'
        @release.save!
      end
      it "should save the datastream." do
        expect(MockAFBaseRelationship.find(@release.pid).foo.person).to eq(['frank'])
        person_field = ActiveFedora::SolrService.solr_name('person', :string, :searchable)
        expect(ActiveFedora::SolrService.query("id:#{@release.pid.gsub(":", "\\:")}", :fl=>"id #{person_field}").first).to eq({"id"=>@release.pid, person_field =>['frank']})
      end
    end
    describe "clone_into a new object" do
      before do
        begin
          new_object = MockAFBaseRelationship.find('narm:999')
          new_object.delete
        rescue ActiveFedora::ObjectNotFoundError
        end

        new_object = MockAFBaseRelationship.create(:pid => 'narm:999')
        @release.clone_into(new_object)
        @new_object = MockAFBaseRelationship.find('narm:999')
      end
      it "should have all the assertions" do
        expect(@new_object.rels_ext.content).to be_equivalent_to '<rdf:RDF xmlns:ns1="info:fedora/fedora-system:def/model#" xmlns:ns2="info:fedora/fedora-system:def/relations-external#" xmlns:ns0="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
         <rdf:Description rdf:about="info:fedora/narm:999">
           <ns0:isGovernedBy rdf:resource="info:fedora/narmdemo:catalog-fixture"/>
           <ns1:hasModel rdf:resource="info:fedora/afmodel:MockAFBaseRelationship"/>
           <ns2:isPartOf rdf:resource="info:fedora/narmdemo:777"/>

         </rdf:Description>
       </rdf:RDF>'
      end
      it "should have the other datastreams too" do
        expect(@new_object.datastreams.keys).to include "foo"
        expect(@new_object.foo.content).to be_equivalent_to @release.foo.content
      end
    end
    describe "clone" do
      before do
        @new_object = @release.clone
      end
      it "should have all the assertions" do
        expect(@new_object.rels_ext.content).to be_equivalent_to '<rdf:RDF xmlns:ns1="info:fedora/fedora-system:def/model#" xmlns:ns2="info:fedora/fedora-system:def/relations-external#" xmlns:ns0="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
         <rdf:Description rdf:about="info:fedora/'+ @new_object.pid+'">
           <ns0:isGovernedBy rdf:resource="info:fedora/narmdemo:catalog-fixture"/>
           <ns1:hasModel rdf:resource="info:fedora/afmodel:MockAFBaseRelationship"/>
           <ns2:isPartOf rdf:resource="info:fedora/narmdemo:777"/>

         </rdf:Description>
       </rdf:RDF>'
      end
      it "should have the other datastreams too" do
        expect(@new_object.datastreams.keys).to include "foo"
        expect(@new_object.foo.content).to be_equivalent_to @release.foo.content
      end
    end
  end

  describe '#reload' do
    before(:each) do
      @object = MockAFBaseRelationship.new
      @object.foo.person = 'bob'
      @object.save

      @object2 = @object.class.find(@object.pid)

      @object2.foo.person = 'dave'
      @object2.save
    end
    it 'should requery Fedora' do
      @object.reload
      expect(@object.foo.person).to eq(['dave'])
    end
    it 'should raise an error if not persisted' do
      @object = MockAFBaseRelationship.new
      # You will want this stub or else it will be really chatty in your STDERR
      allow(@object.inner_object.logger).to receive(:error)
      expect {
        @object.reload
      }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end
  end
end

describe "Datastreams synched together" do
  before do
    class DSTest < ActiveFedora::Base
      def load_datastreams
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
    expect(@nc.test_ds.content).to eq('XXX')
    ds  = @nc.datastreams['test_ds']
    ds.content = "Foobar"
    @nc.save
    expect(DSTest.find(@nc.pid).datastreams['test_ds'].content).to eq('Foobar')
    expect(DSTest.find(@nc.pid).test_ds.content).to eq('Foobar')
  end

end




describe ActiveFedora::Base do
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

  before :all do
    class MockAFBaseRelationship < ActiveFedora::Base
      include ActiveFedora::FileManagement
      has_relationship "testing", :has_part, :type=>MockAFBaseRelationship
      has_relationship "testing2", :has_member, :type=>MockAFBaseRelationship
      has_relationship "testing_inbound", :has_part, :type=>MockAFBaseRelationship, :inbound=>true
      has_relationship "testing_inbound2", :has_member, :type=>MockAFBaseRelationship, :inbound=>true
      has_bidirectional_relationship "testing_bidirectional", :has_collection_member, :is_member_of_collection
      #next 2 used to test objects on opposite end of bidirectional relationship
      has_relationship "testing_inbound3", :has_collection_member, :inbound=>true
      has_relationship "testing3", :is_member_of_collection
    end

    class MockAFBaseFromSolr < ActiveFedora::Base
      include ActiveFedora::Relationships
      has_relationship "testing", :has_part, :type=>MockAFBaseFromSolr
      has_relationship "testing2", :has_member, :type=>MockAFBaseFromSolr
      has_relationship "testing_inbound", :has_part, :type=>MockAFBaseFromSolr, :inbound=>true
      has_relationship "testing_inbound2", :has_member, :type=>MockAFBaseFromSolr, :inbound=>true

      has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
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
  end

  before(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end

  after :all do
    Object.send(:remove_const, :MockAFBaseRelationship)
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
      expect(@test_object.errors.size).to eq(0)
      expect(@test_object.pid).not_to be_nil
    end
  end

  describe '.assign_pid' do
    it "should get nextid" do
      one = ActiveFedora::Base.assign_pid(ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'changeme'))
      two = ActiveFedora::Base.assign_pid(ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'changeme'))
      one = one.gsub('changeme:', '').to_i
      two = two.gsub('changeme:', '').to_i
      expect(two).to eq(one + 1)
    end
  end

  describe "#save" do
    before(:each) do
      @test_object2 = ActiveFedora::Base.new
    end

    after(:each) do
      @test_object2.delete
    end

    it "passing namespace to constructor with no pid should generate a pid with the supplied namespace" do
      @test_object2 = ActiveFedora::Base.new({:namespace=>"randomNamespace"})
      # will be nil if match failed, otherwise will equal pid
      @test_object2.save
      expect(@test_object2.pid.match('randomNamespace:\d+').to_a.first).to eq(@test_object2.pid)
    end

    it "should set the CMA hasModel relationship in the Rels-EXT" do
      @test_object2.save
      rexml = REXML::Document.new(@test_object2.datastreams["RELS-EXT"].content)
      # Purpose: confirm that the isMemberOf entries exist and have real RDF in them
      expect(rexml.root.elements["rdf:Description/ns0:hasModel"].attributes["rdf:resource"]).to eq('info:fedora/afmodel:ActiveFedora_Base')
    end
    it "should merge attributes from fedora into attributes hash" do
      @test_object2.save
      inner_object = @test_object2.inner_object
      expect(inner_object.pid).to eq(@test_object2.pid)
      expect(inner_object).to respond_to(:state)
      expect(inner_object).to respond_to(:lastModifiedDate)
      expect(inner_object).to respond_to(:ownerId)
      expect(inner_object.state).to eq("A")
      expect(inner_object.ownerId).to eq("fedoraAdmin")
    end
  end

  describe ".datastreams" do
    it "should return a Hash of datastreams from fedora" do
      datastreams = @test_object.datastreams
      expect(datastreams).to be_a_kind_of(Hash)
      datastreams.each_value do |ds|
        expect(ds).to be_a_kind_of(ActiveFedora::Datastream)
      end
      expect(@test_object.datastreams["DC"]).to be_an_instance_of(ActiveFedora::Datastream)
      expect(datastreams["DC"]).not_to be_nil
      expect(datastreams["DC"]).to be_an_instance_of(ActiveFedora::Datastream)
    end
    it "should initialize the datastream pointers with @new_object=false" do
      datastreams = @test_object.datastreams
      datastreams.each_value do |ds|
        expect(ds).not_to be_new
      end
    end
  end

  describe ".metadata_streams" do
    it "should return all of the datastreams from the object that are kinds of OmDatastream " do
      mds1 = ActiveFedora::SimpleDatastream.new(@test_object.inner_object, "md1")
      mds2 = ActiveFedora::QualifiedDublinCoreDatastream.new(@test_object.inner_object, "qdc")
      fds = ActiveFedora::Datastream.new(@test_object.inner_object, "fds")
      @test_object.add_datastream(mds1)
      @test_object.add_datastream(mds2)
      @test_object.add_datastream(fds)

      result = @test_object.metadata_streams
      expect(result.length).to eq(2)
      expect(result).to include(mds1)
      expect(result).to include(mds2)
    end
  end

  describe ".dc" do
    it "should expose the DC datastream" do
      dc = @test_object.dc
      expect(dc).to be_a_kind_of(ActiveFedora::Datastream)
      rexml = REXML::Document.new(dc.content)
      expect(rexml.root.elements["dc:identifier"].get_text).not_to be_nil
    end
  end


  describe '.rels_ext' do
    it "should retrieve RelsExtDatastream object via rels_ext method" do
      expect(@test_object.rels_ext).to be_instance_of(ActiveFedora::RelsExtDatastream)
    end

    it 'should create the RELS-EXT datastream if it doesnt exist' do
      test_object = ActiveFedora::Base.new
      #test_object.datastreams["RELS-EXT"].should == nil
      test_object.rels_ext
      expect(test_object.datastreams["RELS-EXT"]).not_to eq(nil)
      expect(test_object.datastreams["RELS-EXT"].class).to eq(ActiveFedora::RelsExtDatastream)
    end
  end

  describe '.add_relationship' do
    it "should update the RELS-EXT datastream and relationships should end up in Fedora when the object is saved" do
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:5")
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:10")
      @test_object.add_relationship(:conforms_to, "info:fedora/afmodel:OralHistory")
      @test_object.save
      rexml = REXML::Document.new(@test_object.datastreams["RELS-EXT"].content)
      # Purpose: confirm that the isMemberOf entries exist and have real RDF in them
      expect(rexml.root.attributes["xmlns:ns1"]).to eq('info:fedora/fedora-system:def/relations-external#')
      expect(rexml.root.elements["rdf:Description/ns1:isMemberOf[@rdf:resource='info:fedora/demo:5']"]).not_to be_nil
      expect(rexml.root.elements["rdf:Description/ns1:isMemberOf[@rdf:resource='info:fedora/demo:10']"]).not_to be_nil
    end
  end

  describe '.add_file_datastream' do

   it "should set the correct mimeType if :mime_type, :mimeType, or :content_type passed in and path does not contain correct extension" do
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object.add_file_datastream(f)
     @test_object.save
     test_obj = ActiveFedora::Base.find(@test_object.pid)
     #check case where nothing passed in does not have correct mime type
     expect(test_obj.datastreams["DS1"].mimeType).to eq("application/octet-stream")
     @test_object2 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object2.add_file_datastream(f,{:mimeType=>"image/jpeg"})
     @test_object2.save
     test_obj = ActiveFedora::Base.find(@test_object2.pid)
     expect(test_obj.datastreams["DS1"].mimeType).to eq("image/jpeg")
     @test_object3 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object3.add_file_datastream(f,{:mime_type=>"image/jpeg"})
     @test_object3.save
     test_obj = ActiveFedora::Base.find(@test_object3.pid)
     expect(test_obj.datastreams["DS1"].mimeType).to eq("image/jpeg")
     @test_object4 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object4.add_file_datastream(f,{:content_type=>"image/jpeg"})
     @test_object4.save
     test_obj = ActiveFedora::Base.find(@test_object4.pid)
     expect(test_obj.datastreams["DS1"].mimeType).to eq("image/jpeg")
   end
  end

  describe '.add_datastream' do

    it "should be able to add datastreams" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1')
      # ds = ActiveFedora::Datastream.new(:dsID => 'DS1', :dsLabel => 'hello', :altIDs => '3333',
      #   :controlGroup => 'M', :blob => fixture('dino.jpg'))
      expect(@test_object.add_datastream(ds)).to be_truthy
    end

    it "adding and saving should add the datastream to the datastreams array" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1')
      ds.content = fixture('dino.jpg').read
      # ds = ActiveFedora::Datastream.new(:dsid => 'DS1', :dsLabel => 'hello', :altIDs => '3333',
      #   :controlGroup => 'M', :blob => fixture('dino.jpg'))
      expect(@test_object.datastreams).not_to have_key("DS1")
      @test_object.add_datastream(ds)
      ds.save
      expect(@test_object.datastreams).to have_key("DS1")
    end

  end

  it "should retrieve blobs that match the saved blobs" do
    ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1')
    ds.content = "foo"
    new_ds = ds.save
    @test_object.add_datastream(new_ds)
    expect(@test_object.class.find(@test_object.pid).datastreams["DS1"].content).to eq(new_ds.content)
  end

  describe ".create_date" do
    it "should return W3C date" do
      expect(@test_object.create_date).not_to be_nil
    end
  end

  describe ".modified_date" do
    it "should return nil before saving and a W3C date after saving" do
      expect(@test_object.modified_date).not_to be_nil
    end
  end

  describe "delete" do

    it "should delete the object from Fedora and Solr" do
      @test_object.save
      expect(ActiveFedora::Base.find_with_conditions(:id=>@test_object.pid).first["id"]).to eq(@test_object.pid)
      pid = @test_object.pid # store so we can access it after deletion
      @test_object.delete
      expect(ActiveFedora::Base.find_with_conditions(:id=>pid)).to be_empty
    end

    describe '#delete' do
      before do
        @test_object2 = MockAFBaseRelationship.create
        @test_object3 = MockAFBaseRelationship.create
        @test_object4 = MockAFBaseRelationship.create
        @test_object5 = MockAFBaseRelationship.create
        allow(Deprecation).to receive(:warn)
        #append to relationship by 'testing'
        @test_object2.add_relationship_by_name("testing",@test_object3)
        @test_object2.add_relationship_by_name("testing2",@test_object4)
        @test_object5.add_relationship_by_name("testing",@test_object2)
        #@test_object5.add_relationship_by_name("testing2",@test_object3)
        @test_object2.save
        @test_object5.save
        #check that the inbound relationships on test_object3 and test_object4 were eliminated
        #testing goes to :has_part and testing2 goes to :has_member
        expect(@test_object2.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object5.internal_uri])
        expect(@test_object2.relationships_by_name(false)[:self]["parts_outbound"]).to eq([@test_object3.internal_uri])
        expect(@test_object2.relationships_by_name(false)[:self]["testing"]).to eq([@test_object3.internal_uri])

        expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object2.internal_uri])
        expect(@test_object4.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object2.internal_uri])

        expect(@test_object5.relationships_by_name(false)[:self]["testing"]).to eq([@test_object2.internal_uri])
    end

    it 'if inbound relationships exist should remove relationships from those inbound targets as well when deleting this object' do

        @test_object2.delete
        #need to reload since removed from rels_ext in memory
        @test_object5 = MockAFBaseRelationship.find(@test_object5.pid)

        #check any test_object2 inbound rels gone from source
        expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([])

        expect(@test_object4.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([])
        expect(@test_object5.relationships_by_name(false)[:self]["testing"]).to eq([])
    end
  end

  end

  describe '#remove_relationship' do
    it 'should remove a relationship from an object after a save' do
      @test_object2 = ActiveFedora::Base.new
      @test_object2.save
      @test_object.add_relationship(:has_part,@test_object2)
      @test_object.save
      @pid = @test_object.pid
      begin
        @test_object = ActiveFedora::Base.find(@pid)
      rescue => e
        puts "#{e.message}\n#{e.backtrace}"
        raise e
      end
      expect(@test_object.object_relations[:has_part]).to include @test_object2.internal_uri
      @test_object.remove_relationship(:has_part,@test_object2)
      @test_object.save
      @test_object = ActiveFedora::Base.find(@pid)
      expect(@test_object.object_relations[:has_part]).to be_empty
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
      model_rel = MockAFBaseRelationship.to_class_uri
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      expect(@test_object2.object_relations[:has_model]).to include model_rel
      expect(@test_object2.object_relations[:has_part]).to include @test_object3

      expect(@test_object2.object_relations[:has_member]).to include @test_object4
      expect(@test_object2.object_relations[:is_member_of_collection]).to include @test_object5
      expect(@test_object2.inbound_relationships).to eq({:has_part=>[@test_object5.internal_uri]})

      expect(@test_object3.object_relations[:has_model]).to include model_rel
      expect(@test_object3.inbound_relationships).to eq({:has_part=>[@test_object2.internal_uri],
                                                               :has_member=>[@test_object5.internal_uri]})
      expect(@test_object4.object_relations[:has_model]).to include model_rel
      expect(@test_object4.inbound_relationships).to eq({:has_member=>[@test_object2.internal_uri],:has_collection_member=>[@test_object5.internal_uri]})

      expect(@test_object5.object_relations[:has_model]).to include model_rel
      expect(@test_object5.object_relations[:has_part]).to include @test_object2
      expect(@test_object5.object_relations[:has_member]).to include @test_object3
      expect(@test_object5.object_relations[:has_collection_member]).to include @test_object4
      expect(@test_object5.inbound_relationships).to eq({:is_member_of_collection=>[@test_object2.internal_uri]})
    end
  end

  describe '#inbound_relationships' do
    it 'should return a hash of inbound relationships' do
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
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      #@test_object5.testing_bidirectional_append(@test_object4)
      @test_object2.save
      @test_object5.save
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      expect(@test_object2.inbound_relationships).to eq({:has_part=>[@test_object5.internal_uri]})
      expect(@test_object3.inbound_relationships).to eq({:has_part=>[@test_object2.internal_uri],:has_member=>[@test_object5.internal_uri]})
      expect(@test_object4.inbound_relationships).to eq({:has_member=>[@test_object2.internal_uri]})
      expect(@test_object5.inbound_relationships).to eq({})
    end
  end

  describe '#inbound_relationships_by_name' do
    it 'should return a hash of inbound relationship names to array of objects' do
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
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      @test_object2.save
      @test_object5.save
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      expect(@test_object2.inbound_relationships_by_name).to eq({"testing_inbound"=>[@test_object5.internal_uri],"testing_inbound2"=>[],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []})
      expect(@test_object3.inbound_relationships_by_name).to eq({"testing_inbound"=>[@test_object2.internal_uri],"testing_inbound2"=>[@test_object5.internal_uri],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []})
      expect(@test_object4.inbound_relationships_by_name).to eq({"testing_inbound"=>[],"testing_inbound2"=>[@test_object2.internal_uri],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []})
      expect(@test_object5.inbound_relationships_by_name).to eq({"testing_inbound"=>[],"testing_inbound2"=>[],
                                                           "testing_bidirectional_inbound"=>[],"testing_inbound3"=>[], "parts_inbound" => []})
    end
  end

  describe '#relationships_by_name' do
    it '' do
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
      @test_object5.testing_append(@test_object2)
      @test_object5.testing2_append(@test_object3)
      @test_object2.save
      @test_object5.save
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      expect(@test_object2.relationships_by_name(false)[:self]["testing"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:self]["testing2"]).to eq([@test_object4.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:self]["parts_outbound"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object5.internal_uri])

      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object2.internal_uri])
      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object5.internal_uri])

      expect(@test_object4.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object2.internal_uri])

      expect(@test_object5.relationships_by_name(false)[:self]["testing"]).to eq([@test_object2.internal_uri])
      expect(@test_object5.relationships_by_name(false)[:self]["testing2"]).to eq([@test_object3.internal_uri])
      expect(@test_object5.relationships_by_name(false)[:self]["parts_outbound"]).to eq([@test_object2.internal_uri])

      #all inbound should now be empty if no parameter supplied to relationships
      expect(@test_object2.relationships_by_name[:self]["testing"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name[:self]["testing2"]).to eq([@test_object4.internal_uri])
      expect(@test_object2.relationships_by_name[:self]["parts_outbound"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name).not_to have_key :inbound

      expect(@test_object3.relationships_by_name).not_to have_key :inbound
      expect(@test_object4.relationships_by_name).not_to have_key :inbound


      expect(@test_object5.relationships_by_name[:self]["testing"]).to eq([@test_object2.internal_uri])
      expect(@test_object5.relationships_by_name[:self]["testing2"]).to eq([@test_object3.internal_uri])
      expect(@test_object5.relationships_by_name[:self]["parts_outbound"]).to eq([@test_object2.internal_uri])
      expect(@test_object5.relationships_by_name).not_to have_key :inbound
      # @test_object2.relationships_by_name.should == {:self=>{"testing2"=>[@test_object4.internal_uri], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[@test_object3.internal_uri], "parts_outbound"=>[@test_object3.internal_uri], "testing_bidirectional_outbound"=>[]}}
      # @test_object3.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      # @test_object4.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[], "testing_bidirectional_outbound"=>[]}}
      # @test_object5.relationships_by_name.should == {:self=>{"testing2"=>[@test_object3.internal_uri], "collection_members"=>[], "testing3"=>[], "part_of"=>[], "testing"=>[@test_object2.internal_uri], "parts_outbound"=>[@test_object2.internal_uri], "testing_bidirectional_outbound"=>[]}}
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
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      expect(@test_object2.relationships_by_name(false)[:self]["testing"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:self]["testing2"]).to eq([@test_object4.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:self]["parts_outbound"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object5.internal_uri])

      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object2.internal_uri])
      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object5.internal_uri])

      expect(@test_object4.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object2.internal_uri])

      expect(@test_object5.relationships_by_name(false)[:self]["testing"]).to eq([@test_object2.internal_uri])
      expect(@test_object5.relationships_by_name(false)[:self]["testing2"]).to eq([@test_object3.internal_uri])
      expect(@test_object5.relationships_by_name(false)[:self]["parts_outbound"]).to eq([@test_object2.internal_uri])
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
      #check inbound correct, testing goes to :has_part and testing2 goes to :has_member
      expect(@test_object2.relationships_by_name(false)[:self]["testing"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:self]["testing2"]).to eq([@test_object4.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:self]["parts_outbound"]).to eq([@test_object3.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object5.internal_uri])

      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object2.internal_uri])
      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object5.internal_uri])

      expect(@test_object4.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object2.internal_uri])

      expect(@test_object5.relationships_by_name(false)[:self]["testing"]).to eq([@test_object2.internal_uri])
      expect(@test_object5.relationships_by_name(false)[:self]["testing2"]).to eq([@test_object3.internal_uri])
      expect(@test_object5.relationships_by_name(false)[:self]["parts_outbound"]).to eq([@test_object2.internal_uri])

      @test_object2.remove_relationship_by_name("testing",@test_object3.internal_uri)
      @test_object2.save
      #check now removed for both outbound and inbound
      expect(@test_object2.relationships_by_name(false)[:self]["testing"]).to eq([])
      expect(@test_object2.relationships_by_name(false)[:self]["testing2"]).to eq([@test_object4.internal_uri])
      expect(@test_object2.relationships_by_name(false)[:self]["parts_outbound"]).to eq([])
      expect(@test_object2.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([@test_object5.internal_uri])

      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound"]).to eq([])
      expect(@test_object3.relationships_by_name(false)[:inbound]["testing_inbound2"]).to eq([@test_object5.internal_uri])
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
      expect(@test_object2.find_relationship_by_name("testing")).to eq([@test_object3.internal_uri])
      expect(@test_object2.find_relationship_by_name("testing2")).to eq([@test_object4.internal_uri])
      expect(@test_object2.find_relationship_by_name("testing_inbound")).to eq([@test_object5.internal_uri])
      expect(@test_object2.find_relationship_by_name("testing_inbound2")).to eq([])
      expect(@test_object3.find_relationship_by_name("testing")).to eq([])
      expect(@test_object3.find_relationship_by_name("testing2")).to eq([])
      expect(@test_object3.find_relationship_by_name("testing_inbound")).to eq([@test_object2.internal_uri])
      expect(@test_object3.find_relationship_by_name("testing_inbound2")).to eq([@test_object5.internal_uri])
      expect(@test_object4.find_relationship_by_name("testing")).to eq([])
      expect(@test_object4.find_relationship_by_name("testing2")).to eq([])
      expect(@test_object4.find_relationship_by_name("testing_inbound")).to eq([])
      expect(@test_object4.find_relationship_by_name("testing_inbound2")).to eq([@test_object2.internal_uri])
      expect(@test_object5.find_relationship_by_name("testing")).to eq([@test_object2.internal_uri])
      expect(@test_object5.find_relationship_by_name("testing2")).to eq([@test_object3.internal_uri])
      expect(@test_object5.find_relationship_by_name("testing_inbound")).to eq([])
      expect(@test_object5.find_relationship_by_name("testing_inbound2")).to eq([])

    end
  end

  describe "#exists?" do
    it "should return true for objects that exist" do
      expect(ActiveFedora::Base.exists?('hydrangea:fixture_mods_article1')).to be_truthy
    end
    it "should return false for objects that dont exist" do
      expect(ActiveFedora::Base.exists?('nil:object')).to be_falsey
    end
  end
end
