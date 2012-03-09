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
      @subject = MyDatastream.new(@inner_object, 'mixed_rdf')
      @subject.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
      @subject.stubs(:pid => 'test:1')
      @subject.stubs(:new? => false)
    end
    it "should have controlGroup" do
      @subject.controlGroup.should == 'M'
    end
    it "should have mimeType" do
      @subject.mimeType.should == 'text/plain'
    end
    it "should have dsid" do
      @subject.dsid.should == 'mixed_rdf'
    end
    it "should have fields" do
      @subject.created.should == ["2010-12-31"]
      @subject.title.should == ["Title of work"]
      @subject.publisher.should == ["Penn State"]
      @subject.based_near.should == ["New York, NY, US"]
      @subject.related_url.should == ["http://google.com/"]
    end
    it "should return fields that are TermProxies" do
      @subject.created.should be_kind_of ActiveFedora::RDFDatastream::TermProxy
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
      @subject.publisher.to_s.should == ""
      @subject.publisher = "Bob"
      @subject.publisher.to_s.should == "Bob"
      @subject.publisher << "Jim"
      @subject.publisher.to_s.should == "BobJim"
    end
 end

  describe "solr integration" do
    before(:all) do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
        map_predicates do |map|
          map.created(:in => RDF::DC, :index_as => {:type => :date,
                        :behaviors => [:sortable, :displayable]})
          map.title(:in => RDF::DC, :index_as => {:type => :text, 
                      :behaviors => [:searchable, :displayable, :sortable]})
          map.publisher(:in => RDF::DC, :index_as => {
                          :behaviors => [:facetable, :sortable, :searchable, :displayable]})
          map.based_near(:in => RDF::FOAF, :index_as => {:type => :text,
                           :behaviors => [:displayable, :facetable, :searchable]})
          map.related_url(:to => "seeAlso", :in => RDF::RDFS,
                          :index_as => {:type => :string})
          map.rights(:in => RDF::DC)
        end
      end
      @subject = MyDatastream.new(@inner_object, 'solr_rdf')
      @subject.content = File.new('spec/fixtures/solr_rdf_descMetadata.nt').read
      @subject.stubs(:pid => 'test:1')
      @subject.stubs(:new? => false)
      @sample_fields = {:publisher => {:values => ["publisher1"], :type => :string, :behaviors => [:facetable, :sortable, :searchable, :displayable]}, 
        :based_near => {:values => ["coverage1", "coverage2"], :type => :text, :behaviors => [:displayable, :facetable, :searchable]}, 
        :created => {:values => "fake-date", :type => :date, :behaviors => [:sortable, :displayable]},
        :title => {:values => "fake-title", :type => :text, :behaviors => [:searchable, :displayable, :sortable]},
        :related_url => {:values => "http://example.org/", :type =>:string, :behaviors => [:searchable]},
        :empty_field => {:values => [], :type => :string, :behaviors => [:searchable]}
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
      solr_doc["publisher_t"].should == ["publisher1"]
      solr_doc["publisher_sort"].should == ["publisher1"]
      solr_doc["publisher_display"].should == ["publisher1"]
      solr_doc["publisher_facet"].should == ["publisher1"]
      solr_doc["based_near_t"].sort.should == ["coverage1", "coverage2"]
      solr_doc["based_near_display"].sort.should == ["coverage1", "coverage2"]
      solr_doc["based_near_facet"].sort.should == ["coverage1", "coverage2"]
      solr_doc["created_sort"].should == ["fake-date"]
      solr_doc["created_display"].should == ["fake-date"]
      solr_doc["title_t"].should == ["fake-title"]
      solr_doc["title_sort"].should == ["fake-title"]
      solr_doc["title_display"].should == ["fake-title"]
      solr_doc["related_url_t"].should == ["http://example.org/"]
      solr_doc["empty_field_t"].should be_nil
    end
    it "should allow multiple values for a single field"
    it 'should append create keys in format field_name + _ + field_type' do
      @subject.stubs(:fields).returns(@sample_fields)
      
      #should have these            
      @subject.to_solr["publisher_t"].should_not be_nil
      @subject.to_solr["based_near_t"].should_not be_nil
      @subject.to_solr["title_t"].should_not be_nil
      @subject.to_solr["related_url_t"].should_not be_nil

      #should NOT have these
      @subject.to_solr["narrator"].should be_nil
      @subject.to_solr["empty_field"].should be_nil
      @subject.to_solr["creator"].should be_nil
    end
    it "should use Solr mappings to generate field names" do
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      @subject.stubs(:fields).returns(@sample_fields)
      solr_doc =  @subject.to_solr

      #should have these            
      solr_doc["publisher_field"].should == ["publisher1"]
      solr_doc["based_near_field"].sort.should == ["coverage1", "coverage2"]
      solr_doc["created_display"].should == ["fake-date"]
      solr_doc["title_field"].should == ["fake-title"]
        
      solr_doc["title_t"].should be_nil
      solr_doc["publisher_t"].should be_nil
      solr_doc["based_near_t"].should be_nil
      solr_doc["created_dt"].should be_nil
      
      # Reload default mappings
      ActiveFedora::SolrService.load_mappings
    end
    describe "with an actual object" do
      before(:all) do
        @obj = MyDatastream.new(@inner_object, 'solr_rdf')
        @obj.created = "2012-03-04"
        @obj.title = "Of Mice and Men, The Sequel"
        @obj.publisher = "Bob's Blogtastic Publishing"
        @obj.based_near = ["Tacoma, WA", "Renton, WA"]
        @obj.related_url = "http://example.org/blogtastic/"
        @obj.rights = "Totally open, y'all"
        @obj.save
      end
      describe ".fields()" do
        it "should return the right # of fields" do
          @obj.fields.keys.count.should == 5
        end
        it "should return the right fields" do
          @obj.fields.keys.should include(:related_url)
          @obj.fields.keys.should include(:publisher)
          @obj.fields.keys.should include(:created)
          @obj.fields.keys.should include(:title)
          @obj.fields.keys.should include(:based_near)
        end
        it "should return the right values" do
          @obj.fields[:related_url][:values].should == ["http://example.org/blogtastic/"]
        end
        it "should return the right type information" do
          @obj.fields[:created][:type].should == :date
        end
        it "should return multi-value fields as expected" do
          @obj.fields[:based_near][:values].count.should == 2
          @obj.fields[:based_near][:values].should include("Tacoma, WA")
          @obj.fields[:based_near][:values].should include("Renton, WA")
        end
      end
      describe ".to_solr()" do
        it "should return the right # of fields" do
          @obj.to_solr.keys.count.should == 13
        end
        it "should return the right fields" do
          @obj.to_solr.keys.should include("related_url_t")
          @obj.to_solr.keys.should include("publisher_t")
          @obj.to_solr.keys.should include("publisher_sort")
          @obj.to_solr.keys.should include("publisher_display")
          @obj.to_solr.keys.should include("publisher_facet")
          @obj.to_solr.keys.should include("created_sort")
          @obj.to_solr.keys.should include("created_display")
          @obj.to_solr.keys.should include("title_t")
          @obj.to_solr.keys.should include("title_sort")
          @obj.to_solr.keys.should include("title_display")
          @obj.to_solr.keys.should include("based_near_t")
          @obj.to_solr.keys.should include("based_near_facet")
          @obj.to_solr.keys.should include("based_near_display")
        end
        it "should return the right values" do
          @obj.to_solr["related_url_t"].should == ["http://example.org/blogtastic/"]
        end
        it "should return multi-value fields as expected" do
          @obj.to_solr["based_near_t"].count.should == 2
          @obj.to_solr["based_near_t"].should include("Tacoma, WA")
          @obj.to_solr["based_near_t"].should include("Renton, WA")
        end
      end
    end
  end
end
