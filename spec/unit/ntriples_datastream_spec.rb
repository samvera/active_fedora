require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  describe "an instance with content" do
    before do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        property :created, predicate: RDF::DC.created
        property :title, predicate: RDF::DC.title
        property :publisher, predicate: RDF::DC.publisher
        property :creator, predicate: RDF::DC.creator
        property :educationLevel, predicate: RDF::DC.educationLevel
        property :based_near, predicate: RDF::FOAF.based_near
        property :related_url, predicate: RDF::RDFS.seeAlso
      end
      @subject = MyDatastream.new(double('inner object', pid: 'test:1', :new_record? => true), 'descMetadata')
      @subject.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
    end
    after do
      Object.send(:remove_const, :MyDatastream)
    end
    it "should have a subject" do
      @subject.rdf_subject.should == "info:fedora/test:1"
    end
    it "should have controlGroup" do
      @subject.controlGroup.should == 'M'
    end
    it "should have mimeType" do
      @subject.mimeType.should == 'text/plain'
    end
    it "should have dsid" do
      @subject.dsid.should == 'descMetadata'
    end
    it "should have fields" do
      @subject.created.should == [Date.parse('2010-12-31')]
      @subject.title.should == ["Title of work"]
      @subject.publisher.should == ["Penn State"]
      @subject.based_near.should == ["New York, NY, US"]
      @subject.related_url.length.should == 1
      @subject.related_url.first.rdf_subject.should == "http://google.com/"
    end

    it "should be able to call enumerable methods on the fields" do
      @subject.title.join(', ').should == "Title of work"
      @subject.title.count.should == 1
      @subject.title.size.should == 1
      @subject.title[0].should == "Title of work"
      @subject.title.to_a.should == ["Title of work"]
      val = []
      @subject.title.each_with_index {|v, i| val << "#{i}. #{v}"}
      val.should == ["0. Title of work"]
    end

    it "should return fields that are not TermProxies" do
      @subject.created.should be_kind_of Array
    end
    it "should have method missing" do
      lambda{@subject.frank}.should raise_exception NoMethodError
    end

    it "should set fields" do
      @subject.publisher = "St. Martin's Press"
      @subject.publisher.should == ["St. Martin's Press"]
    end
    it "should set rdf literal fields" do
      @subject.creator = RDF.Literal("Geoff Ryman")
      @subject.creator.should == ["Geoff Ryman"]
    end
    it "should append fields" do
      @subject.publisher << "St. Martin's Press"
      @subject.publisher.should == ["Penn State", "St. Martin's Press"]
    end
    it "should delete fields" do
      @subject.related_url.delete(RDF::URI("http://google.com/"))
      @subject.related_url.should == []
    end
  end

  describe "some dummy instances" do
    before do
      @one = ActiveFedora::RDFDatastream.new('fakepid', 'myFoobar')
      @two = ActiveFedora::RDFDatastream.new('fakepid', 'myQuix')
    end
    it "should generate predictable prexies" do
      @one.apply_prefix("baz").should == 'my_foobar__baz'
      @two.apply_prefix("baz").should == 'my_quix__baz'
    end
  end

  describe "an instance with a custom subject" do
    before do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        rdf_subject { |ds| "info:fedora/#{ds.pid}/content" }
        property :created, predicate: RDF::DC.created
        property :title, predicate: RDF::DC.title
        property :publisher, predicate: RDF::DC.publisher
        property :based_near, predicate: RDF::FOAF.based_near
        property :related_url, predicate: RDF::RDFS.seeAlso
      end
      @inner_object = double('inner object', pid: 'test:1', :new_record? => true)
      @subject = MyDatastream.new(@inner_object, 'mixed_rdf')
      @subject.stub(pid: 'test:1')
      @subject.stub(:new_record? => false)
      @subject.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
    end

    after do
      Object.send(:remove_const, :MyDatastream)
    end

    it "should have fields" do
      @subject.title.should == ["Title of datastream"]
    end

    it "should have a custom subject" do
      @subject.rdf_subject.should == 'info:fedora/test:1/content'
    end
  end

  describe "a new instance" do
    before(:each) do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        property :publisher, predicate: RDF::DC.publisher
      end
      @subject = MyDatastream.new(@inner_object, 'mixed_rdf')
      @subject.stub(pid: 'test:1', repository: ActiveFedora::Base.connection_for_pid(0))
    end
    after(:each) do
      Object.send(:remove_const, :MyDatastream)
    end
    it "should support to_s method" do
      @subject.publisher.to_s.should == [].to_s
      @subject.publisher = "Bob"
      @subject.publisher.to_s.should == ["Bob"].to_s
      @subject.publisher << "Jim"
      @subject.publisher.to_s.should == ["Bob", "Jim"].to_s
    end
 end

  describe "solr integration" do
    before(:all) do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        property :created, predicate: RDF::DC.created do |index|
          index.as :sortable, :displayable
          index.type :date
        end
        property :title, predicate: RDF::DC.title do |index|
          index.as :stored_searchable, :sortable
          index.type :text
        end
        property :publisher, predicate: RDF::DC.publisher do |index|
          index.as :facetable, :sortable, :stored_searchable
        end
        property :based_near, predicate: RDF::FOAF.based_near do |index|
          index.as :facetable, :stored_searchable
          index.type :text
        end
        property :related_url, predicate: RDF::RDFS.seeAlso do |index|
          index.as :stored_searchable
        end
        property :rights, predicate: RDF::DC.rights
      end
      @subject = MyDatastream.new(@inner_object, 'solr_rdf')
      @subject.content = File.new('spec/fixtures/solr_rdf_descMetadata.nt').read
    end
    after(:all) do
      Object.send(:remove_const, :MyDatastream)
    end
    before(:each) do
      @subject.stub(pid: 'test:1')
      @subject.serialize
    end
    it "should provide .to_solr and return a SolrDocument" do
      @subject.should respond_to(:to_solr)
      @subject.to_solr.should be_kind_of(Hash)
    end

    it "should have a solr_name method" do
      expect(MyDatastream.new(nil, 'descMetadata').primary_solr_name(:based_near)).to eq 'desc_metadata__based_near_tesim'
      expect(MyDatastream.new(nil, 'props').primary_solr_name(:title)).to eq 'props__title_tesim'
    end

    it "should optionally allow you to provide the Solr::Document to add fields to and return that document when done" do
      doc = Hash.new
      @subject.to_solr(doc).should == doc
    end
    it "should iterate through @fields hash" do
      solr_doc = @subject.to_solr
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__publisher", type: :string)].should == ["publisher1"]
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__publisher", :sortable)].should == "publisher1"
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__publisher", :facetable)].should == ["publisher1"]
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__based_near", type: :string)].should == ["coverage1", "coverage2"]
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__based_near", :facetable)].should == ["coverage1", "coverage2"]
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__created", :sortable, type: :date)].should == "2009-10-10T00:00:00Z"
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__created", :displayable)].should == ["2009-10-10"]
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__title", type: :string)].should == ["fake-title"]
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__title", :sortable)].should == "fake-title"
      solr_doc[ActiveFedora::SolrService.solr_name("solr_rdf__related_url", type: :string)].should == ["http://example.org/"]
    end

    describe "with an actual object" do
      before(:each) do
        class Foo < ActiveFedora::Base
          has_metadata "descMetadata", type: MyDatastream
          has_attributes :created, :title, :publisher, :based_near, :related_url, :rights, datastream: :descMetadata, multiple: true
        end
        @obj = MyDatastream.new(@inner_object, 'solr_rdf')
        repository = double()
          @obj.stub(repository: repository, pid: 'test:1')
          repository.stub(:modify_datastream)
          repository.stub(:add_datastream)
        @obj.created = Date.parse("2012-03-04")
        @obj.title = "Of Mice and Men, The Sequel"
        @obj.publisher = "Bob's Blogtastic Publishing"
        @obj.based_near = ["Tacoma, WA", "Renton, WA"]
        @obj.related_url = "http://example.org/blogtastic/"
        @obj.rights = "Totally open, y'all"
        @obj.save
      end
      after do
        Object.send(:remove_const, :Foo)
      end


      describe ".fields()" do
        it "should return the right fields" do
          @obj.send(:fields).keys.should == ["created", "title", "publisher", "based_near", "related_url"]
        end
        it "should return the right values" do
          fields = @obj.send(:fields)
          fields[:related_url][:values].should == ["http://example.org/blogtastic/"]
          fields[:based_near][:values].should == ["Tacoma, WA", "Renton, WA"]
        end
        it "should return the right type information" do
          fields = @obj.send(:fields)
          fields[:created][:type].should == :date
        end
      end
      describe ".to_solr()" do
        it "should return the right fields" do
          @obj.to_solr.keys.should include(ActiveFedora::SolrService.solr_name("solr_rdf__related_url", type: :string),
                ActiveFedora::SolrService.solr_name("solr_rdf__publisher", type: :string),
                ActiveFedora::SolrService.solr_name("solr_rdf__publisher", :sortable),
                ActiveFedora::SolrService.solr_name("solr_rdf__publisher", :facetable),
                ActiveFedora::SolrService.solr_name("solr_rdf__created", :sortable, type: :date),
                ActiveFedora::SolrService.solr_name("solr_rdf__created", :displayable),
                ActiveFedora::SolrService.solr_name("solr_rdf__title", type: :string),
                ActiveFedora::SolrService.solr_name("solr_rdf__title", :sortable),
                ActiveFedora::SolrService.solr_name("solr_rdf__based_near", type: :string),
                ActiveFedora::SolrService.solr_name("solr_rdf__based_near", :facetable))

        end

        it "should return the right values" do
          @obj.to_solr[ActiveFedora::SolrService.solr_name("solr_rdf__related_url", type: :string)].should == ["http://example.org/blogtastic/"]
          @obj.to_solr[ActiveFedora::SolrService.solr_name("solr_rdf__based_near", type: :string)].should == ["Tacoma, WA","Renton, WA"]
        end
      end
    end
  end
end
