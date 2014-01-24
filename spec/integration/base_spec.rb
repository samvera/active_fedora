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
      obj = ActiveFedora::Base.find(@obj.pid)
      obj.foo.should_not be_new
      obj.foo.person.should == ['bob']
      person_field = ActiveFedora::SolrService.solr_name('person', type: :string)
      solr_result = ActiveFedora::SolrService.query("{!raw f=id}#{@obj.pid}", :fl=>"id #{person_field}").first
      expect(solr_result).to eq("id"=>@obj.pid, person_field =>['bob'])
    end
  end

  describe "setting object state" do
    it "should store it" do
      obj = MockAFBaseRelationship.create
      obj.state='D'
      obj.save!
      obj.reload
      obj.state.should == 'D'
    end
  end

  describe "that already exists in the repo" do
    before do
      @release = MockAFBaseRelationship.create()
      @release.add_relationship(:is_governed_by, 'info:fedora/test:catalog-fixture')
      @release.add_relationship(:is_part_of, 'info:fedora/test:777')
      @release.foo.person = "test foo content"
      @release.save
    end
    describe "and has been changed" do
      before do
        @release.foo.person = 'frank'
        @release.save!
      end
      it "should save the datastream." do
        MockAFBaseRelationship.find(@release.pid).foo.person.should == ['frank']
        person_field = ActiveFedora::SolrService.solr_name('person', type: :string)
        ActiveFedora::SolrService.query("id:#{@release.pid.gsub(":", "\\:")}", :fl=>"id #{person_field}").first.should == {"id"=>@release.pid, person_field =>['frank']}
      end
    end
    describe "clone_into a new object" do
      before do
        begin
          new_object = MockAFBaseRelationship.find('test:999')
          new_object.delete
        rescue ActiveFedora::ObjectNotFoundError
        end
        
        new_object = MockAFBaseRelationship.create(:pid => 'test:999')
        @release.clone_into(new_object)
        @new_object = MockAFBaseRelationship.find('test:999')
      end
      it "should have all the assertions" do
        @new_object.rels_ext.content.should be_equivalent_to '<rdf:RDF xmlns:ns1="info:fedora/fedora-system:def/model#" xmlns:ns2="info:fedora/fedora-system:def/relations-external#" xmlns:ns0="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
         <rdf:Description rdf:about="info:fedora/test:999">
           <ns0:isGovernedBy rdf:resource="info:fedora/test:catalog-fixture"/>
           <ns1:hasModel rdf:resource="info:fedora/afmodel:MockAFBaseRelationship"/>
           <ns2:isPartOf rdf:resource="info:fedora/test:777"/>

         </rdf:Description>
       </rdf:RDF>'
      end
      it "should have the other datastreams too" do
        @new_object.datastreams.keys.should include "foo"
        @new_object.foo.content.should be_equivalent_to @release.foo.content
      end
    end
    describe "clone" do
      before do
        @new_object = @release.clone
      end
      it "should have all the assertions" do
        @new_object.rels_ext.content.should be_equivalent_to '<rdf:RDF xmlns:ns1="info:fedora/fedora-system:def/model#" xmlns:ns2="info:fedora/fedora-system:def/relations-external#" xmlns:ns0="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
         <rdf:Description rdf:about="info:fedora/'+ @new_object.pid+'">
           <ns0:isGovernedBy rdf:resource="info:fedora/test:catalog-fixture"/>
           <ns1:hasModel rdf:resource="info:fedora/afmodel:MockAFBaseRelationship"/>
           <ns2:isPartOf rdf:resource="info:fedora/test:777"/>

         </rdf:Description>
       </rdf:RDF>'
      end
      it "should have the other datastreams too" do
        @new_object.datastreams.keys.should include "foo"
        @new_object.foo.content.should be_equivalent_to @release.foo.content
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
      @object.foo.person.should == ['dave']
    end
    it 'should raise an error if not persisted' do
      @object = MockAFBaseRelationship.new
      # You will want this stub or else it will be really chatty in your STDERR
      @object.inner_object.logger.stub(:error)
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
    @nc.test_ds.content.should == 'XXX'
    ds  = @nc.datastreams['test_ds']
    ds.content = "Foobar"
    @nc.save
    DSTest.find(@nc.pid).datastreams['test_ds'].content.should == 'Foobar'
    DSTest.find(@nc.pid).test_ds.content.should == 'Foobar'
  end

