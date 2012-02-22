require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  before do
    class NtriplesMetadataDatastream < ActiveFedora::NtriplesRDFDatastream
      include ActiveFedora::RDFDatastream::ModelMethods
      register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
      map_predicates do |map|
        map.title(:to => "title", :in => RDF::DC)
        map.based_near(:to => "based_near", :in => RDF::FOAF)
        map.related_url(:to => "seeAlso", :in => RDF::RDFS)
      end
    end
    class RdfTest < ActiveFedora::Base 
      has_metadata :name=>'rdf', :type=>NtriplesMetadataDatastream
      delegate :based_near, :to=>'rdf'
      delegate :related_url, :to=>'rdf'
      delegate :title, :to=>'rdf', :unique=>true
    end
    @subject = RdfTest.new
  end

  after do
    Object.send(:remove_const, :RdfTest)
    Object.send(:remove_const, :NtriplesMetadataDatastream)
  end

  it "should set and recall values" do
    @subject.title = 'War and Peace'
    @subject.based_near = "Moscow, Russia"
    @subject.related_url = RDF::URI("http://en.wikipedia.org/wiki/War_and_Peace")
    @subject.save

    loaded = RdfTest.find(@subject.pid)
    loaded.title.should == 'War and Peace'
    loaded.based_near.should == 'Moscow, Russia'
    loaded.related_url.should == 'http://en.wikipedia.org/wiki/War_and_Peace'
  end
end
