require 'spec_helper'
require 'active_fedora'
require 'active_fedora/base'
require 'active_fedora/metadata_datastream'
require 'ruby-debug'
require 'nokogiri'

# Load Sample OralHistory Model
require File.join( File.dirname(__FILE__), "..","samples","oral_history_sample_model" )


describe ActiveFedora::Base do
  
  before(:all) do
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end

  before(:each) do
    @test_object = OralHistorySampleModel.new
    @test_object.save
  end
  
  after(:each) do
    @test_object.delete
  end
  
  describe "load_instance" do
    it "should retain all datastream attributes pulled from fedora" do
      raw_object = ActiveFedora::Base.find(@test_object.pid)
      loaded = OralHistorySampleModel.load_instance(@test_object.pid)
      raw_datastreams = raw_object.datastreams
      loaded_datastreams = loaded.datastreams
      raw_datastreams.each_pair do |k,v|
        v.dsid.should == loaded_datastreams[k].dsid
        v.dsLabel.should == loaded_datastreams[k].dsLabel
        v.mimeType.should == loaded_datastreams[k].mimeType
      end
    end
  end

end