end




describe ActiveFedora::Base do
  before :all do
    class MockAFBaseRelationship < ActiveFedora::Base
    end

    class MockAFBaseFromSolr < ActiveFedora::Base
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
      @test_object.should have(0).errors
      @test_object.pid.should_not be_nil
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
      @test_object2.pid.match('randomNamespace:\d+').to_a.first.should == @test_object2.pid
    end

    it "should set the CMA hasModel relationship in the Rels-EXT" do 
      @test_object2.save
      rexml = REXML::Document.new(@test_object2.datastreams["RELS-EXT"].content)
      # Purpose: confirm that the isMemberOf entries exist and have real RDF in them
      rexml.root.elements["rdf:Description/ns0:hasModel"].attributes["rdf:resource"].should == 'info:fedora/afmodel:ActiveFedora_Base'
    end
    it "should merge attributes from fedora into attributes hash" do
      @test_object2.save
      inner_object = @test_object2.inner_object
      inner_object.pid.should == @test_object2.pid
      inner_object.should respond_to(:lastModifiedDate)
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
        ds.should_not be_new
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
      result.length.should == 2
      result.should include(mds1)
      result.should include(mds2)
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
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:5")
      @test_object.add_relationship(:is_member_of, "info:fedora/demo:10")
      @test_object.add_relationship(:conforms_to, "info:fedora/afmodel:OralHistory")
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
     test_obj = ActiveFedora::Base.find(@test_object.pid)
     #check case where nothing passed in does not have correct mime type
     test_obj.datastreams["DS1"].mimeType.should == "application/octet-stream"
     @test_object2 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object2.add_file_datastream(f,{:mimeType=>"image/jpeg"})
     @test_object2.save
     test_obj = ActiveFedora::Base.find(@test_object2.pid)
     test_obj.datastreams["DS1"].mimeType.should == "image/jpeg"
     @test_object3 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object3.add_file_datastream(f,{:mime_type=>"image/jpeg"})
     @test_object3.save
     test_obj = ActiveFedora::Base.find(@test_object3.pid)
     test_obj.datastreams["DS1"].mimeType.should == "image/jpeg"
     @test_object4 = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object4.add_file_datastream(f,{:content_type=>"image/jpeg"})
     @test_object4.save
     test_obj = ActiveFedora::Base.find(@test_object4.pid)
     test_obj.datastreams["DS1"].mimeType.should == "image/jpeg"
   end
  end
  
  describe '.add_datastream' do
  
    it "should be able to add datastreams" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1')
      @test_object.add_datastream(ds).should be_true
    end
      
    it "adding and saving should add the datastream to the datastreams array" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'DS1') 
      ds.content = fixture('dino.jpg').read
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
      @test_object.save
      ActiveFedora::Base.find_with_conditions(:id=>@test_object.pid).first["id"].should == @test_object.pid
      pid = @test_object.pid # store so we can access it after deletion
      @test_object.delete
      ActiveFedora::Base.find_with_conditions(:id=>pid).should be_empty
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
      @test_object.object_relations[:has_part].should include @test_object2.internal_uri
      @test_object.remove_relationship(:has_part,@test_object2)
      @test_object.save
      @test_object = ActiveFedora::Base.find(@pid)
      @test_object.object_relations[:has_part].should be_empty
    end
  end

  
  describe "#exists?" do
    it "should return true for objects that exist" do
      @obj = ActiveFedora::Base.create
      ActiveFedora::Base.exists?(@obj.pid).should be_true
    end
    it "should return false for objects that don't exist" do
      ActiveFedora::Base.exists?('test:missing_object').should be_false
    end
    it "should return false for nil" do
      ActiveFedora::Base.exists?(nil).should be_false
    end
    it "should return false for empty" do
      ActiveFedora::Base.exists?('').should be_false
    end
  end
end
