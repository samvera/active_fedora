require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  describe "an instance with content" do
    before do 
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        map_predicates do |map|
          map.created(:in => RDF::DC)
          map.title(:in => RDF::DC)
          map.publisher(:in => RDF::DC)
          map.creator(:in => RDF::DC)
          map.based_near(:in => RDF::FOAF)
          map.related_url(:to => "seeAlso", :in => RDF::RDFS)
        end
      end
      class Foo < ActiveFedora::Base
        has_metadata :name => "descMetadata", :type => MyDatastream
        delegate :created, :to => :descMetadata
        delegate :title, :to => :descMetadata
        delegate :publisher, :to => :descMetadata
        delegate :based_near, :to => :descMetadata
        delegate :related_url, :to => :descMetadata
      end
      @object = Foo.new(:pid => 'test:1')
      @subject = @object.descMetadata
      @subject.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
      @object.save
    end
    after do
      @object.delete
      Object.send(:remove_const, :MyDatastream)
      Object.send(:remove_const, :Foo)
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
      @subject.created.should == ["2010-12-31"]
      @subject.title.should == ["Title of work"]
      @subject.publisher.should == ["Penn State"]
      @subject.based_near.should == ["New York, NY, US"]
      @subject.related_url.should == ["http://google.com/"]
    end

    it "should delegate as_json to the fields" do
      @subject.title.as_json.should == ["Title of work"]
      @subject.title.to_json.should == "\[\"Title of work\"\]"
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
      class MyFoobarRDFDatastream < ActiveFedora::NtriplesRDFDatastream
      end
      class MyFoobarRdfDatastream < ActiveFedora::NtriplesRDFDatastream
      end
    end
    it "should generate predictable prexies" do
      MyFoobarRDFDatastream.prefix("baz").should == :my_foobar__baz
    end
    it "should generate prefixes case-insensitively" do
      MyFoobarRDFDatastream.prefix("quux").should == MyFoobarRdfDatastream.prefix("quux")
    end
  end

  describe "an instance with a custom subject" do
    before do 
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        rdf_subject { |ds| "info:fedora/#{ds.pid}/content" }
        map_predicates do |map|
          map.created(:in => RDF::DC)
          map.title(:in => RDF::DC)
          map.publisher(:in => RDF::DC)
          map.based_near(:in => RDF::FOAF)
          map.related_url(:to => "seeAlso", :in => RDF::RDFS)
        end
      end
      @subject = MyDatastream.new(@inner_object, 'mixed_rdf')
      @subject.stub(:pid => 'test:1')
      @subject.stub(:new? => false)
      @subject.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
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
        map_predicates do |map|
          map.publisher(:in => RDF::DC)
        end
      end
      @subject = MyDatastream.new(@inner_object, 'mixed_rdf')
      @subject.stub(:pid => 'test:1', :repository => ActiveFedora::Base.connection_for_pid(0))
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
        map_predicates do |map|
          map.created(:in => RDF::DC) do |index| 
            index.as :sortable, :displayable
            index.type :date
          end
          map.title(:in => RDF::DC) do |index|
            index.as :searchable, :displayable, :sortable
            index.type :text 
          end
          map.publisher(:in => RDF::DC) do |index| 
            index.as :facetable, :sortable, :searchable, :displayable
          end
          map.based_near(:in => RDF::FOAF) do |index|
            index.as :displayable, :facetable, :searchable 
            index.type :text
          end
          map.related_url(:to => "seeAlso", :in => RDF::RDFS) do |index|
            index.defaults
          end
          map.rights(:in => RDF::DC)
        end
      end
      @subject = MyDatastream.new(@inner_object, 'solr_rdf')
      @subject.content = File.new('spec/fixtures/solr_rdf_descMetadata.nt').read
    end
    before(:each) do  
      @subject.stub(:pid => 'test:1')
    end
    after(:all) do
      # Revert to default mappings after running tests
      ActiveFedora::SolrService.load_mappings
    end
    it "should provide .to_solr and return a SolrDocument" do
      @subject.should respond_to(:to_solr)
      @subject.to_solr.should be_kind_of(Hash)
    end
    it "should optionally allow you to provide the Solr::Document to add fields to and return that document when done" do
      doc = Hash.new
      @subject.to_solr(doc).should == doc
    end
    it "should iterate through @fields hash" do
      solr_doc = @subject.to_solr
      solr_doc["my_datastream__publisher_t"].should == ["publisher1"]
      solr_doc["my_datastream__publisher_sort"].should == ["publisher1"]
      solr_doc["my_datastream__publisher_display"].should == ["publisher1"]
      solr_doc["my_datastream__publisher_facet"].should == ["publisher1"]
      solr_doc["my_datastream__based_near_t"].sort.should == ["coverage1", "coverage2"]
      solr_doc["my_datastream__based_near_display"].sort.should == ["coverage1", "coverage2"]
      solr_doc["my_datastream__based_near_facet"].sort.should == ["coverage1", "coverage2"]
      solr_doc["my_datastream__created_sort"].should == ["fake-date"]
      solr_doc["my_datastream__created_display"].should == ["fake-date"]
      solr_doc["my_datastream__title_t"].should == ["fake-title"]
      solr_doc["my_datastream__title_sort"].should == ["fake-title"]
      solr_doc["my_datastream__title_display"].should == ["fake-title"]
      solr_doc["my_datastream__related_url_t"].should == ["http://example.org/"]
      solr_doc["my_datastream__empty_field_t"].should be_nil

      #should NOT have these
      solr_doc["my_datastream__narrator"].should be_nil
      solr_doc["my_datastream__empty_field"].should be_nil
      solr_doc["my_datastream__creator"].should be_nil
    end

    it "should use Solr mappings to generate field names" do
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      solr_doc =  @subject.to_solr

      #should have these            
      solr_doc["my_datastream__publisher_field"].should == ["publisher1"]
      solr_doc["my_datastream__based_near_field"].sort.should == ["coverage1", "coverage2"]
      solr_doc["my_datastream__created_display"].should == ["fake-date"]
      solr_doc["my_datastream__title_field"].should == ["fake-title"]
        
      solr_doc["my_datastream__title_t"].should be_nil
      solr_doc["my_datastream__publisher_t"].should be_nil
      solr_doc["my_datastream__based_near_t"].should be_nil
      solr_doc["my_datastream__created_dt"].should be_nil
      
      # Reload default mappings
      ActiveFedora::SolrService.load_mappings
    end
    describe "with an actual object" do
      before(:each) do
        class Foo < ActiveFedora::Base
          has_metadata :name => "descMetadata", :type => MyDatastream
          delegate :created, :to => :descMetadata
          delegate :title, :to => :descMetadata
          delegate :publisher, :to => :descMetadata
          delegate :based_near, :to => :descMetadata
          delegate :related_url, :to => :descMetadata
          delegate :rights, :to => :descMetadata
        end
        @obj = MyDatastream.new(@inner_object, 'solr_rdf')
        repository = mock()
          @obj.stub(:repository => repository, :pid => 'test:1')
          repository.stub(:modify_datastream)
          repository.stub(:add_datastream)
        @obj.created = "2012-03-04"
        @obj.title = "Of Mice and Men, The Sequel"
        @obj.publisher = "Bob's Blogtastic Publishing"
        @obj.based_near = ["Tacoma, WA", "Renton, WA"]
        @obj.related_url = "http://example.org/blogtastic/"
        @obj.rights = "Totally open, y'all"
        @obj.save
      end

      it "should save content properly upon save" do
        foo = Foo.new(:pid => 'test:1')
        foo.title = 'Hamlet'
        foo.save
        foo.title.should == ['Hamlet']
        foo.descMetadata.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
        foo.save
        foo.title.should == ['Title of work']
      end
      describe ".fields()" do
        it "should return the right fields" do
          @obj.send(:fields).keys.should == [:created, :title, :publisher, :based_near, :related_url]
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
        it "should solrize even when the object is not new" do
          foo = Foo.new
          foo.should_receive(:update_index).once
          foo.title = "title1"
          foo.save
          foo = Foo.find(foo.pid)
          foo.should_receive(:update_index).once
          foo.publisher = "Allah2"
          foo.title = "The Work2"
          foo.save  
        end
      end
      describe ".to_solr()" do
        it "should return the right fields" do
          @obj.to_solr.keys.count.should == 13
          @obj.to_solr.keys.should include("my_datastream__related_url_t", "my_datastream__publisher_t", "my_datastream__publisher_sort",
                "my_datastream__publisher_display", "my_datastream__publisher_facet", "my_datastream__created_sort",
                "my_datastream__created_display", "my_datastream__title_t", "my_datastream__title_sort", "my_datastream__title_display",
                "my_datastream__based_near_t", "my_datastream__based_near_facet", "my_datastream__based_near_display")
        end

        it "should return the right values" do
          @obj.to_solr["my_datastream__related_url_t"].should == ["http://example.org/blogtastic/"]
          @obj.to_solr["my_datastream__based_near_t"].should == ["Tacoma, WA","Renton, WA"]
        end
      end
    end
  end
end
