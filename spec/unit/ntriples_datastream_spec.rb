require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  describe "an instance with content" do
    before do 
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
        map_predicates do |map|
          map.created(:in => RDF::DC)
          map.title(:in => RDF::DC)
          map.publisher(:in => RDF::DC)
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
    it "should return fields that are not TermProxies" do
      @subject.created.should be_kind_of Array
    end
    it "should have method missing" do
      lambda{@subject.frank}.should raise_exception ActiveFedora::UnregisteredPredicateError
    end

    it "should set fields" do
      @subject.publisher = "St. Martin's Press"
      @subject.publisher.should == ["St. Martin's Press"]
    end
    it "should append fields" do
      @subject.publisher << "St. Martin's Press"
      @subject.publisher.should == ["Penn State", "St. Martin's Press"]
    end
    it "should delete fields" do
      @subject.related_url.delete("http://google.com/")
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
        register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
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
      @subject.stubs(:pid => 'test:1')
      @subject.stubs(:new? => false)
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
        register_vocabularies RDF::DC
        map_predicates do |map|
          map.publisher(:in => RDF::DC)
        end
      end
      @subject = MyDatastream.new(@inner_object, 'mixed_rdf')
      @subject.stubs(:pid => 'test:1')
    end
    after(:each) do
      Object.send(:remove_const, :MyDatastream)
    end
    it "should save and reload" do
      @subject.publisher = ["St. Martin's Press"]
      @subject.save
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
        register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
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
      @subject.stubs(:pid => 'test:1')
      @subject.stubs(:new? => false)
      @sample_fields = {:my_datastream__publisher => {:values => ["publisher1"], :type => :string, :behaviors => [:facetable, :sortable, :searchable, :displayable]}, 
        :my_datastream__based_near => {:values => ["coverage1", "coverage2"], :type => :text, :behaviors => [:displayable, :facetable, :searchable]}, 
        :my_datastream__created => {:values => "fake-date", :type => :date, :behaviors => [:sortable, :displayable]},
        :my_datastream__title => {:values => "fake-title", :type => :text, :behaviors => [:searchable, :displayable, :sortable]},
        :my_datastream__related_url => {:values => "http://example.org/", :type =>:string, :behaviors => [:searchable]},
        :my_datastream__empty_field => {:values => [], :type => :string, :behaviors => [:searchable]}
      } 
    end
    after(:all) do
      # Revert to default mappings after running tests
      ActiveFedora::SolrService.load_mappings
    end
    it "should provide .to_solr and return a SolrDocument" do
      @subject.should respond_to(:to_solr)
      @subject.to_solr.should be_kind_of(Hash)
    end
    it "should provide .fields and return a Hash" do
      @subject.should respond_to(:fields)
      @subject.fields.should be_kind_of(Hash)
    end   
    it "should optionally allow you to provide the Solr::Document to add fields to and return that document when done" do
      doc = Hash.new
      @subject.to_solr(doc).should == doc
    end
    it "should iterate through @fields hash" do
      @subject.expects(:fields).returns(@sample_fields)
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
    end
    it 'should append create keys in format field_name + _ + field_type' do
      @subject.stubs(:fields).returns(@sample_fields)
      
      #should have these            
      @subject.to_solr["my_datastream__publisher_t"].should_not be_nil
      @subject.to_solr["my_datastream__based_near_t"].should_not be_nil
      @subject.to_solr["my_datastream__title_t"].should_not be_nil
      @subject.to_solr["my_datastream__related_url_t"].should_not be_nil

      #should NOT have these
      @subject.to_solr["my_datastream__narrator"].should be_nil
      @subject.to_solr["my_datastream__empty_field"].should be_nil
      @subject.to_solr["my_datastream__creator"].should be_nil
    end
    it "should use Solr mappings to generate field names" do
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      @subject.stubs(:fields).returns(@sample_fields)
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
        @obj.created = "2012-03-04"
        @obj.title = "Of Mice and Men, The Sequel"
        @obj.publisher = "Bob's Blogtastic Publishing"
        @obj.based_near = ["Tacoma, WA", "Renton, WA"]
        @obj.related_url = "http://example.org/blogtastic/"
        @obj.rights = "Totally open, y'all"
        @obj.save
      end
      describe '#save' do
        it "should set dirty? to false" do
          @obj.dirty?.should be_false
          @obj.title = "something"
          @obj.dirty?.should be_true
          @obj.save
          @obj.dirty?.should be_false
        end
      end
      describe '.content=' do
        it "should update the content and graph, marking the datastream as changed" do
          mock_repo = mock('repository')
          mock_repo.expects(:datastream_dissemination).with(:pid => 'test:123', 
                                                            :dsid => 'solr_rdf')
          sample_rdf = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
          @obj.stubs(:pid).returns('test:123')
          @obj.stubs(:repository).returns(mock_repo)
          @obj.should_not be_changed
          @obj.content.should_not be_equivalent_to(sample_rdf)
          @obj.content = sample_rdf
          @obj.should be_changed
          @obj.content.should be_equivalent_to(sample_rdf)
        end
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
        it "should return the right # of fields" do
          @obj.fields.keys.count.should == 5
        end
        it "should return the right fields" do
          @obj.fields.keys.should include(:my_datastream__related_url)
          @obj.fields.keys.should include(:my_datastream__publisher)
          @obj.fields.keys.should include(:my_datastream__created)
          @obj.fields.keys.should include(:my_datastream__title)
          @obj.fields.keys.should include(:my_datastream__based_near)
        end
        it "should return the right values" do
          @obj.fields[:my_datastream__related_url][:values].should == ["http://example.org/blogtastic/"]
        end
        it "should return the right type information" do
          @obj.fields[:my_datastream__created][:type].should == :date
        end
        it "should return multi-value fields as expected" do
          @obj.fields[:my_datastream__based_near][:values].count.should == 2
          @obj.fields[:my_datastream__based_near][:values].should include("Tacoma, WA")
          @obj.fields[:my_datastream__based_near][:values].should include("Renton, WA")
        end
        it "should solrize even when the object is not new" do
          foo = Foo.new
          foo.expects(:update_index).once
          foo.title = "title1"
          foo.save
          foo = Foo.find(foo.pid)
          foo.expects(:update_index).once
          foo.publisher = "Allah2"
          foo.title = "The Work2"
          foo.save  
        end
      end
      describe ".to_solr()" do
        it "should return the right # of fields" do
          @obj.to_solr.keys.count.should == 13
        end
        it "should return the right fields" do
          @obj.to_solr.keys.should include("my_datastream__related_url_t")
          @obj.to_solr.keys.should include("my_datastream__publisher_t")
          @obj.to_solr.keys.should include("my_datastream__publisher_sort")
          @obj.to_solr.keys.should include("my_datastream__publisher_display")
          @obj.to_solr.keys.should include("my_datastream__publisher_facet")
          @obj.to_solr.keys.should include("my_datastream__created_sort")
          @obj.to_solr.keys.should include("my_datastream__created_display")
          @obj.to_solr.keys.should include("my_datastream__title_t")
          @obj.to_solr.keys.should include("my_datastream__title_sort")
          @obj.to_solr.keys.should include("my_datastream__title_display")
          @obj.to_solr.keys.should include("my_datastream__based_near_t")
          @obj.to_solr.keys.should include("my_datastream__based_near_facet")
          @obj.to_solr.keys.should include("my_datastream__based_near_display")
        end
        it "should return the right values" do
          @obj.to_solr["my_datastream__related_url_t"].should == ["http://example.org/blogtastic/"]
        end
        it "should return multi-value fields as expected" do
          @obj.to_solr["my_datastream__based_near_t"].count.should == 2
          @obj.to_solr["my_datastream__based_near_t"].should include("Tacoma, WA")
          @obj.to_solr["my_datastream__based_near_t"].should include("Renton, WA")
        end
      end
    end
  end
end
