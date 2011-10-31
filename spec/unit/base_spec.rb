require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'active_fedora/base'
require 'active_fedora/metadata_datastream'
require 'time'
require 'date'
class FooHistory < ActiveFedora::Base
  has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
    m.field "fubar", :string
    m.field "swank", :text
  end
  has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText" do |m|
    m.field "fubar", :text
  end
  has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText2", :label=>"withLabel" do |m|
    m.field "fubar", :text
  end 
end

@@last_pid = 0  

describe ActiveFedora::Base do
  
  def increment_pid
    @@last_pid += 1    
  end

  before(:each) do
    @mock_repo = mock("repository")
    ActiveFedora::DigitalObject.any_instance.expects(:repository).returns(@mock_repo).at_least_once
    @this_pid = increment_pid.to_s
    @mock_repo.stubs(:datastream_dissemination)
    ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns(@this_pid)

    @mock_repo.expects(:datastream).with{ |x| x[:dsid] == 'RELS-EXT'}.returns("").at_least_once #raises(RuntimeError, "Fake Not found")
    @mock_repo.expects(:datastream).with{ |x| x[:dsid] == 'someData'}.returns("").at_least_once #raises(RuntimeError, "Fake Not found")
    @mock_repo.expects(:datastream).with{ |x| x[:dsid] == 'withText2'}.returns("").at_least_once #raises(RuntimeError, "Fake Not found")
    @mock_repo.expects(:datastream).with{ |x| x[:dsid] == 'withText'}.returns("").at_least_once #raises(RuntimeError, "Fake Not found")
    @test_object = ActiveFedora::Base.new
    @test_history = FooHistory.new
  end

  after(:each) do
    begin
    ActiveFedora::SolrService.stubs(:instance)
    @test_object.delete
    rescue
    end
  end

  describe '#new' do
    it "should create a new inner object" do
      Rubydora::DigitalObject.any_instance.expects(:save).never
      @mock_repo.expects(:datastreams).with(:pid => "test:1").returns("")

      result = ActiveFedora::Base.new(:pid=>"test:1")  
      result.inner_object.should be_kind_of(Rubydora::DigitalObject)    
    end

    it "should allow initialization with nil" do  
      # for doing AFObject.new(params[:foo]) when nothing is in params[:foo]
      Rubydora::DigitalObject.any_instance.expects(:save).never
      result = ActiveFedora::Base.new(nil)  
      result.inner_object.should be_kind_of(Rubydora::DigitalObject)    
    end

  end

  describe ".internal_uri" do
    it "should return pid as fedors uri" do
      @test_object.internal_uri.should eql("info:fedora/#{@test_object.pid}")
    end
  end

  ### Methods for ActiveModel::Conversions
  it "should have to_param once it's saved" do
    @mock_repo.expects(:object).raises(RuntimeError)
    @test_object.to_param.should be_nil
    @test_object.expects(:create).returns(true)
    @test_object.save
    @test_object.expects(:persisted?).returns(true).at_least_once
    @test_object.to_param.should == @test_object.pid
  end

  it "should have to_key once it's saved" do 
    @mock_repo.expects(:object).raises(RuntimeError)
    @test_object.to_key.should be_nil
    @test_object.expects(:create).returns(true)
    @test_object.save
    @test_object.expects(:persisted?).returns(true).at_least_once
    @test_object.to_key.should == [@test_object.pid]
  end

  it "should have to_model" do
    @test_object.to_model.should be @test_object
  end
  ### end ActiveModel::Conversions

  ### Methods for ActiveModel::Naming
  it "Should know the model_name" do
    FooHistory.model_name.should == 'FooHistory'
    FooHistory.model_name.human.should == 'Foo history'
  end
  ### End ActiveModel::Naming 
  
 

  it "should respond_to has_metadata" do
    ActiveFedora::Base.respond_to?(:has_metadata).should be_true
  end

  describe "has_metadata" do
    before :each do
      @mock_repo.expects(:datastreams).with(:pid => "monkey:99").returns("")
      @mock_repo.expects(:object).with(:pid => "monkey:99").raises(RuntimeError)
      @mock_repo.expects(:ingest).with(:pid => "monkey:99").returns("monkey:99")
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'someData'}
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'withText'}
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'withText2'}
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'RELS-EXT'}
      @mock_repo.expects(:datastream_dissemination).with(:pid => 'monkey:99', :dsid => 'RELS-EXT')

      @n = FooHistory.new(:pid=>"monkey:99")
      @n.expects(:update_index)
      @n.save
    end

    it "should create specified datastreams with specified fields" do
      @n.datastreams["someData"].should_not be_nil
      @n.datastreams["someData"].fubar_values='bar'
      @n.datastreams["someData"].fubar_values.should == ['bar']
      @n.datastreams["withText2"].dsLabel.should == "withLabel"
    end

  end



  describe ".fields" do
    it "should provide fields" do
      @test_object.should respond_to(:fields)
    end
    it "should add pid, system_create_date and system_modified_date from object attributes" do
      cdate = "2008-07-02T05:09:42.015Z"
      mdate = "2009-07-07T23:37:18.991Z"
      @test_object.expects(:create_date).returns(cdate)
      @test_object.expects(:modified_date).returns(mdate)
      fields = @test_object.fields
      fields[:system_create_date][:values].should eql([cdate])
      fields[:system_modified_date][:values].should eql([mdate])
      fields[:id][:values].should eql([@test_object.pid])
    end
    
    it "should add self.class as the :active_fedora_model" do
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      fields = @test_object.fields
      fields[:active_fedora_model][:values].should eql([@test_object.class.inspect])
    end
    
    it "should call .fields on all MetadataDatastreams and return the resulting document" do
      mock1 = mock("ds1", :fields => {})
      mock2 = mock("ds2", :fields => {})
      mock1.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      mock2.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)

      @test_object.expects(:datastreams).returns({:ds1 => mock1, :ds2 => mock2})
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      @test_object.fields
    end
  end

  it 'should provide #find' do
    ActiveFedora::Base.should respond_to(:find)
  end

  it "should provide .create_date" do
    @test_object.should respond_to(:create_date)
  end

  it "should provide .modified_date" do
    @test_object.should respond_to(:modified_date)
  end

  it 'should respond to .rels_ext' do
    @test_object.should respond_to(:rels_ext)
  end

  describe '.rels_ext' do

    it 'should return the RelsExtDatastream object from the datastreams array' do
      @test_object.expects(:datastreams).returns({"RELS-EXT" => "foo"}).at_least_once
      @test_object.rels_ext.should == "foo"
    end
  end

  it 'should provide #add_relationship' do
    @test_object.should respond_to(:add_relationship)
  end

  describe '#add_relationship' do
    it 'should call #add_relationship on the rels_ext datastream' do
      mock_rels_ext = mock("rels-ext")
      mock_rels_ext.expects(:dirty=).with(true)
      @test_object.expects(:relationship_exists?).returns(false).once()
      @test_object.expects(:rels_ext).returns(mock_rels_ext).at_least_once 
      @test_object.add_relationship("predicate", "object")
    end

    it "should update the RELS-EXT datastream and set the datastream as dirty when relationships are added" do
      mock_ds = mock("Rels-Ext")
      mock_ds.expects(:dirty=).with(true).times(2)
      @test_object.datastreams["RELS-EXT"] = mock_ds
      test_relationships = [ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:5"), 
        ActiveFedora::Relationship.new(:subject => :self, :predicate => :is_member_of, :object => "info:fedora/demo:10")]
      test_relationships.each do |rel|
        @test_object.add_relationship(rel.predicate, rel.object)
      end
    end
    
    it 'should add a relationship to an object only if it does not exist already' do
      ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns(increment_pid.to_s)
      @test_object3 = ActiveFedora::Base.new
      @test_object.add_relationship(:has_part,@test_object3)
      r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object3)
      @test_object.ids_for_outbound(:has_part).should == [@test_object3.pid]
      #try adding again and make sure not there twice
      @test_object.add_relationship(:has_part,@test_object3)
      @test_object.ids_for_outbound(:has_part).should == [@test_object3.pid]
    end

    it 'should add literal relationships if requested' do
      @test_object.add_relationship(:conforms_to,"AnInterface",true)
      @test_object.ids_for_outbound(:conforms_to).should == ["AnInterface"]
    end
  end
  
  it 'should provide #remove_relationship' do
    @test_object.should respond_to(:remove_relationship)
  end
  
  describe '#remove_relationship' do
    it 'should remove a relationship from the relationships hash' do
      ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns(increment_pid.to_s)
      @test_object3 = ActiveFedora::Base.new
      ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns(increment_pid.to_s)
      @test_object4 = ActiveFedora::Base.new
      @test_object.add_relationship(:has_part,@test_object3)
      @test_object.add_relationship(:has_part,@test_object4)
      #check both are there
      @test_object.ids_for_outbound(:has_part).should == [@test_object3.pid,@test_object4.pid]
      @test_object.remove_relationship(:has_part,@test_object3)
      #check only one item removed
      @test_object.ids_for_outbound(:has_part).should == [@test_object4.pid]
      @test_object.remove_relationship(:has_part,@test_object4)
      #check last item removed and predicate removed since now emtpy
      @test_object.relationships.size.should == 0
    end
  end

  it 'should provide #relationships' do
    @test_object.should respond_to(:relationships)
  end

  describe '#relationships' do
    it 'should return a graph' do
      @test_object.relationships.kind_of?(RDF::Graph).should be_true
      @test_object.relationships.size.should == 0 
    end
  end

  describe '.save' do
    
    
    it "should return true and set persisted if object and datastreams all save successfully" do
      @mock_repo.expects(:ingest).with(:pid => @this_pid).returns(@this_pid)
      @mock_repo.expects(:object).with(:pid => @this_pid).raises(RuntimeError)
      @mock_repo.expects(:datastreams).with(:pid => @this_pid).returns("")
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'RELS-EXT'}
      @test_object.persisted?.should be false 
      @test_object.expects(:update_index)
      @test_object.save.should == true
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("<objectProfile><objOwnerId>fedoraAdmin</objOwnerId></objectProfile>")
      @test_object.persisted?.should be true
    end

    
    it "should raise an exception if object fails to save" do
      pending # Not using Fedora::Repository anymore
      server_response = mock("Server Error")
      Fedora::Repository.instance.expects(:save).with(@test_object.inner_object).raises(Fedora::ServerError, server_response)
      lambda {@test_object.save}.should raise_error(Fedora::ServerError)
      #lambda {@test_object.save}.should raise_error(Fedora::ServerError, "Error Saving object #{@test_object.pid}. Server Error: RubyFedora Error Msg")
    end
    
    it "should raise an exception if any of the datastreams fail to save" do
      pending # Not using Fedora::Repository anymore
      Fedora::Repository.instance.expects(:save).with(@test_object.inner_object).returns(true)
      Fedora::Repository.instance.expects(:save).with(kind_of(ActiveFedora::RelsExtDatastream)).raises(Fedora::ServerError,  mock("Server Error")) 
      lambda {@test_object.save}.should raise_error(Fedora::ServerError)
    end
    
    it "should call .save on any datastreams that are dirty" do
      to = FooHistory.new
      to.expects(:update_index)
      @mock_repo.expects(:ingest).with(:pid => @this_pid).returns(@this_pid)
      @mock_repo.expects(:object).with(:pid => @this_pid).raises(RuntimeError)
      @mock_repo.expects(:datastreams).with(:pid => @this_pid).returns("")

      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'withText2'}
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'withText'}
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'RELS-EXT'}


      to.datastreams["someData"].stubs(:changed?).returns(true)
      to.datastreams["someData"].stubs(:new_object?).returns(true)
      to.datastreams["someData"].expects(:save)
      to.expects(:refresh)
      to.save
    end
    it "should call .save on any datastreams that are new" do
      ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'ds_to_add')
      ds.content = "DS CONTENT"
      @test_object.add_datastream(ds)
      ds.expects(:save)
      @test_object.instance_variable_set(:@new_object, false)
      @test_object.expects(:refresh)
      @mock_repo.expects(:object).with(:pid => @this_pid).raises(RuntimeError).at_least_once
      @mock_repo.expects(:ingest).with(:pid => @test_object.pid)
      @mock_repo.expects(:datastreams).with(:pid => @test_object.pid).returns("")
      @mock_repo.expects(:add_datastream).with{ |x| x[:dsid] = "RELS-EXT"}
      @test_object.expects(:update_index)
      @test_object.save
    end
    it "should not call .save on any datastreams that are not dirty" do
      @test_object = FooHistory.new
      @test_object.expects(:update_index)
      @test_object.expects(:refresh)

      @mock_repo.expects(:ingest).with(:pid => @test_object.pid)

      @test_object.inner_object.expects(:new?).returns(true).twice
      @test_object.inner_object.expects(:datastreams).returns({'someData'=>mock('obj', :changed? => false)})
      @test_object.datastreams["someData"].should_not be_nil
      @test_object.datastreams['someData'].stubs(:changed?).returns(false)
      @test_object.datastreams['someData'].stubs(:new?).returns(false)
      @test_object.datastreams['someData'].expects(:save).never
      @test_object.datastreams['withText2'].expects(:save)
      @test_object.datastreams['withText'].expects(:save)
      @test_object.datastreams['RELS-EXT'].expects(:save)
      @test_object.save
    end
    it "should update solr index with all metadata if any MetadataDatastreams have changed" do
      @mock_repo.expects(:ingest).with(:pid => nil)
      @mock_repo.expects(:modify_datastream).with{ |x| x[:pid] == nil && x[:dsid] == 'RELS-EXT'}
      @mock_repo.expects(:add_datastream).with {|params| params[:dsid] == 'ds1'}
      @mock_repo.expects(:datastream).with{ |x| x[:dsid] == 'ds1'}.returns("").at_least_once #raises(RuntimeError, "Fake Not found")
      @test_object.inner_object.expects(:new?).returns(true).times(2)
      @test_object.inner_object.expects(:datastreams).returns([])
      @test_object.inner_object.expects(:pid).at_least_once

      dirty_ds = ActiveFedora::MetadataDatastream.new(@test_object.inner_object, 'ds1')
      rels_ds = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
      rels_ds.expects(:new?).returns(false).twice
      rels_ds.model = @test_object
      mock2 = mock("ds2")
      mock2.stubs(:changed? => false)
      mock2.expects(:serialize!)
      @test_object.stubs(:datastreams).returns({:ds1 => dirty_ds, :ds2 => mock2, 'RELS-EXT'=>rels_ds})
      @test_object.expects(:update_index)
      @test_object.expects(:refresh)
      
      @test_object.save
    end
    it "should NOT update solr index if no MetadataDatastreams have changed" do
      ActiveFedora::DigitalObject.any_instance.stubs(:save)
      mock1 = mock("ds1")
      mock1.expects( :changed?).returns(false).at_least_once
      mock1.expects(:serialize!)
      mock2 = mock("ds2")
      mock2.expects( :changed?).returns(false).at_least_once
      mock2.expects(:serialize!)
      mock_rels_ext = mock("rels-ext")
      mock_rels_ext.stubs(:dsid=>"RELS-EXT", :relationships=>{}, :add_relationship=>nil, :dirty= => nil)
      mock_rels_ext.expects( :changed?).returns(false).at_least_once
      mock_rels_ext.expects(:serialize!)
      mock_rels_ext.expects(:model=).with(@test_object)
      ActiveFedora::RelsExtDatastream.expects(:new).returns(mock_rels_ext)
      @test_object.stubs(:datastreams).returns({:ds1 => mock1, :ds2 => mock2})
      @test_object.expects(:update_index).never
      @test_object.expects(:refresh)
      @test_object.instance_variable_set(:@new_object, false)

      @test_object.save
    end
    it "should update solr index if relationships have changed" do
      @mock_repo.expects(:ingest).with(:pid => @test_object.pid)
      @test_object.inner_object.expects(:repository).returns(@mock_repo).at_least_once
      @test_object.inner_object.expects(:new?).returns(true).twice

      rels_ext = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
      rels_ext.model = @test_object
      rels_ext.expects(:changed?).returns(true).times(3) # FIXME Rubydora is holding one object, while we have a different one. 
      rels_ext.expects(:save).returns(true).twice #TODO why two times?
      rels_ext.expects(:serialize!)
      clean_ds = mock("ds2")
      clean_ds.stubs(:dirty? => false, :changed? => false, :new? => false)
      clean_ds.expects(:serialize!)
      @test_object.inner_object.stubs(:datastreams).returns({"RELS-EXT" => rels_ext, :clean_ds => clean_ds})
      @test_object.stubs(:datastreams).returns({"RELS-EXT" => rels_ext, :clean_ds => clean_ds})
      @test_object.instance_variable_set(:@new_object, false)
      @test_object.expects(:refresh)
      @test_object.expects(:update_index)
      
      @test_object.save
    end
  end


  describe ".to_xml" do
    it "should provide .to_xml" do
      @test_object.should respond_to(:to_xml)
    end

    it "should add pid, system_create_date and system_modified_date from object attributes" do
      @test_object.expects(:create_date).returns("cDate")
      @test_object.expects(:modified_date).returns("mDate")
      solr_doc = @test_object.to_solr
      solr_doc["system_create_dt"].should eql("cDate")
      solr_doc["system_modified_dt"].should eql("mDate")
      solr_doc[:id].should eql("#{@test_object.pid}")
    end

    it "should call .to_xml on all MetadataDatastreams and return the resulting document" do
      ds1 = ActiveFedora::MetadataDatastream.new(@test_object.inner_object, 'ds1')
      ds2 = ActiveFedora::MetadataDatastream.new(@test_object.inner_object, 'ds2')
      [ds1,ds2].each {|ds| ds.expects(:to_xml)}

      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      @test_object.expects(:datastreams).returns({:ds1 => ds1, :ds2 => ds2})
      @test_object.to_xml
    end
  end
  
  describe ".to_solr" do
    
    # before(:all) do
    #   # Revert to default mappings after running tests
    #   ActiveFedora::SolrService.load_mappings
    # end
    
    after(:all) do
      # Revert to default mappings after running tests
      ActiveFedora::SolrService.load_mappings
    end
    
    it "should provide .to_solr" do
      @test_object.should respond_to(:to_solr)
    end

    it "should add pid, system_create_date and system_modified_date from object attributes" do
      @test_object.expects(:create_date).returns("cDate")
      @test_object.expects(:modified_date).returns("mDate")
      solr_doc = @test_object.to_solr
      solr_doc["system_create_dt"].should eql("cDate")
      solr_doc["system_modified_dt"].should eql("mDate")
      solr_doc[:id].should eql("#{@test_object.pid}")
    end

    it "should omit base metadata and RELS-EXT if :model_only==true" do
      @test_object.add_relationship(:has_part, "foo")
      # @test_object.expects(:modified_date).returns("mDate")
      solr_doc = @test_object.to_solr(Hash.new, :model_only => true)
      solr_doc["system_create_dt"].should be_nil
      solr_doc["system_modified_dt"].should be_nil
      solr_doc["id"].should be_nil
      solr_doc["has_part_s"].should be_nil
    end
    
    it "should add self.class as the :active_fedora_model" do
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      solr_doc = @test_history.to_solr
      solr_doc["active_fedora_model_s"].should eql("FooHistory")
    end

    it "should use mappings.yml to decide names of solr fields" do      
      cdate = "2008-07-02T05:09:42.015Z"
      mdate = "2009-07-07T23:37:18.991Z"
      @test_object.stubs(:create_date).returns(cdate)
      @test_object.stubs(:modified_date).returns(mdate)
      solr_doc = @test_object.to_solr
      solr_doc["system_create_dt"].should eql(cdate)
      solr_doc["system_modified_dt"].should eql(mdate)
      solr_doc[:id].should eql("#{@test_object.pid}")
      solr_doc["active_fedora_model_s"].should eql(@test_object.class.inspect)
      
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      solr_doc = @test_object.to_solr
      [:system_create_dt, :system_modified_dt, :active_fedora_model_s].each do |fn|
        solr_doc[fn].should == nil
      end
      solr_doc["system_create_date"].should eql(cdate)
      solr_doc["system_modified_date"].should eql(mdate)
      solr_doc[:id].should eql("#{@test_object.pid}")
      solr_doc["active_fedora_model_field"].should eql(@test_object.class.inspect)
    end
    
    it "should call .to_solr on all MetadataDatastreams and NokogiriDatastreams, passing the resulting document to solr" do
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      mock1 = mock("ds1", :to_solr)
      mock2 = mock("ds2", :to_solr)
      ngds = mock("ngds", :to_solr)
      mock1.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      mock2.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      ngds.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      ngds.expects(:kind_of?).with(ActiveFedora::NokogiriDatastream).returns(true)
      
      @test_object.expects(:datastreams).returns({:ds1 => mock1, :ds2 => mock2, :ngds => ngds})
      @test_object.to_solr
    end
    it "should call .to_solr on the RELS-EXT datastream if it is dirty" do
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      @test_object.add_relationship(:has_collection_member, "info:fedora/foo:member")
      rels_ext = @test_object.rels_ext
      rels_ext.dirty?.should == true
      rels_ext.expects(:to_solr)
      @test_object.to_solr
    end
    
  end
  

  describe ".update_index" do
    it "should provide .update_index" do
      @test_object.should respond_to(:update_index)
    end
  end

  describe ".label" do
    it "should return the label of the inner object" do 
      @test_object.inner_object.expects(:label).returns("foo label")
      @test_object.label.should == "foo label"
    end
  end
  
  describe ".label=" do
    it "should set the label of the inner object" do
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      @test_object.label.should_not == "foo label"
      @test_object.label = "foo label"
      @test_object.label.should == "foo label"
    end
  end
  
  it "should get a pid but not save on init" do
    Rubydora::DigitalObject.any_instance.expects(:save).never
    ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns('mooshoo:24')
    f = FooHistory.new
    f.pid.should_not be_nil
    f.pid.should == 'mooshoo:24'
  end
  it "should not clobber a pid if i'm creating!" do
    @mock_repo.expects(:datastreams).with(:pid => "numbnuts:1").returns("")
    f = FooHistory.new(:pid=>'numbnuts:1')
    f.pid.should == 'numbnuts:1'

  end
  
  describe "get_values_from_datastream" do
    it "should look up the named datastream and call get_values with the given pointer/field_name" do
      mock_ds = mock("Datastream", :get_values=>["value1", "value2"])
      @test_object.stubs(:datastreams).returns({"ds1"=>mock_ds})
      @test_object.get_values_from_datastream("ds1", "--my xpath--").should == ["value1", "value2"]
    end
  end
  
  describe "update_datastream_attributes" do
    it "should look up any datastreams specified as keys in the given hash and call update_attributes on the datastream" do
      mock_desc_metadata = mock("descMetadata")
      mock_properties = mock("properties")
      mock_ds_hash = {'descMetadata'=>mock_desc_metadata, 'properties'=>mock_properties}
      
      ds_values_hash = {
        "descMetadata"=>{ [{:person=>0}, :role]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} },
        "properties"=>{ "notes"=>"foo" }
      }
      m = FooHistory.new
      m.stubs(:datastreams).returns(mock_ds_hash)
      mock_desc_metadata.expects(:update_indexed_attributes).with( ds_values_hash['descMetadata'] )
      mock_properties.expects(:update_indexed_attributes).with( ds_values_hash['properties'] )
      m.update_datastream_attributes( ds_values_hash )
    end
    it "should not do anything and should return an empty hash if the specified datastream does not exist" do
      @mock_repo.expects(:object).with(:pid => @this_pid).returns("")
      ds_values_hash = {
        "nonexistentDatastream"=>{ "notes"=>"foo" }
      }
      m = FooHistory.new
      untouched_xml = m.to_xml
      m.update_datastream_attributes( ds_values_hash ).should == {}
      m.to_xml.should == untouched_xml
    end
  end
  
  describe "update_attributes" do

    it "should set the attributes and save" do
      m = FooHistory.new
      att= {"fubar"=> '1234', "baz" =>'stuff'}
      
      m.expects(:fubar=).with('1234')
      m.expects(:baz=).with('stuff')
      m.expects(:save)
      m.update_attributes(att)
    end
  end
  
  describe "update_indexed_attributes" do
    it "should call .update_indexed_attributes on all metadata datastreams & nokogiri datastreams" do
      m = FooHistory.new
      att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
      
      m.datastreams['someData'].expects(:update_indexed_attributes)
      m.datastreams["withText"].expects(:update_indexed_attributes)
      m.datastreams['withText2'].expects(:update_indexed_attributes)
      m.update_indexed_attributes(att)
    end
    it "should take a :datastreams argument" do 
      att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
      m = FooHistory.new
      m.update_indexed_attributes(att, :datastreams=>"withText")
      m.should_not be_nil
      m.datastreams['someData'].fubar_values.should == []
      m.datastreams["withText"].fubar_values.should == ['mork', 'york', 'mangle']
      m.datastreams['withText2'].fubar_values.should == []
      
      att= {"fubar"=>{"-1"=>"tork", "0"=>"work", "1"=>"bork"}}
      m.update_indexed_attributes(att, :datastreams=>["someData", "withText2"])
      m.should_not be_nil
      m.datastreams['someData'].fubar_values.should == ['tork', 'work', 'bork']
      m.datastreams["withText"].fubar_values.should == ['mork', 'york', 'mangle']
      m.datastreams['withText2'].fubar_values.should == ['tork', 'work', 'bork']
    end
  end

  it "should expose solr for real." do
    sinmock = mock('solr instance')
    conmock = mock("solr conn")
    sinmock.expects(:conn).returns(conmock)
    conmock.expects(:query).with('pid: foobar', {}).returns({:baz=>:bif})
    ActiveFedora::SolrService.expects(:instance).returns(sinmock)
    FooHistory.solr_search("pid: foobar").should == {:baz=>:bif}
  end
  it "should expose solr for real. and pass args through" do
    sinmock = mock('solr instance')
    conmock = mock("solr conn")
    sinmock.expects(:conn).returns(conmock)
    conmock.expects(:query).with('pid: foobar', {:ding, :dang}).returns({:baz=>:bif})
    ActiveFedora::SolrService.expects(:instance).returns(sinmock)
    FooHistory.solr_search("pid: foobar", {:ding=>:dang}).should == {:baz=>:bif}
  end

  it 'should provide #relationships_by_name' do
    @test_object.should respond_to(:relationships_by_name)
  end
  
  describe '#relationships_by_name' do
    
    class MockNamedRelationships < ActiveFedora::Base
      has_relationship "testing", :has_part, :type=>ActiveFedora::Base
      has_relationship "testing2", :has_member, :type=>ActiveFedora::Base
      has_relationship "testing_inbound", :has_part, :type=>ActiveFedora::Base, :inbound=>true
    end
    
    it 'should return current relationships by name' do
      ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns(increment_pid.to_s)
      @test_object2 = MockNamedRelationships.new
      @test_object2.add_relationship(:has_model, ActiveFedora::ContentModel.pid_from_ruby_class(MockNamedRelationships))
      @test_object.add_relationship(:has_model, ActiveFedora::ContentModel.pid_from_ruby_class(ActiveFedora::Base))
      #should return expected named relationships
      @test_object2.relationships_by_name
      @test_object2.relationships_by_name.should == {:self=>{"testing2"=>[], "collection_members"=>[], "part_of"=>[], "testing"=>[], "parts_outbound"=>[]}}
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:dummy,:object=>@test_object})
      @test_object2.add_relationship_by_name("testing",@test_object)
      @test_object2.relationships_by_name.should == {:self=>{"testing"=>[r.object],"testing2"=>[],"part_of"=>[], "parts_outbound"=>[r.object], "collection_members"=>[]}}
    end 
  end

  
  describe '#create_relationship_name_methods' do
    class MockCreateNamedRelationshipMethodsBase < ActiveFedora::Base
      register_relationship_desc :self, "testing", :is_part_of, :type=>ActiveFedora::Base
      create_relationship_name_methods "testing"
    end
      
    it 'should append and remove using helper methods for each outbound relationship' do
      ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns(increment_pid.to_s)
      @test_object2 = MockCreateNamedRelationshipMethodsBase.new 
      @test_object2.should respond_to(:testing_append)
      @test_object2.should respond_to(:testing_remove)
      #test executing each one to make sure code added is correct
      r = ActiveFedora::Relationship.new({:subject=>:self,:predicate=>:has_model,:object=>ActiveFedora::ContentModel.pid_from_ruby_class(ActiveFedora::Base)})
      @test_object.add_relationship(r.predicate,r.object)
      @test_object2.add_relationship(r.predicate,r.object)
      @test_object2.testing_append(@test_object)
      #create relationship to access generate_uri method for an object
      r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>:dummy, :object=>@test_object)
      @test_object2.relationships_by_name.should == {:self=>{"testing"=>[r.object],"collection_members"=>[], "part_of"=>[r.object], "parts_outbound"=>[]}}
      @test_object2.testing_remove(@test_object)
      @test_object2.relationships_by_name.should == {:self=>{"testing"=>[],"collection_members"=>[], "part_of"=>[], "parts_outbound"=>[]}}
    end
  end
end
