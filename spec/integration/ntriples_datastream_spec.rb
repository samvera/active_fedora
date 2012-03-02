require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
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

    loaded = RdfTest.find(@subject.pid)
    loaded.title.should == 'War and Peace'
    loaded.based_near.should == ['Moscow, Russia']
    loaded.related_url.should == ['http://en.wikipedia.org/wiki/War_and_Peace']
    loaded.part.should == ['this is a part']
  end
  it "should append values" do
    # this is how I'd like it to work (but it doesn't):
    @subject.part << "thing 1"
    @subject.part << "thing 2"
    @subject.save
    # this is how I work around it:
    #mf = RdfTest.find(@subject.pid)
    #mf.part = @subject.part.push("thing 2")
    #mf.save

    loaded = RdfTest.find(@subject.pid)
    loaded.part.should include("thing 1")
    loaded.part.should include("thing 2")
  end

end
