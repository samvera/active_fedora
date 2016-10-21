require 'spec_helper'
require "solrizer"

describe ActiveFedora::OmDatastream do
  
  describe "a new instance with an inline datastream" do
    before(:all) do 
      class ModsArticle3 < ActiveFedora::Base
        # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
        has_metadata "descMetadata", type: Hydra::ModsArticleDatastream, control_group: 'X', autocreate: true
      end
    end

    after(:all) do
      Object.send(:remove_const, :ModsArticle3)
    end

    before(:each) do
      @obj = ModsArticle3.new
      @obj.save
      @obj.reload
    end

    after(:each) do
      @obj.destroy
    end

    it "should report being inline" do
      expect(@obj.descMetadata).to be_inline
    end

    it "should not be changed when no fields have been set" do
      expect(@obj.descMetadata).not_to be_changed
    end
    it "should be changed when a field has been set" do
      @obj.descMetadata.title = 'Foobar'
      expect(@obj.descMetadata).to be_changed
    end
    describe "#changed?" do
      it "should not be changed if the new xml matches the old xml" do
        @obj.descMetadata.content = @obj.descMetadata.content
        expect(@obj.descMetadata).not_to be_changed
      end

      it "should not be changed if there are minor differences in whitespace" do
        @obj.descMetadata.content = "<a><b>1</b></a>"
        @obj.save
        expect(@obj.descMetadata).not_to be_changed
        @obj.descMetadata.content = "<a>\n<b>1</b>\n</a>"
        expect(@obj.descMetadata).not_to be_changed
      end
    end
  end

  describe "an instance that is a managed datastream" do
    before(:all) do
      class ModsArticle2 < ActiveFedora::Base
        # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
        has_metadata "descMetadata", type: Hydra::ModsArticleDatastream, autocreate: true
      end
    end

    after(:all) do
      Object.send(:remove_const, :ModsArticle2)
    end

    before(:each) do
      @obj = ModsArticle2.new
      @obj.save
      @obj.reload
    end

    after(:each) do
      @obj.destroy
    end

    it "should not report being inline" do
      expect(@obj.descMetadata).to be_managed
    end

    describe "#changed?" do
      it "should not be changed if the new xml matches the old xml" do
        @obj.descMetadata.content = @obj.descMetadata.content
        expect(@obj.descMetadata).not_to be_changed
      end

      it "should be changed if there are minor differences in whitespace" do
        @obj.descMetadata.content = "<a><b>1</b></a>"
        @obj.save
        expect(@obj.descMetadata).not_to be_changed
        @obj.descMetadata.content = "<a>\n<b>1</b>\n</a>"
        expect(@obj.descMetadata).to be_changed
      end
    end

    describe "empty datastream content" do
      it "should not break when there is empty datastream content" do
        @obj.descMetadata.content = ""
        @obj.save
      end
    end

    describe '.term_values' do
      before do
        @obj.descMetadata.content = File.read(fixture('mods_articles/mods_article1.xml'))
        @obj.save
        @obj.reload
        @solr_obj = ActiveFedora::Base.load_instance_from_solr(@obj.pid)
      end

      it "should return the same values whether getting from solr or Fedora" do
        expect(@solr_obj.datastreams["descMetadata"].term_values(:name,:role,:text)).to eq(["Creator","Contributor","Funder","Host"])
        expect(@solr_obj.datastreams["descMetadata"].term_values({:name=>0},:role,:text)).to eq(["Creator"])
        expect(@solr_obj.datastreams["descMetadata"].term_values({:name=>1},:role,:text)).to eq(["Contributor"])
        expect(@solr_obj.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text)).to eq(["Creator"])
        expect(@solr_obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text)).to eq(["Contributor"])
        expect(@solr_obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text)).to eq([])
        ar = @solr_obj.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
        expect(ar.length).to eq(4)
        expect(ar.include?("Creator")).to eq(true)
        expect(ar.include?("Contributor")).to eq(true)
        expect(ar.include?("Funder")).to eq(true)
        expect(ar.include?("Host")).to eq(true)

        expect(@obj.datastreams["descMetadata"].term_values(:name,:role,:text)).to eq(["Creator","Contributor","Funder","Host"])
        expect(@obj.datastreams["descMetadata"].term_values({:name=>0},:role,:text)).to eq(["Creator"])
        expect(@obj.datastreams["descMetadata"].term_values({:name=>1},:role,:text)).to eq(["Contributor"])
        expect(@obj.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text)).to eq(["Creator"])
        expect(@obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text)).to eq(["Contributor"])
        expect(@obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text)).to eq([])
        ar = @obj.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
        expect(ar.length).to eq(4)
        expect(ar.include?("Creator")).to eq(true)
        expect(ar.include?("Contributor")).to eq(true)
        expect(ar.include?("Funder")).to eq(true)
        expect(ar.include?("Host")).to eq(true)
      end
    end
    
    describe '.update_values' do
      before do
        @obj.descMetadata.content = File.read(fixture('mods_articles/mods_article1.xml'))
        @obj.save
        @obj.reload
      end

      it "should not be dirty after .update_values is saved" do
        @obj.datastreams["descMetadata"].update_values([{:name=>0},{:role=>0},:text] =>"Funder")
        expect(@obj.datastreams["descMetadata"]).to be_changed
        @obj.save
        expect(@obj.datastreams["descMetadata"]).not_to be_changed
        expect(@obj.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text)).to eq(["Funder"])
      end    
    end


    describe ".to_solr" do
      before do
        @obj.descMetadata.journal.issue.publication_date = Date.parse('2012-11-02')
        @obj.save!
        @obj.reload
      end
      it "should solrize terms with :type=>'date' to *_dt solr terms" do
        expect(@obj.to_solr[ActiveFedora::SolrService.solr_name('desc_metadata__journal_issue_publication_date', type: :date)]).to eq(['2012-11-02T00:00:00Z'])
      end
    end
  end
end
