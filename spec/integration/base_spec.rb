require 'spec_helper'

describe "A base object with metadata" do
  before :all do
    class MockAFBaseRelationship < ActiveFedora::Base
      has_metadata 'foo', type: Hydra::ModsArticleDatastream 
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
      obj.foo.should_not be_new_record
      obj.foo.person.should == ['bob']
      person_field = ActiveFedora::SolrService.solr_name('foo__person', type: :string)
      solr_result = ActiveFedora::SolrService.query("{!raw f=id}#{@obj.pid}", :fl=>"id #{person_field}").first
      expect(solr_result).to eq("id"=>@obj.pid, person_field =>['bob'])
    end
  end

  describe "that already exists in the repo" do
    before do
      @release = MockAFBaseRelationship.create()
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
        person_field = ActiveFedora::SolrService.solr_name('foo__person', type: :string)
        ActiveFedora::SolrService.query("id:\"#{@release.pid}\"", :fl=>"id #{person_field}").first.should == {"id"=>@release.pid, person_field =>['frank']}
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
      # @object.logger.stub(:error)
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
    @nc = DSTest.create
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
    
    it "should set the CMA hasModel relationship" do 
      @test_object2.save
      pending "@test_object2 should have assertion hasModel is 'http://fedora.info/definitions/v4/model#ActiveFedora_Base'"
    end

    it 'when the object is updated, it also updates modification time field in solr' do
      @test_object2.save

      # Make sure the modification time changes by at least 1 second
      sleep 1

      @test_object2.save
      @test_object2.reload

      pid = @test_object2.pid.sub(':', '\:')
      solr_doc = ActiveFedora::SolrService.query("id:\"#{pid}\"")

      new_time_fedora = Time.parse(@test_object2.modified_date).to_i
      new_time_solr = Time.parse(solr_doc.first['system_modified_dtsi']).to_i
      new_time_solr.should == new_time_fedora
    end
  end
  
  describe ".datastreams" do
    it "should return a Hash of datastreams from fedora" do
      datastreams = @test_object.datastreams
      datastreams.should be_a_kind_of(Hash) 
      datastreams.should be_empty
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
      mds1 = ActiveFedora::SimpleDatastream.new(@test_object, "md1")
      mds2 = ActiveFedora::QualifiedDublinCoreDatastream.new(@test_object, "qdc")
      fds = ActiveFedora::Datastream.new(@test_object, "fds")
      @test_object.add_datastream(mds1)
      @test_object.add_datastream(mds2)
      @test_object.add_datastream(fds)      
      
      result = @test_object.metadata_streams
      result.length.should == 2
      result.should include(mds1)
      result.should include(mds2)
    end
  end
  
  describe '.add_file_datastream' do
   it "should set the correct mime_type if :mime_type is passed in and path does not contain correct extension" do
     @test_object = ActiveFedora::Base.new
     f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
     @test_object.add_file_datastream(f, mime_type: "image/jpeg")
     @test_object.save
     test_obj = ActiveFedora::Base.find(@test_object.pid)
     test_obj.datastreams["DS1"].mime_type.should == "image/jpeg"
   end
  end
  
  describe '.add_datastream' do
  
    it "should be able to add datastreams" do
      ds = ActiveFedora::Datastream.new(@test_object, 'DS1')
      @test_object.add_datastream(ds).should be_true
    end
      
    it "adding and saving should add the datastream to the datastreams array" do
      ds = ActiveFedora::Datastream.new(@test_object, 'DS1') 
      ds.content = fixture('dino.jpg').read
      @test_object.datastreams.should_not have_key("DS1")
      @test_object.add_datastream(ds)
      ds.save
      @test_object.datastreams.should have_key("DS1")
    end
    
  end
  
  it "should retrieve blobs that match the saved blobs" do
    ds = ActiveFedora::Datastream.new(@test_object, 'DS1')
    ds.content = "foo"
    ds.save
    @test_object.add_datastream(ds)
    expect(@test_object.class.find(@test_object.pid).datastreams["DS1"].content).to eq "foo" 
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

  describe "#exists?" do
    let(:obj) { ActiveFedora::Base.create } 
    it "should return true for objects that exist" do
      expect(ActiveFedora::Base.exists?(obj)).to be true
    end
    it "should return true for pids that exist" do
      expect(ActiveFedora::Base.exists?(obj.pid)).to be true
    end
    it "should return false for pids that don't exist" do
      expect(ActiveFedora::Base.exists?('test:missing_object')).to be false
    end
    it "should return false for nil" do
      expect(ActiveFedora::Base.exists?(nil)).to be false
    end
    it "should return false for false" do
      expect(ActiveFedora::Base.exists?(false)).to be false
    end
    it "should return false for empty" do
      expect(ActiveFedora::Base.exists?('')).to be false
    end
    context "when passed a hash of conditions" do
      let(:conditions) { {foo: "bar"} }
      context "and at least one object matches the conditions" do
        it "should return true" do
          allow(ActiveFedora::SolrService).to receive(:query) { [double("solr document")] }
          expect(ActiveFedora::Base.exists?(conditions)).to be true
        end
      end
      context "and no object matches the conditions" do
        it "should return false" do
          allow(ActiveFedora::SolrService).to receive(:query) { [] }
          expect(ActiveFedora::Base.exists?(conditions)).to be false
        end
      end
    end
  end
end
