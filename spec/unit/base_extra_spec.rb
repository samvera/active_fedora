require 'spec_helper'

describe ActiveFedora::Base do

  describe ".update_index" do
    before do
      mock_conn = double("SolrConnection")
      expect(mock_conn).to receive(:add) do |_, opts|
        expect(opts).to eq(:params=>{:softCommit=>true})
      end
      mock_ss = double("SolrService")
      allow(mock_ss).to receive(:conn).and_return(mock_conn)
      allow(ActiveFedora::SolrService).to receive(:instance).and_return(mock_ss)
    end

    it "should call .to_solr on all Datastreams and pass the resulting document to solr" do
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = double("ds1", :to_solr => {})
      mock2 = double("ds2", :to_solr => {})

      mock_datastreams = {:ds1 => mock1, :ds2 => mock2}
      expect(mock1).to receive(:to_solr).and_return({})
      expect(mock2).to receive(:to_solr).and_return({})
      expect(subject).to receive(:attached_files).and_return(mock_datastreams)
      expect(subject).to receive(:solrize_relationships)
      subject.update_index
    end

    it "should retrieve a solr Connection and call Connection.add" do
      subject.update_index
    end

  end

  describe ".delete" do

    before do
      allow(subject).to receive(:new_record?).and_return(false)
      allow(ActiveFedora.fedora.connection).to receive(:delete)
    end

    it "should delete object from repository and index" do
      expect(ActiveFedora::SolrService).to receive(:delete).with(nil)
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
    subject {SpecModel::CamelCased.to_class_uri}

    it { should == 'SpecModel::CamelCased' }
  end
end
