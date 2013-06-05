require 'spec_helper'

require 'active_fedora'
require "rexml/document"

describe ActiveFedora::Datastreams do
  describe "serializing datastreams" do
    before :all do
      class TestingMetadataSerializing < ActiveFedora::Base
        has_metadata :name => "nokogiri_autocreate_on", :autocreate => true, :type => ActiveFedora::OmDatastream
        has_metadata :name => "nokogiri_autocreate_off", :autocreate => false, :type => ActiveFedora::OmDatastream
      end
    end

    after :all do
      Object.send(:remove_const, :TestingMetadataSerializing)
    end

    subject { TestingMetadataSerializing.new }

    it "should work" do
      subject.save(:validate => false)
      subject.nokogiri_autocreate_on.should_not be_new
      subject.nokogiri_autocreate_off.should be_new
    end
  end


  describe "#has_metadata" do
    before :all do
      class HasMetadata < ActiveFedora::Base
        has_metadata :name => "with_versions", :autocreate => true, :label => "Versioned DS", :type => ActiveFedora::SimpleDatastream
        has_metadata :name => "without_versions", :autocreate => true, :versionable => false, :type => ActiveFedora::SimpleDatastream
      end
    end
    after :all do
      Object.send(:remove_const, :HasMetadata)
    end
    before :each do
      @base = ActiveFedora::Base.new(:pid=>"test:has_metadata_base")
      @base.add_datastream(@base.create_datastream(ActiveFedora::Datastream, "testDS", :dsLabel => "Test DS"))
      @base.datastreams["testDS"].content = "blah blah blah"
      @base.save
      @test = HasMetadata.new(:pid=>"test:has_metadata_model")
      @test.save
    end
    
    after :each do
      @base.delete
      @test.delete
    end
    
    it "should create datastreams from the spec on new objects" do
      @test.without_versions.versionable.should be_false
      @test.with_versions.versionable.should be_true
      @test.with_versions.dsLabel.should == "Versioned DS"
      @test.without_versions.content= "blah blah blah"
      @test.save
      HasMetadata.find(@test.pid).without_versions.versionable.should be_false
    end
    
    it "should use ds_specs and preserve existing datastreams on migrated objects" do
      test_obj = HasMetadata.find(@base.pid)
      test_obj.datastreams["testDS"].dsLabel.should == "Test DS"
      test_obj.datastreams["testDS"].new?.should be_false
      test_obj.with_versions.dsLabel.should == "Versioned DS"
      test_obj.without_versions.versionable.should be_false
      test_obj.with_versions.new?.should be_true
    end
    
  end
  
  describe "#has_file_datastream" do
    before :all do
      class HasFile < ActiveFedora::Base
        has_file_datastream :name => "file_ds", :versionable => false
        has_file_datastream :name => "file_ds2", :versionable => false, :autocreate => false
      end
    end
    after :all do
      Object.send(:remove_const, :HasFile)
    end
    before :each do
      @base = ActiveFedora::Base.new(:pid=>"test:ds_versionable_base")
      @base.save
      @base2 = ActiveFedora::Base.new(:pid=>"test:ds_versionable_base2")
      @base2.add_datastream(@base2.create_datastream(ActiveFedora::Datastream,"file_ds", :versionable=>true,:dsLabel=>"Pre-existing DS"))
      @base2.datastreams["file_ds"].content = "blah blah blah"
      @base2.save
      @has_file = HasFile.new(:pid=>"test:ds_versionable_has_file")
      @has_file.save
    end
    
    after :each do
      @base.delete
      @base2.delete
      @has_file.delete
    end
    
    it "should create datastreams from the spec on new objects" do
      @has_file.file_ds.versionable.should be_false
      @has_file.file_ds.content = "blah blah blah"
      @has_file.file_ds.changed?.should be_true
      @has_file.file_ds2.changed?.should be_false # no autocreate
      @has_file.file_ds2.new?.should be_true
      @has_file.save
      @has_file.file_ds.versionable.should be_false
      test_obj = HasFile.find(@has_file.pid)
      test_obj.file_ds.versionable.should be_false
      test_obj.rels_ext.changed?.should be_false
      test_obj.file_ds.changed?.should be_false
      test_obj.file_ds2.changed?.should be_false
      test_obj.file_ds2.new?.should be_true
    end
    
    it "should use ds_specs on migrated objects" do
      test_obj = HasFile.find(@base.pid)
      test_obj.file_ds.versionable.should be_false
      test_obj.file_ds.new?.should be_true
      test_obj.file_ds.content = "blah blah blah"
      test_obj.save
      test_obj.file_ds.versionable.should be_false
      # look it up again to check datastream profile
      test_obj = HasFile.find(@base.pid)
      test_obj.file_ds.versionable.should be_false
      test_obj.file_ds.dsLabel.should == "File Datastream"
      test_obj = HasFile.find(@base2.pid)
      test_obj.file_ds.versionable.should be_true
      test_obj.file_ds.dsLabel.should == "Pre-existing DS"
    end
  end
end
