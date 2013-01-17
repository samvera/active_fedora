require 'spec_helper'

describe "Nested Rdf Objects" do
  describe "without type" do
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
      comp = SpecDatastream::Component.new(ds.graph)
      comp.label = ["Alternator"]
      ds.parts = comp
      ds.parts.first.label.should == ["Alternator"]
    end
    it "should be able to nest many complex objects" do
      comp1 = SpecDatastream::Component.new ds.graph
      comp1.label = ["Alternator"]
      comp2 = SpecDatastream::Component.new ds.graph
      comp2.label = ["Crankshaft"]
      ds.parts = [comp1, comp2]
      ds.parts.first.label.should == ["Alternator"]
      ds.parts.last.label.should == ["Crankshaft"]
    end

    it "should be able to clear complex objects" do
      comp1 = SpecDatastream::Component.new ds.graph
      comp1.label = ["Alternator"]
      comp2 = SpecDatastream::Component.new ds.graph
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

    it "should build complex objects" do
      part = ds.parts.build
      part.should be_kind_of SpecDatastream::Component
      part.label = "Wheel bearing"
    end
  end

  describe "with type" do
    before(:each) do 
      class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
        map_predicates do |map|
          map.mediator(:in=> RDF::DC, :class_name=>'MediatorUser')
        end

        class MediatorUser
          include ActiveFedora::RdfObject
          rdf_type "http://purl.org/dc/terms/AgentClass"
          map_predicates do |map|
            map.title(:in=> RDF::DC)
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


    it "should store the type of complex objects when type is specified" do
      comp = SpecDatastream::MediatorUser.new ds.graph
      comp.title = ["Doctor"]
      ds.mediator = comp
      ds.mediator.first.type.first.should be_instance_of RDF::URI
      ds.mediator.first.type.first.to_s.should == "http://purl.org/dc/terms/AgentClass"
      ds.mediator.first.title.first.should == 'Doctor'
    end

    it "should add the type of complex object when it is not provided" do
      ds.content = <<END
_:g70350851837440 <http://purl.org/dc/terms/title> "Mediation Person" .
<info:fedora/test:124> <http://purl.org/dc/terms/mediator> _:g70350851837440 .
END
      ds.mediator.first.type.first.to_s.should == "http://purl.org/dc/terms/AgentClass"
    end

    it "should add load the type of complex objects when provided (superceeding what is specified by the class)" do
      ds.content = <<END
_:g70350851837440 <http://purl.org/dc/terms/title> "Mediation Orgainzation" .
_:g70350851837440 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebu.ch/metadata/ontologies/ebucore#Organisation> .
<info:fedora/test:124> <http://purl.org/dc/terms/mediator> _:g70350851837440 .
END
      ds.mediator.first.type.first.to_s.should == "http://www.ebu.ch/metadata/ontologies/ebucore#Organisation"
    end
  end
end
