require 'spec_helper'

describe 'Nested Rdf Objects' do
  describe 'without type' do
    before(:each) do
      class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
        map_predicates do |map|
          map.parts(:in => RDF::DC, :to => 'hasPart', :class_name => 'Component')
        end

        class Component
          include ActiveFedora::RdfObject
          map_predicates do |map|
            map.label(:in => RDF::DC, :to => 'title')
          end
        end
      end

    end

    after(:each) do
      Object.send(:remove_const, :SpecDatastream)
    end

    let (:ds) do
      mock_obj = double(:mock_obj, :pid => 'test:124', :new_record? => true)
      ds = SpecDatastream.new(mock_obj)
    end

    describe '#new_record?' do
      it 'should be true when its built' do
        v = ds.parts.build(label: 'Alternator')
        expect(v).to be_new_record
      end

      it "should not be new when it's loaded from fedora" do
        ds.content = '_:g70324142325120 <http://purl.org/dc/terms/title> "Alternator" .
<info:fedora/test:124> <http://purl.org/dc/terms/hasPart> _:g70324142325120 .'
        expect(ds.parts.first).not_to be_new_record
      end
    end

    it 'should not choke on invalid data' do
      # set a string in the graph where model expects a node
      ds.parts = ['foo']
      expect {ds.parts.inspect}.to raise_error(ArgumentError, "Expected the value of http://purl.org/dc/terms/hasPart to be an RDF object but it is a String \"foo\"")
    end

    it 'should be able to nest a complex object' do
      comp = SpecDatastream::Component.new(ds.graph)
      comp.label = ['Alternator']
      ds.parts = comp
      expect(ds.parts.first.label).to eq(['Alternator'])
    end

    it 'should be able to replace attributes' do
      v = ds.parts.build(label: 'Alternator')
      expect(ds.parts.first.label).to eq(['Alternator'])
      ds.parts.first.label = ['Distributor']
      expect(ds.parts.first.label).to eq(['Distributor'])
    end

    it 'should be able to replace objects' do
      ds.parts.build(label: 'Alternator')
      ds.parts.build(label: 'Distributor')
      expect(ds.parts.size).to eq(2)
      comp = SpecDatastream::Component.new(ds.graph)
      comp.label = 'Injector port'
      ds.parts = [comp]
      expect(ds.parts.size).to eq(1)
    end

    it 'should be able to nest many complex objects' do
      comp1 = SpecDatastream::Component.new ds.graph
      comp1.label = ['Alternator']
      comp2 = SpecDatastream::Component.new ds.graph
      comp2.label = ['Crankshaft']
      ds.parts = [comp1, comp2]
      expect(ds.parts.first.label).to eq(['Alternator'])
      expect(ds.parts.last.label).to eq(['Crankshaft'])
    end

    it 'should be able to clear complex objects' do
      comp1 = SpecDatastream::Component.new ds.graph
      comp1.label = ['Alternator']
      comp2 = SpecDatastream::Component.new ds.graph
      comp2.label = ['Crankshaft']
      ds.parts = [comp1, comp2]
      ds.parts = []
      expect(ds.parts).to eq([])
    end

    it 'should load complex objects' do
      ds.content = <<END
