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
    allow(@base).to receive(:create_date).and_return("2008-07-02T05:09:42.015Z")
    allow(@base).to receive(:modified_date).and_return("2008-09-29T21:21:52.892Z")
  end

  describe ".file_objects" do
    it "should wrap .collection_members and .parts" do
      expect(@base).to receive(:collection_members).and_return([])
      expect(@base).to receive(:parts).and_return(["Foo"])
      @base.file_objects
    end
  end

  describe ".file_objects_append" do
    it "should make the file object being appended assert isPartOf pointing back at the current object and save the child" do
      mock_child = ActiveFedora::Base.new
      expect(mock_child).to receive(:add_relationship).with(:is_part_of, @base)
      expect(mock_child).to receive(:save)
      @base.file_objects_append(mock_child)
    end
    it "should load the file object being appended if only a pid is provided and save the child" do
      mock_child = double("object")
      expect(mock_child).to receive(:add_relationship).with(:is_part_of, @base)
      expect(mock_child).to receive(:save)
      expect(ActiveFedora::Base).to receive(:find).with("_PID_").and_return(mock_child)
      @base.file_objects_append("_PID_")
    end
  end

  describe ".parts" do
    it "should search for both (outbound) has_part and (inbound) is_part_of relationships, removing duplicates" do
      expect(@base).to receive(:parts_outbound).and_return(["A", "B"])
      expect(@base).to receive(:parts_inbound).and_return(["B", "C"])
      expect(@base.parts).to eq(["B", "C", "A"])
    end
  end

  describe ".collection_members" do
    it "should return an array" do
      expect(@base.collection_members).to be_kind_of(Array)
    end
    describe "_append" do
      it "should be a supported method" do
        expect(@base).to respond_to(:collection_members_append)
      end
      it "should assert hasCollectionMember for the given object/pid" do
        mocko = double("object")
        expect(@base).to receive(:add_relationship).with(:has_collection_member, mocko)
        @base.collection_members_append(mocko)
      end
    end
    describe "_remove" do
      it "should be a supported method" do
        expect(@base).to respond_to(:collection_members_remove)
      end
    end
  end

  describe ".add_file_datastream" do
    it "should create a new datastream with the file as its content" do
      mock_file = double()
      ds = double()
      expect(@base).to receive(:create_datastream).with(ActiveFedora::Datastream, nil, hash_including(:blob => mock_file)).and_return(ds)
      expect(@base).to receive(:add_datastream).with(ds)
      @base.add_file_datastream(mock_file)
    end
    it "should set  :dsid  and :label when supplied" do
      mock_file = double()
      ds = double()
      expect(@base).to receive(:create_datastream).with(ActiveFedora::Datastream, 'Foo', hash_including(:dsLabel => 'My Label', :blob => mock_file)).and_return(ds)
      expect(@base).to receive(:add_datastream).with(ds)
      @base.add_file_datastream(mock_file, :label => 'My Label', :dsid => 'Foo')
    end

  end
end
