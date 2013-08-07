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
      mock_obj = double(:mock_obj, :pid=>'test:124', :new? => true)
      ds = SpecDatastream.new(mock_obj)
    end

    describe "#new_record?" do
      it "should be true when its built" do
        v = ds.parts.build(label: 'Alternator')
        v.should be_new_record
      end

      it "should not be new when it's loaded from fedora" do
        ds.content = '_:g70324142325120 <http://purl.org/dc/terms/title> "Alternator" .
<info:fedora/test:124> <http://purl.org/dc/terms/hasPart> _:g70324142325120 .'
        ds.parts.first.should_not be_new_record
      end
    end

    it "should not choke on invalid data" do
      # set a string in the graph where model expects a node
      ds.parts = ["foo"]
      expect {ds.parts.inspect}.to raise_error(ArgumentError, "Expected the value of http://purl.org/dc/terms/hasPart to be an RDF object but it is a String \"foo\"")
    end
    
    it "should be able to nest a complex object" do
      comp = SpecDatastream::Component.new(ds.graph)
      comp.label = ["Alternator"]
      ds.parts = comp
      ds.parts.first.label.should == ["Alternator"]
    end

    it "should be able to replace attributes" do
      v = ds.parts.build(label: 'Alternator')
      ds.parts.first.label.should == ['Alternator']
      ds.parts.first.label = ['Distributor']
      ds.parts.first.label.should == ['Distributor']
    end

    it "should be able to replace objects" do
      ds.parts.build(label: 'Alternator')
      ds.parts.build(label: 'Distributor')
      ds.parts.size.should == 2
      comp = SpecDatastream::Component.new(ds.graph)
      comp.label = "Injector port"
      ds.parts = [comp]
      ds.parts.size.should == 1
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

    it "should build complex objects when a parent node doesn't exist" do
      part = ds.parts.build
      part.should be_kind_of SpecDatastream::Component
      part.label = "Wheel bearing"
      ds.parts.first.label.should == ['Wheel bearing']
    end

    it "should not create a child node when hitting the accessor" do
      ds.parts
      ds.parts.first.should be_nil
      ds.serialize.should == ''
    end

    it "should build complex objects when a parent node exists" do
      part = ds.parts.build
      part.should be_kind_of SpecDatastream::Component
      part.label = "Wheel bearing"
      ds.parts.first.label.should == ['Wheel bearing']
    end

    describe "#first_or_create" do
      it "should return a result if the predicate exists" do
        part1 = ds.parts.build
        part2 = ds.parts.build
        ds.parts.first_or_create.should == part1
      end

      it "should create a new result if the predicate doesn't exist" do
        ds.parts.should == []
        part = ds.parts.first_or_create(label: 'Front control arm bushing')
        part.label.should == ['Front control arm bushing']
        ds.parts.should == [part]
      end

    end
  end


  describe "with type" do
    describe "one class per assertion" do 
      before(:each) do 
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          map_predicates do |map|
            map.mediator(:in=> RDF::DC, :class_name=>'MediatorUser')
          end

          class MediatorUser
            include ActiveFedora::RdfObject
            rdf_type RDF::DC.AgentClass
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
        mock_obj = double(:mock_obj, :pid=>'test:124', :new? => true)
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

    describe "shared assertion to different classes" do
      before(:each) do 
        class EbuCore < RDF::Vocabulary("http://www.ebu.ch/metadata/ontologies/ebucore#")
          property :isEpisodeOf
          property :title
        end
        
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          map_predicates do |map|
            map.series(:to => 'isEpisodeOf', :in=> EbuCore, :class_name=>'Series')
            map.program(:to => 'isEpisodeOf', :in=> EbuCore, :class_name=>'Program')
          end

          class Series
            include ActiveFedora::RdfObject
            rdf_type 'http://www.ebu.ch/metadata/ontologies/ebucore#Series'
            map_predicates do |map|
              map.title(:in=> EbuCore)
            end
          end

          class Program 
            include ActiveFedora::RdfObject
            rdf_type 'http://www.ebu.ch/metadata/ontologies/ebucore#Programme'
            map_predicates do |map|
              map.title(:in=> EbuCore)
            end
          end
        end

      end
      
      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end

      let (:ds) do
        mock_obj = double(:mock_obj, :pid=>'test:124', :new? => true)
        ds = SpecDatastream.new(mock_obj)
      end


      it "should store the type of complex objects when type is specified" do
        series = SpecDatastream::Series.new ds.graph
        series.title = ["renovating bathrooms"]
        ds.series = series

        program = SpecDatastream::Program.new ds.graph
        program.title = ["This old House"]
        ds.program = program

        ds.program.first.type.size.should == 1
        ds.program.first.type.first.to_s.should == 'http://www.ebu.ch/metadata/ontologies/ebucore#Programme' 
        ds.series.first.type.size.should == 1
        ds.series.first.type.first.to_s.should == 'http://www.ebu.ch/metadata/ontologies/ebucore#Series' 
      end

      it "should create an object of the correct type" do
        ds.program.build.should be_kind_of SpecDatastream::Program
        ds.series.build.should be_kind_of SpecDatastream::Series
      end
    end
  end
end