_:g70350851837440 <http://purl.org/dc/terms/title> "Alternator" .
<info:fedora/test:124> <http://purl.org/dc/terms/hasPart> _:g70350851837440 .
<info:fedora/test:124> <http://purl.org/dc/terms/hasPart> _:g70350851833380 .
_:g70350851833380 <http://purl.org/dc/terms/title> "Crankshaft" .
END
      expect(ds.parts.first.label).to eq(['Alternator'])
    end

    it "should build complex objects when a parent node doesn't exist" do
      part = ds.parts.build
      expect(part).to be_kind_of SpecDatastream::Component
      part.label = 'Wheel bearing'
      expect(ds.parts.first.label).to eq(['Wheel bearing'])
    end

    it 'should not create a child node when hitting the accessor' do
      ds.parts
      expect(ds.parts.first).to be_nil
      expect(ds.serialize).to eq('')
    end

    it 'should build complex objects when a parent node exists' do
      part = ds.parts.build
      expect(part).to be_kind_of SpecDatastream::Component
      part.label = 'Wheel bearing'
      expect(ds.parts.first.label).to eq(['Wheel bearing'])
    end

    describe '#first_or_create' do
      it 'should return a result if the predicate exists' do
        part1 = ds.parts.build
        part2 = ds.parts.build
        expect(ds.parts.first_or_create).to eq(part1)
      end

      it "should create a new result if the predicate doesn't exist" do
        expect(ds.parts).to eq([])
        part = ds.parts.first_or_create(label: 'Front control arm bushing')
        expect(part.label).to eq(['Front control arm bushing'])
        expect(ds.parts).to eq([part])
      end

    end
  end


  describe 'with type' do
    describe 'one class per assertion' do
      before(:each) do
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          map_predicates do |map|
            map.mediator(:in => RDF::DC, :class_name => 'MediatorUser')
          end

          class MediatorUser
            include ActiveFedora::RdfObject
            rdf_type RDF::DC.AgentClass
            map_predicates do |map|
              map.title(:in => RDF::DC)
            end
          end
        end
      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end

      let (:ds) do
        mock_obj = double(:mock_obj, :pid => 'test:124', :new_record? => true)
        ds = SpecDatastream.new(mock_obj)
      end


      it 'should store the type of complex objects when type is specified' do
        comp = SpecDatastream::MediatorUser.new ds.graph
        comp.title = ['Doctor']
        ds.mediator = comp
        expect(ds.mediator.first.type.first).to be_instance_of RDF::Vocabulary::Term
        expect(ds.mediator.first.type.first.to_s).to eq('http://purl.org/dc/terms/AgentClass')
        expect(ds.mediator.first.title.first).to eq('Doctor')
      end

      it 'should add the type of complex object when it is not provided' do
        ds.content = <<END
  _:g70350851837440 <http://purl.org/dc/terms/title> "Mediation Person" .
  <info:fedora/test:124> <http://purl.org/dc/terms/mediator> _:g70350851837440 .
END
        expect(ds.mediator.first.type.first.to_s).to eq('http://purl.org/dc/terms/AgentClass')
      end

      it 'should add load the type of complex objects when provided (superceeding what is specified by the class)' do
        ds.content = <<END
  _:g70350851837440 <http://purl.org/dc/terms/title> "Mediation Orgainzation" .
  _:g70350851837440 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebu.ch/metadata/ontologies/ebucore#Organisation> .
  <info:fedora/test:124> <http://purl.org/dc/terms/mediator> _:g70350851837440 .
END
        expect(ds.mediator.first.type.first.to_s).to eq('http://www.ebu.ch/metadata/ontologies/ebucore#Organisation')
      end
    end

    describe 'shared assertion to different classes' do
      before(:each) do
        class EbuCore < RDF::Vocabulary('http://www.ebu.ch/metadata/ontologies/ebucore#')
          property :isEpisodeOf
          property :title
        end

        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          map_predicates do |map|
            map.series(:to => 'isEpisodeOf', :in => EbuCore, :class_name => 'Series')
            map.program(:to => 'isEpisodeOf', :in => EbuCore, :class_name => 'Program')
          end

          class Series
            include ActiveFedora::RdfObject
            rdf_type 'http://www.ebu.ch/metadata/ontologies/ebucore#Series'
            map_predicates do |map|
              map.title(:in => EbuCore)
            end
          end

          class Program
            include ActiveFedora::RdfObject
            rdf_type 'http://www.ebu.ch/metadata/ontologies/ebucore#Programme'
            map_predicates do |map|
              map.title(:in => EbuCore)
            end
          end
        end

      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end

      let (:ds) do
        mock_obj = double(:mock_obj, :pid => 'test:124', :new_record? => true)
        ds = SpecDatastream.new(mock_obj)
      end


      it 'should store the type of complex objects when type is specified' do
        series = SpecDatastream::Series.new ds.graph
        series.title = ['renovating bathrooms']
        ds.series = series

        program = SpecDatastream::Program.new ds.graph
        program.title = ['This old House']
        ds.program = program

        expect(ds.program.first.type.size).to eq(1)
        expect(ds.program.first.type.first.to_s).to eq('http://www.ebu.ch/metadata/ontologies/ebucore#Programme')
        expect(ds.series.first.type.size).to eq(1)
        expect(ds.series.first.type.first.to_s).to eq('http://www.ebu.ch/metadata/ontologies/ebucore#Series')
      end

      it 'should create an object of the correct type' do
        expect(ds.program.build).to be_kind_of SpecDatastream::Program
        expect(ds.series.build).to be_kind_of SpecDatastream::Series
      end
    end
  end
end
