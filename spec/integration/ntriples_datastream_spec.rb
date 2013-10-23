require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      map_predicates do |map|
        map.title(:in => RDF::DC) do |index|
          index.as :stored_searchable, :facetable
        end
        map.date_uploaded(:to => "dateSubmitted", :in => RDF::DC) do |index|
          index.type :date
          index.as :stored_searchable, :sortable
        end
        map.part(:to => "hasPart", :in => RDF::DC)
        map.based_near(:in => RDF::FOAF)
        map.related_url(:to => "seeAlso", :in => RDF::RDFS)
      end
    end
    class RdfTest < ActiveFedora::Base 
      has_metadata :name=>'rdf', :type=>MyDatastream
      has_attributes :based_near, :related_url, :part, :date_uploaded, datastream: 'rdf', multiple: true
      has_attributes :title, datastream: 'rdf', multiple: false
    end
    @subject = RdfTest.new
  end

  subject {
    @subject
  }

  after do
    Object.send(:remove_const, :RdfTest)
    Object.send(:remove_const, :MyDatastream)
  end

  it "should not try to send an empty datastream" do
    @subject.save
  end

  it "should save content properly upon save" do
    foo = RdfTest.new(:pid=>'test:1') #Pid needs to match the subject in the loaded file
    foo.title = 'Hamlet'
    foo.save
    foo.title.should == 'Hamlet'
    foo.rdf.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
    foo.save
    foo.title.should == 'Title of work'
  end

  it "should delegate as_json to the fields" do
    @subject = RdfTest.new(title: "Title of work")
    @subject.rdf.title.as_json.should == ["Title of work"]
    @subject.rdf.title.to_json.should == "\[\"Title of work\"\]"
  end

  it "should solrize even when the object is not new" do
    foo = RdfTest.new
    foo.should_receive(:update_index).once
    foo.title = "title1"
    foo.save
    foo = RdfTest.find(foo.pid)
    foo.should_receive(:update_index).once
    foo.title = "The Work2"
    foo.save  
  end

  it "should serialize dates" do
    subject.date_uploaded = Date.parse('2012-11-02')
    subject.date_uploaded.first.should be_kind_of Date
    solr_document = subject.to_solr
    solr_document[ActiveFedora::SolrService.solr_name('rdf__date_uploaded', type: :date)].should == ['2012-11-02T00:00:00Z']
  end

  it "should produce a solr document" do
    @subject = RdfTest.new(title: "War and Peace")
    solr_document = @subject.to_solr
    solr_document[ActiveFedora::SolrService.solr_name('rdf__title', :facetable)].should == ["War and Peace"]
    solr_document[ActiveFedora::SolrService.solr_name('rdf__title', type: :string)].should == ["War and Peace"]
  end

  it "should set and recall values" do
    @subject.title = 'War and Peace'
    @subject.rdf.should be_changed
    @subject.based_near = "Moscow, Russia"
    @subject.related_url = "http://en.wikipedia.org/wiki/War_and_Peace"
    @subject.part = "this is a part"
    @subject.save
    @subject.title.should == 'War and Peace'
    @subject.based_near.should == ["Moscow, Russia"]
    @subject.related_url.should == ["http://en.wikipedia.org/wiki/War_and_Peace"]
    @subject.part.should == ["this is a part"]    
  end
  it "should set, persist, and recall values" do
    @subject.title = 'War and Peace'
    @subject.based_near = "Moscow, Russia"
    @subject.related_url = "http://en.wikipedia.org/wiki/War_and_Peace"
    @subject.part = "this is a part"
    @subject.save

    loaded = RdfTest.find(@subject.pid)
    loaded.title.should == 'War and Peace'
    loaded.based_near.should == ['Moscow, Russia']
    loaded.related_url.should == ['http://en.wikipedia.org/wiki/War_and_Peace']
    loaded.part.should == ['this is a part']
  end
  it "should set multiple values" do
    @subject.part = ["part 1", "part 2"]
    @subject.save

    loaded = RdfTest.find(@subject.pid)
    loaded.part.should == ['part 1', 'part 2']
  end
  it "should append values" do
    @subject.part = "thing 1"
    @subject.save

    @subject.part << "thing 2"
    @subject.part.should == ["thing 1", "thing 2"]
  end

  it "should be able to save a blank document" do
    @subject.title = ""
    @subject.save
  end

  it "should load n-triples into the graph" do
    ntrip = '<http://oregondigital.org/ns/62> <http://purl.org/dc/terms/type> "Image" .
