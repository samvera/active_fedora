require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  describe ".update_index" do
    before do
      mock_conn = double("SolrConnection")
      mock_conn.should_receive(:add) do |_, opts|
        opts.should == {:params=>{:softCommit=>true}}
      end
      mock_ss = double("SolrService")
      mock_ss.stub(:conn).and_return(mock_conn)
      ActiveFedora::SolrService.stub(:instance).and_return(mock_ss)
    end
    
    it "should call .to_solr on all SimpleDatastreams AND RelsExtDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})
      mock3 = double("RELS-EXT", :to_solr => {})
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      mock1.should_receive(:solrize_profile).and_return({})
      mock2.should_receive(:solrize_profile).and_return({})
      mock3.should_receive(:solrize_profile).and_return({})
      @test_object.should_receive(:datastreams).twice.and_return(mock_datastreams)
      @test_object.should_receive(:solrize_relationships)
      @test_object.update_index
    end

    it "should call .to_solr on all RDFDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})
      mock3 = double("RELS-EXT", :to_solr => {})
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      mock1.should_receive(:solrize_profile).and_return({})
      mock2.should_receive(:solrize_profile).and_return({})
      mock3.should_receive(:solrize_profile).and_return({})
      @test_object.should_receive(:datastreams).twice.and_return(mock_datastreams)
      @test_object.should_receive(:solrize_relationships)
      @test_object.update_index
    end

    it "should retrieve a solr Connection and call Connection.add" do
      @test_object.update_index
    end

  end
  
  describe ".delete" do
    
    before(:each) do
    end
    
    it "should delete object from repository and index" do
      @test_object.inner_object.stub(:delete)
      mock_conn = double("SolrConnection")
      mock_conn.should_receive(:delete_by_id).with(nil, {:params=>{"softCommit"=>true}}) 
      mock_ss = double("SolrService")
      mock_ss.stub(:conn).and_return(mock_conn)
      ActiveFedora::SolrService.stub(:instance).and_return(mock_ss)
      @test_object.delete
    end

  end
  
  describe '#pids_from_uris' do 
    it "should strip the info:fedora/ out of a given string" do 
      ActiveFedora::Base.pids_from_uris("info:fedora/FOOBAR").should == "FOOBAR"
    end
    it "should accept an array of strings"do 
      ActiveFedora::Base.pids_from_uris(["info:fedora/FOOBAR", "info:fedora/BAZFOO"]).should == ["FOOBAR", "BAZFOO"]
    end
  end

  describe "to_class_uri" do
    before :all do
      module SpecModel
        class CamelCased < ActiveFedora::Base
        end
      end
    end
    
    after :all do
      SpecModel.send(:remove_const, :CamelCased)
    end
    subject {SpecModel::CamelCased}
    
    its(:to_class_uri) {should == 'info:fedora/afmodel:SpecModel_CamelCased' }
  
    context "with the namespace declared in the model" do
      before do
        subject.stub(:pid_namespace).and_return("test-cModel")
      end
      its(:to_class_uri) {should == 'info:fedora/test-cModel:SpecModel_CamelCased' }
    end
    context "with the suffix declared in the model" do
      before do
        subject.stub(:pid_suffix).and_return("-TEST-SUFFIX")
      end
      its(:to_class_uri) {should == 'info:fedora/afmodel:SpecModel_CamelCased-TEST-SUFFIX' }
    end
  end
end
