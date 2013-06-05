require 'spec_helper'
require "solrizer"

describe ActiveFedora::OmDatastream do
  
  describe "an new instance with a inline datastream" do
    before do 
      class ModsArticle3 < ActiveFedora::Base
        # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
        has_metadata :name => "descMetadata", :type => Hydra::ModsArticleDatastream, :control_group => 'X'

      end

      @obj = ModsArticle3.new
      @obj.save
      @obj.descMetadata.should be_inline
    end
    after do
      @obj.destroy
      Object.send(:remove_const, :ModsArticle3)
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
        @pid = "test:fixture_mods_article2"
        @test_object = ModsArticle3.find(@pid)

        @test_object.descMetadata.ng_xml = @test_object.descMetadata.ng_xml
        @test_object.descMetadata.should_not be_changed
      end

      it "should not be changed if there are minor differences in whitespace" do
        obj = ModsArticle3.new
        obj.descMetadata.content = "<a>1</a>"
        obj.save
        obj.descMetadata.should_not be_changed
        obj.descMetadata.content = "<a>1</a>\n"
        obj.descMetadata.should_not be_changed
      end
    end
  end


  describe "an instance that is a managed datastream" do
    before(:all) do
      class ModsArticle2 < ActiveFedora::Base
        # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
        has_metadata :name => "descMetadata", :type => Hydra::ModsArticleDatastream
      end
    end

    after(:all) do
      Object.send(:remove_const, :ModsArticle2)
    end

    describe "#changed?" do
      it "should not be changed if the new xml matches the old xml" do
        @pid = "test:fixture_mods_article2"
        @test_object = ModsArticle2.find(@pid)

        @test_object.descMetadata.ng_xml = @test_object.descMetadata.ng_xml
        @test_object.descMetadata.should_not be_changed
      end

      it "should be changed if there are minor differences in whitespace" do
        obj = ModsArticle2.new
        obj.descMetadata.content = "<a>1</a>"
        obj.save
        obj.descMetadata.should_not be_changed
        obj.descMetadata.content = "<a>1</a>\n"
        obj.descMetadata.should be_changed
      end
    end



    describe "empty datastream content" do
      it "should not break when there is empty datastream content" do
        obj = ModsArticle2.new
        obj.descMetadata.content = ""
        obj.save

      end
    end

    describe '.term_values' do
      before do
        @pid = "test:fixture_mods_article2"
        @test_object = ModsArticle2.find(@pid)
        @test_object.descMetadata.content = File.read(fixture('mods_articles/mods_article1.xml'))
        @test_object.save
        @test_object = ModsArticle2.find(@pid)
        @test_solr_object = ActiveFedora::Base.load_instance_from_solr(@pid)
      end

      it "should return the same values whether getting from solr or Fedora" do
        @test_solr_object.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
        @test_solr_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
        @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
        @test_solr_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
        @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
        @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
        ar = @test_solr_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
        ar.length.should == 4
        ar.include?("Creator").should == true
        ar.include?("Contributor").should == true
        ar.include?("Funder").should == true
        ar.include?("Host").should == true

        @test_object.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
        @test_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
        @test_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
        @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
        @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
        @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
        ar = @test_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
        ar.length.should == 4
        ar.include?("Creator").should == true
        ar.include?("Contributor").should == true
        ar.include?("Funder").should == true
        ar.include?("Host").should == true
      end
    end
    
    describe '.update_values' do
      before do
        @pid = "test:fixture_mods_article2"
        @test_object = ModsArticle2.find(@pid)
        @test_object.descMetadata.content = File.read(fixture('mods_articles/mods_article1.xml'))
        @test_object.save
        @test_object = ModsArticle2.find(@pid)
      end

      it "should not be dirty after .update_values is saved" do
        @test_object.datastreams["descMetadata"].update_values([{:name=>0},{:role=>0},:text] =>"Funder")
        @test_object.datastreams["descMetadata"].should be_changed
        @test_object.save
        @test_object.datastreams["descMetadata"].should_not be_changed
        @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Funder"]
      end    
    end


    describe ".to_solr" do
      before do
        object = ModsArticle2.new
        object.descMetadata.journal.issue.publication_date = Date.parse('2012-11-02')
        object.save!
        @test_object = ModsArticle2.find(object.pid)

      end
      it "should solrize terms with :type=>'date' to *_dt solr terms" do
        @test_object.to_solr[ActiveFedora::SolrService.solr_name('mods_journal_issue_publication_date', type: :date)].should == ['2012-11-02T00:00:00Z']
      end
    end
  end
end
