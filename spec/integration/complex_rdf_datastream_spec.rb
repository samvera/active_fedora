require 'spec_helper'

describe "Nested Rdf Objects" do
  before(:each) do 
    class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
      map_predicates do |map|
        map.our_parts(:in=> RDF::DC, :to=>'hasPart', :class_name=>'Component')
      end

      class Component
        include ActiveFedora::RdfObject
        map_predicates do |map|
          map.my_label(:in=> RDF::DC, :to=>'title')
        end
      end
    end

  end
  
  after(:each) do
    Object.send(:remove_const, :SpecDatastream)
  end

  it "should be able to nest the component" do
    mock_obj = stub(:mock_obj, :pid=>'test:124', :new? => true)
    ds = SpecDatastream.new(mock_obj)
    comp = SpecDatastream::Component.new
    comp.my_label = ["Alternator"]
    ds.our_parts = comp

    puts 'oe ' + ds.our_parts.first.inspect
    puts 'lab ' + ds.our_parts.first.my_label.inspect
    ds.our_parts.first.my_label.should == ["Alternator"]

  end
end