<http://oregondigital.org/ns/62> <http://purl.org/dc/terms/spatial> "Benton County (Ore.)" .
'
    @subject.rdf.content = ntrip
    @subject.rdf.graph.dump(:ntriples).should == ntrip
  end

  describe "using rdf_subject" do
    before do
      # reopening existing class
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        rdf_subject { |ds| RDF::URI.new("http://oregondigital.org/ns/#{ds.pid.split(':')[1]}") }
        map_predicates do |map|
          map.type(:in => RDF::DC)
          map.spatial(:in => RDF::DC)
        end
      end
    end
    after do
      @subject.destroy
    end

    it "should write rdf with proper subjects" do
      @subject.inner_object.pid = 'test:99'
      @subject.rdf.type = "Frog"
      @subject.save!
      @subject.reload
      @subject.rdf.graph.dump(:ntriples).should == "<http://oregondigital.org/ns/99> <http://purl.org/dc/terms/type> \"Frog\" .\n"
      @subject.rdf.type == ['Frog']

    end

  end


  it "should delete values" do
    @subject.title = "Hamlet"
    @subject.related_url = "http://psu.edu/"
    @subject.related_url << "http://projecthydra.org/"

    @subject.title.should == "Hamlet"
    @subject.related_url.should include("http://psu.edu/")
    @subject.related_url.should include("http://projecthydra.org/")

    @subject.title = "" #empty string can be meaningful, don't assume delete.
    @subject.title.should == ''

    @subject.title = nil
    @subject.related_url.delete("http://projecthydra.org/")

    @subject.title.should be_nil
    @subject.related_url.should == ["http://psu.edu/"]
  end
  it "should delete multiple values at once" do
    @subject.part = "MacBeth"
    @subject.part << "Hamlet"
    @subject.part << "Romeo & Juliet"
    @subject.part.first.should == "MacBeth"
    @subject.part.delete("MacBeth", "Romeo & Juliet")
    @subject.part.should == ["Hamlet"]
    @subject.part.first.should == "Hamlet"
  end
  it "should ignore values to be deleted that do not exist" do
    @subject.part = ["title1", "title2", "title3"]
    @subject.part.delete("title2", "title4", "title6")
    @subject.part.should == ["title1", "title3"]
  end
  describe "term proxy methods" do
    before(:each) do
      class TitleDatastream < ActiveFedora::NtriplesRDFDatastream
        map_predicates { |map| map.title(:in => RDF::DC) }
      end
      class Foobar < ActiveFedora::Base 
        has_metadata :name=>'rdf', :type=>TitleDatastream
        has_attributes :title, datastream: 'rdf', multiple: true
      end
      @subject = Foobar.new
      @subject.title = ["title1", "title2", "title3"]
    end

    after(:each) do
      Object.send(:remove_const, :Foobar)
      Object.send(:remove_const, :TitleDatastream)
    end

    it "should support the count method to determine # of values" do
      @subject.title.count.should == 3
    end
    it "should iterate over multiple values" do
      @subject.title.should respond_to(:each)
    end
    it "should get the first value" do
      @subject.title.first.should == "title1"
    end
    it "should evaluate equality predictably" do
      @subject.title.should == ["title1", "title2", "title3"]
    end
    it "should support the empty? method" do
      @subject.title.should respond_to(:empty?)
      @subject.title.empty?.should be_false
      @subject.title.delete("title1", "title2", "title3")
      @subject.title.empty?.should be_true
    end
    it "should support the is_a? method" do
      @subject.title.is_a?(Array).should == true
    end
  end
end
