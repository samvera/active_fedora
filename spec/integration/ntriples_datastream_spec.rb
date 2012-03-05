require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
      map_predicates do |map|
        map.title(:in => RDF::DC)
        map.part(:to => "hasPart", :in => RDF::DC)
        map.based_near(:in => RDF::FOAF)
        map.related_url(:to => "seeAlso", :in => RDF::RDFS)
      end
    end
    class RdfTest < ActiveFedora::Base 
      has_metadata :name=>'rdf', :type=>MyDatastream
      delegate :based_near, :to=>'rdf'
      delegate :related_url, :to=>'rdf'
      delegate :part, :to=>'rdf'
      delegate :title, :to=>'rdf', :unique=>true
    end
    @subject = RdfTest.new
  end

  after do
    Object.send(:remove_const, :RdfTest)
    Object.send(:remove_const, :MyDatastream)
  end

  it "should set and recall values" do
    @subject.title = 'War and Peace'
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
  it "should delete values" do
    @subject.title = "Hamlet"
    @subject.related_url = "http://psu.edu/"
    @subject.related_url << "http://projecthydra.org/"
    @subject.save
    @subject.title.should == "Hamlet"
    @subject.related_url.should include("http://psu.edu/")
    @subject.related_url.should include("http://projecthydra.org/")
    @subject.title = ""
    @subject.related_url.delete("http://projecthydra.org/")
    @subject.save
    @subject.title.should be_nil
    @subject.related_url.should == ["http://psu.edu/"]
  end
end
