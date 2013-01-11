require 'spec_helper'

describe "Nested Rdf Objects" do
  before(:each) do 
    class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
      map_predicates do |map|
        map.parts(:in=> RDF::DC, :to=>'hasPart', :class_name=>'Component')
      end

      class Component
        include ActiveFedora::RdfObject
        map_predicates do |map|
          map.label(:in=> RDF::DC, :to=>'title')
        end
      end
    end

  end
  
  after(:each) do
    Object.send(:remove_const, :SpecDatastream)
  end

  let (:ds) do
    mock_obj = stub(:mock_obj, :pid=>'test:124', :new? => true)
    ds = SpecDatastream.new(mock_obj)
  end


  it "should be able to nest a complex object" do
    comp = SpecDatastream::Component.new
    comp.label = ["Alternator"]
    ds.parts = comp
    ds.parts.first.label.should == ["Alternator"]
  end
  it "should be able to nest many complex objects" do
    comp1 = SpecDatastream::Component.new
    comp1.label = ["Alternator"]
    comp2 = SpecDatastream::Component.new
    comp2.label = ["Crankshaft"]
    ds.parts = [comp1, comp2]
    ds.parts.first.label.should == ["Alternator"]
    ds.parts.last.label.should == ["Crankshaft"]
  end

  it "should be able to clear complex objects" do
    comp1 = SpecDatastream::Component.new
    comp1.label = ["Alternator"]
    comp2 = SpecDatastream::Component.new
    comp2.label = ["Crankshaft"]
    ds.parts = [comp1, comp2]
    ds.parts = []
    ds.parts.should == []
  end

  it "should load complex objects" do
    ds.content = <<END
_:g70350851837440 <http://purl.org/dc/terms/title> "Alternator" .
<info:fedora/test:124> <http://purl.org/dc/terms/hasPart> _:g70350851837440 .
<info:fedora/test:124> <http://purl.org/dc/terms/hasPart> _:g70350851833380 .
_:g70350851833380 <http://purl.org/dc/terms/title> "Crankshaft" .
END
    ds.parts.first.label.should == ["Alternator"]
  end
end
