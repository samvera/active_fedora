require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

# Some tentative extensions to ActiveFedora::Base

describe ActiveFedora::Base do
  
  before(:each) do
    Fedora::Repository.stubs(:instance).returns(stub_everything())
    @base = ActiveFedora::Base.new
    @base.stubs(:create_date).returns("2008-07-02T05:09:42.015Z")
    @base.stubs(:modified_date).returns("2008-09-29T21:21:52.892Z")
  end
  
  describe ".file_objects" do
    it "should be a supported method" do
      @base.should respond_to("file_objects")
    end
    it "should wrap .collection_members" do
      @base.expects(:collection_members)
      @base.file_objects
    end
    describe "_append" do
      it "should wrap collection_members_append" do
        mocko = mock("object")
        @base.expects(:collection_members_append).with(mocko)
        @base.file_objects_append(mocko)
      end
    end
    describe "_remove" do
      it "should wrap collection_members_remove"
    end
  end
  
  describe ".collection_members" do
    it "should return an array" do
      @base.collection_members.should be_kind_of(Array)
    end
    it "should search for all of the :collection_members" 
    describe "_append" do
      it "should be a supported method" do
        @base.should respond_to(:collection_members_append)
      end
      it "should assert hasCollectionMember for the given object/pid" do
        mocko = mock("object")
        @base.expects(:add_relationship).with(:has_collection_member, mocko)
        @base.collection_members_append(mocko)
      end
      it "should support << operator" do
        pending
        # I can't remember how to do this, and it's not a deal breaker... (MZ)
        mocko = mock("object")
        @base.expects(:add_relationship).with(:has_collection_member, mocko)
        @base.collection_members << mocko
      end
    end
    describe "_remove" do
      it "should be a supported method" do
        @base.should respond_to(:collection_members_remove)
      end
      it "should remove hasCollectionMember for the given object/pid"
    end
  end
  
  describe ".add_file_datastream" do
    it "should create a new datastream with the file as its content" do
      mock_file = mock("File")
      mock_ds = mock("Datastream")
      ActiveFedora::Datastream.expects(:new).with(:dsLabel => "", :controlGroup => 'M', :blob=>mock_file).returns(mock_ds)
      @base.expects(:add_datastream).with(mock_ds)
      @base.add_file_datastream(mock_file)
    end
    it "should apply filename argument to the datastream label if it is provided" do
      mock_file = mock("File")
      mock_ds = mock("Datastream")
      ActiveFedora::Datastream.expects(:new).with(:dsLabel => "My Label", :controlGroup => 'M', :blob=>mock_file).returns(mock_ds)
      @base.expects(:add_datastream).with(mock_ds)
      @base.add_file_datastream(mock_file, :label => "My Label")
    end
    it "should use :dsid if provided" do
      mock_file = mock("File")
      mock_ds = mock("Datastream")
      mock_ds.expects(:dsid=).with("__DSID__")
      ActiveFedora::Datastream.expects(:new).with(:dsLabel => "My Label", :controlGroup => 'M', :blob=>mock_file).returns(mock_ds)
      @base.expects(:add_datastream).with(mock_ds)
      @base.add_file_datastream(mock_file, :label => "My Label", :dsid => "__DSID__")
    end
    
  end
end