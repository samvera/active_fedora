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
      @obj.descMetadata.should be_inline
    end

    it "should not be changed when no fields have been set" do
      @obj.descMetadata.should_not be_content_changed
    end
    it "should be changed when a field has been set" do
      @obj.descMetadata.title = 'Foobar'
      @obj.descMetadata.should be_content_changed
    end
    describe "#changed?" do
      it "should not be changed if the new xml matches the old xml" do
        @obj.descMetadata.content = @obj.descMetadata.content
        @obj.descMetadata.should_not be_changed
      end

      it "should not be changed if there are minor differences in whitespace" do
        @obj.descMetadata.content = "<a><b>1</b></a>"
        @obj.save
        @obj.descMetadata.should_not be_changed
        @obj.descMetadata.content = "<a>\n<b>1</b>\n</a>"
        @obj.descMetadata.should_not be_changed
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
      @obj.descMetadata.should be_managed
    end

    describe "#changed?" do
      it "should not be changed if the new xml matches the old xml" do
        @obj.descMetadata.content = @obj.descMetadata.content
        @obj.descMetadata.should_not be_changed
      end

      it "should be changed if there are minor differences in whitespace" do
        @obj.descMetadata.content = "<a><b>1</b></a>"
        @obj.save
        @obj.descMetadata.should_not be_changed
        @obj.descMetadata.content = "<a>\n<b>1</b>\n</a>"
        @obj.descMetadata.should be_changed
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
        @solr_obj.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
        @solr_obj.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
        @solr_obj.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
        @solr_obj.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
        @solr_obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
        @solr_obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
        ar = @solr_obj.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
        ar.length.should == 4
        ar.include?("Creator").should == true
        ar.include?("Contributor").should == true
        ar.include?("Funder").should == true
        ar.include?("Host").should == true

        @obj.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
        @obj.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
        @obj.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
        @obj.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
        @obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
        @obj.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
        ar = @obj.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
        ar.length.should == 4
        ar.include?("Creator").should == true
        ar.include?("Contributor").should == true
        ar.include?("Funder").should == true
        ar.include?("Host").should == true
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
        @obj.datastreams["descMetadata"].should be_changed
        @obj.save
        @obj.datastreams["descMetadata"].should_not be_changed
        @obj.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Funder"]
      end    
    end


    describe ".to_solr" do
      before do
        @obj.descMetadata.journal.issue.publication_date = Date.parse('2012-11-02')
        @obj.save!
        @obj.reload
      end
      it "should solrize terms with :type=>'date' to *_dt solr terms" do
        @obj.to_solr[ActiveFedora::SolrService.solr_name('journal_issue_publication_date', type: :date)].should == ['2012-11-02T00:00:00Z']
      end
    end
  end
end
