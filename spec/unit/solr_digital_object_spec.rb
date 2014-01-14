require 'spec_helper'

describe ActiveFedora::SolrDigitalObject do
  describe "repository" do
    subject { ActiveFedora::SolrDigitalObject.new({},{'datastreams'=>{}}) }
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
      subject { ActiveFedora::SolrDigitalObject.new({}, {'datastreams'=>{'properties'=>{'dsMIME'=>'text/xml'}}},WithoutMetadataDs) }
      it "should create an xml datastream" do
        subject.datastreams['properties'].should be_kind_of ActiveFedora::OmDatastream
      end

      its(:new_record?) { should be_false }
    end
    
    describe "with a ds spec that's not part of the solrized object" do
      before do
        class MissingMetadataDs < ActiveFedora::Base
          has_metadata :name => "foo", :type => ActiveFedora::OmDatastream, :label => 'Foo Data'
        end
        after do
          Object.send(:remove_const, MissingMetadataDs)
        end
        subject { ActiveFedora::SolrDigitalObject.new({}, {'datastreams'=>{'properties'=>{'dsMIME'=>'text/xml'}}},MissingMetadataDs) }
        it "should have a foo datastream" do
          subject.datastreams['foo'].label.should == 'Foo Data'
        end
      end
    end
  end


end
