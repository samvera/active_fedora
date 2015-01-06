require 'spec_helper'
require "solrizer"

describe ActiveFedora::OmDatastream do

  before(:all) do
    class HydrangeaArticle2 < ActiveFedora::Base
      # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
      has_metadata :name => "descMetadata", :type => Hydra::ModsArticleDatastream

      # A place to put extra metadata values
      has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
        m.field 'collection', :string
      end
    end

  end

  after(:all) do
    Object.send(:remove_const, :HydrangeaArticle2)
  end

  describe "#changed?" do
    it "should not be changed if the new xml matches the old xml" do
      @pid = "hydrangea:fixture_mods_article2"
      @test_object = HydrangeaArticle2.find(@pid)

      @test_object.descMetadata.ng_xml = @test_object.descMetadata.ng_xml
      expect(@test_object.descMetadata).not_to be_changed
    end


    it "should not be changed if there are minor differences in whitespace" do

      obj = HydrangeaArticle2.new
      obj.descMetadata.content = "<a>1</a>"
      obj.save
      expect(obj.descMetadata).not_to be_changed
      obj.descMetadata.content = "<a>1</a>\n"
      expect(obj.descMetadata).not_to be_changed

    end
  end

  describe "empty datastream content" do
    it "should not break when there is empty datastream content" do
      obj = HydrangeaArticle2.new
      obj.descMetadata.content = ""
      obj.save

    end
  end

  describe '.term_values' do
    before do
      @pid = "hydrangea:fixture_mods_article2"
      @test_object = HydrangeaArticle2.find(@pid)
      @test_object.descMetadata.content = File.read(fixture('mods_articles/hydrangea_article1.xml'))
      @test_object.save
      @test_object = HydrangeaArticle2.find(@pid)
      @test_solr_object = ActiveFedora::Base.load_instance_from_solr(@pid)
    end

    it "should return the same values whether getting from solr or Fedora" do
      expect(@test_solr_object.datastreams["descMetadata"].term_values(:name,:role,:text)).to eq(["Creator","Contributor","Funder","Host"])
      expect(@test_solr_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text)).to eq(["Creator"])
      expect(@test_solr_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text)).to eq(["Contributor"])
      expect(@test_solr_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text)).to eq(["Creator"])
      expect(@test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text)).to eq(["Contributor"])
      expect(@test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text)).to eq([])
      ar = @test_solr_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
      expect(ar.length).to eq(4)
      expect(ar.include?("Creator")).to eq(true)
      expect(ar.include?("Contributor")).to eq(true)
      expect(ar.include?("Funder")).to eq(true)
      expect(ar.include?("Host")).to eq(true)

      expect(@test_object.datastreams["descMetadata"].term_values(:name,:role,:text)).to eq(["Creator","Contributor","Funder","Host"])
      expect(@test_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text)).to eq(["Creator"])
      expect(@test_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text)).to eq(["Contributor"])
      expect(@test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text)).to eq(["Creator"])
      expect(@test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text)).to eq(["Contributor"])
      expect(@test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text)).to eq([])
      ar = @test_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
      expect(ar.length).to eq(4)
      expect(ar.include?("Creator")).to eq(true)
      expect(ar.include?("Contributor")).to eq(true)
      expect(ar.include?("Funder")).to eq(true)
      expect(ar.include?("Host")).to eq(true)
    end
  end

  describe '.update_values' do
    before do
      @pid = "hydrangea:fixture_mods_article2"
      @test_object = HydrangeaArticle2.find(@pid)
      @test_object.descMetadata.content = File.read(fixture('mods_articles/hydrangea_article1.xml'))
      @test_object.save
      @test_object = HydrangeaArticle2.find(@pid)
    end

    it "should not be dirty after .update_values is saved" do
      @test_object.datastreams["descMetadata"].update_values([{:name=>0},{:role=>0},:text] =>"Funder")
      expect(@test_object.datastreams["descMetadata"]).to be_changed
      @test_object.save
      expect(@test_object.datastreams["descMetadata"]).not_to be_changed
      expect(@test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text)).to eq(["Funder"])
    end
  end


  describe ".to_solr" do
    before do
      object = HydrangeaArticle2.new
      object.descMetadata.journal.issue.publication_date = Date.parse('2012-11-02')
      object.save!
      @test_object = HydrangeaArticle2.find(object.pid)

    end
    it "should solrize terms with :type=>'date' to *_dt solr terms" do
      expect(@test_object.to_solr[ActiveFedora::SolrService.solr_name('mods_journal_issue_publication_date', :date)]).to eq(['2012-11-02T00:00:00Z'])
    end
  end
end
