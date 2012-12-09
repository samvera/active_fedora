require 'spec_helper'

describe ActiveFedora::Base do
  before(:all) do
    @behavior = ActiveFedora::FileManagement.deprecation_behavior
    ActiveFedora::FileManagement.deprecation_behavior = :silence
  end
  
  after :all do
    ActiveFedora::FileManagement.deprecation_behavior = @behavior
  end

  before(:all) do
    class FileMgmt < ActiveFedora::Base
      include ActiveFedora::FileManagement
    end
    @base = FileMgmt.new
  end

  before(:each) do
    @base.stub(:create_date).and_return("2008-07-02T05:09:42.015Z")
    @base.stub(:modified_date).and_return("2008-09-29T21:21:52.892Z")
  end
  
  describe ".file_objects" do
    it "should wrap .collection_members and .parts" do
      @base.should_receive(:collection_members).and_return([])
      @base.should_receive(:parts).and_return(["Foo"])
      @base.file_objects
    end
  end
  
  describe ".file_objects_append" do
    it "should make the file object being appended assert isPartOf pointing back at the current object and save the child" do
      mock_child = ActiveFedora::Base.new
      mock_child.should_receive(:add_relationship).with(:is_part_of, @base)
      mock_child.should_receive(:save)
      @base.file_objects_append(mock_child)
    end
    it "should load the file object being appended if only a pid is provided and save the child" do
      mock_child = mock("object")
      mock_child.should_receive(:add_relationship).with(:is_part_of, @base)
      mock_child.should_receive(:save)
      ActiveFedora::Base.should_receive(:find).with("_PID_").and_return(mock_child)
      @base.file_objects_append("_PID_")
    end
  end
  
  describe ".parts" do
    it "should search for both (outbound) has_part and (inbound) is_part_of relationships, removing duplicates" do
      @base.should_receive(:parts_outbound).and_return(["A", "B"])
      @base.should_receive(:parts_inbound).and_return(["B", "C"])
      @base.parts.should == ["B", "C", "A"]
    end
  end
  
  describe ".collection_members" do
    it "should return an array" do
      @base.collection_members.should be_kind_of(Array)
    end
    describe "_append" do
      it "should be a supported method" do
        @base.should respond_to(:collection_members_append)
      end
      it "should assert hasCollectionMember for the given object/pid" do
        mocko = mock("object")
        @base.should_receive(:add_relationship).with(:has_collection_member, mocko)
        @base.collection_members_append(mocko)
      end
    end
    describe "_remove" do
      it "should be a supported method" do
        @base.should respond_to(:collection_members_remove)
      end
    end
  end
  
  describe ".add_file_datastream" do
    it "should create a new datastream with the file as its content" do
      mock_file = mock()
      ds = mock()
      @base.should_receive(:create_datastream).with(ActiveFedora::Datastream, nil, hash_including(:blob => mock_file)).and_return(ds)
      @base.should_receive(:add_datastream).with(ds)
      @base.add_file_datastream(mock_file)
    end
    it "should set  :dsid  and :label when supplied" do
      mock_file = mock()
      ds = mock()
      @base.should_receive(:create_datastream).with(ActiveFedora::Datastream, 'Foo', hash_including(:dsLabel => 'My Label', :blob => mock_file)).and_return(ds)
      @base.should_receive(:add_datastream).with(ds)
      @base.add_file_datastream(mock_file, :label => 'My Label', :dsid => 'Foo')
    end
    
  end
end
