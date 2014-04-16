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
      expect(subject.nokogiri_autocreate_on).to_not be_new_record
      expect(subject.nokogiri_autocreate_off).to be_new_record
    end
  end

  describe "#has_file_datastream" do
    before :all do
      class HasFile < ActiveFedora::Base
        has_file_datastream "file_ds"
        has_file_datastream "file_ds2", autocreate: false
      end
    end
    after :all do
      Object.send(:remove_const, :HasFile)
    end
    before :each do
      @base = ActiveFedora::Base.new("test:ds_versionable_base")
      @base.save
      @base2 = ActiveFedora::Base.new("test:ds_versionable_base2")
      @base2.add_datastream(@base2.create_datastream(ActiveFedora::Datastream, "file_ds"))
      @base2.datastreams["file_ds"].content = "blah blah blah"
      @base2.save
      @has_file = HasFile.new("test:ds_versionable_has_file")
      @has_file.save
    end
    
    after :each do
      @base.delete
      @base2.delete
      @has_file.delete
    end
    
    it "should create datastreams from the spec on new objects" do
      @has_file.file_ds.content = "blah blah blah"
      @has_file.file_ds.changed?.should be_true
      @has_file.file_ds2.changed?.should be_false # no autocreate
      expect(@has_file.file_ds2).to be_new_record
      @has_file.save
      test_obj = HasFile.find(@has_file.pid)
      test_obj.file_ds.changed?.should be_false
      test_obj.file_ds2.changed?.should be_false
      expect(test_obj.file_ds2).to be_new_record
    end
  end
end
