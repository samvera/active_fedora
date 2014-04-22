require 'spec_helper'

describe ActiveFedora::Base do
  
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
    
    it "should call .to_solr on all Datastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})
      
      mock_datastreams = {:ds1 => mock1, :ds2 => mock2}
      mock1.should_receive(:to_solr).and_return({})
      mock2.should_receive(:to_solr).and_return({})
      subject.should_receive(:datastreams).and_return(mock_datastreams)
      subject.should_receive(:solrize_relationships)
      subject.update_index
    end

    it "should retrieve a solr Connection and call Connection.add" do
      subject.update_index
    end

  end
  
  describe ".delete" do
    
    before do
      subject.stub(new_record?: false)
      subject.orm.resource.client.stub(:delete)
    end
    
    it "should delete object from repository and index" do
      ActiveFedora::SolrService.should_receive(:delete).with(nil)
      subject.delete
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
    
    its(:to_class_uri) {should == 'http://fedora.info/definitions/v4/model#SpecModel_CamelCased' }
  
    context "with the namespace declared in the model" do
      before do
        subject.stub(:pid_namespace).and_return("http://test.com/model#")
      end
      its(:to_class_uri) {should == 'http://test.com/model#SpecModel_CamelCased' }
    end
  end
end
