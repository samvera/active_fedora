require 'spec_helper'

describe ActiveFedora::SolrDigitalObject do
  describe "repository" do
    subject { ActiveFedora::SolrDigitalObject.new({}) }
    describe "when not finished" do
      it "should not respond_to? :repository" do
        subject.should_not respond_to :repository
      end
    end
    describe "when finished" do
      before do
        subject.freeze
      end
      it "should respond_to? :repository" do
        subject.should respond_to :repository
      end
    end
  end

  describe "initializing" do
    describe "without a datastream in the ds spec and an xml mime type in the solr doc" do
      before do
        class WithoutMetadataDs < ActiveFedora::Base
          ## No datastreams are defined in this class
        end
      end
      after do
        Object.send(:remove_const, :WithoutMetadataDs)
      end
      subject { ActiveFedora::SolrDigitalObject.new({'properties_dsProfile_dsMIME_s' =>'text/xml'}, WithoutMetadataDs) }
      it "should create an xml datastream" do
        subject.datastreams['properties'].should be_kind_of ActiveFedora::NokogiriDatastream
      end
    end
  end


end
