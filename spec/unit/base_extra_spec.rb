require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  describe ".update_index" do
    before do
      mock_conn = double("SolrConnection")
      expect(mock_conn).to receive(:add) do |_, opts|
        expect(opts).to eq({:params=>{:softCommit=>true}})
      end
      mock_ss = double("SolrService")
      allow(mock_ss).to receive(:conn).and_return(mock_conn)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(mock_ss)
    end
    
    it "should call .to_solr on all SimpleDatastreams AND RelsExtDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})
      mock3 = double("RELS-EXT", :to_solr => {})
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      expect(mock1).to receive(:solrize_profile).and_return({})
      expect(mock2).to receive(:solrize_profile).and_return({})
      expect(mock3).to receive(:solrize_profile).and_return({})
      expect(@test_object).to receive(:datastreams).twice.and_return(mock_datastreams)
      expect(@test_object).to receive(:solrize_relationships)
      @test_object.update_index
    end

    it "should call .to_solr on all RDFDatastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})
      mock3 = double("RELS-EXT", :to_solr => {})
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3}
      expect(mock1).to receive(:solrize_profile).and_return({})
      expect(mock2).to receive(:solrize_profile).and_return({})
      expect(mock3).to receive(:solrize_profile).and_return({})
      expect(@test_object).to receive(:datastreams).twice.and_return(mock_datastreams)
      expect(@test_object).to receive(:solrize_relationships)
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
      allow(@test_object.inner_object).to receive(:delete)
      mock_conn = double("SolrConnection")
      expect(mock_conn).to receive(:delete_by_id).with(nil, {:params=>{"softCommit"=>true}}) 
      mock_ss = double("SolrService")
      allow(mock_ss).to receive(:conn).and_return(mock_conn)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(mock_ss)
      @test_object.delete
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
        allow(subject).to receive(:pid_namespace).and_return("test-cModel")
      end
      its(:to_class_uri) {should == 'info:fedora/test-cModel:SpecModel_CamelCased' }
    end
    context "with the suffix declared in the model" do
      before do
        allow(subject).to receive(:pid_suffix).and_return("-TEST-SUFFIX")
      end
      its(:to_class_uri) {should == 'info:fedora/afmodel:SpecModel_CamelCased-TEST-SUFFIX' }
    end
  end
end
