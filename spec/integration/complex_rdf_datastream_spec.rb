require 'spec_helper'

describe "Nested Rdf Objects" do
  describe "without type" do
    before do
      class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
        property :parts, predicate: ::RDF::Vocab::DC.hasPart, class_name: 'Component'

        class Component < ActiveTriples::Resource
          property :label, predicate: ::RDF::Vocab::DC.title
        end
      end
    end

    after do
      Object.send(:remove_const, :SpecDatastream)
    end

    let(:ds) do
      SpecDatastream.new("#{ActiveFedora.fedora.host}/test/test:124/descMd")
    end

    describe "#new_record?" do
      it "is true when its built" do
        v = ds.parts.build(label: 'Alternator')
        expect(v).to be_new_record
      end

      it "does not be new when it's loaded from fedora" do
        ds.content = "_:g70324142325120 <http://purl.org/dc/terms/title> \"Alternator\" .
<#{ActiveFedora.fedora.host}/test/test:124> <http://purl.org/dc/terms/hasPart> _:g70324142325120 ."
        ds.resource.persist!
        expect(ds.parts.first).to_not be_new_record
      end
    end

    it "is able to nest a complex object" do
      comp = SpecDatastream::Component.new(nil, ds.graph)
      comp.label = ["Alternator"]
      ds.parts = comp
      expect(ds.parts.first.label).to eq ["Alternator"]
    end

    it "is able to replace attributes" do
      ds.parts.build(label: 'Alternator')
      expect(ds.parts.first.label).to eq ['Alternator']
      ds.parts.first.label = ['Distributor']
      expect(ds.parts.first.label).to eq ['Distributor']
    end

    it "is able to replace objects" do
      ds.parts.build(label: 'Alternator')
      ds.parts.build(label: 'Distributor')
      expect(ds.parts.size).to eq 2
      comp = SpecDatastream::Component.new(nil, ds.graph)
      comp.label = "Injector port"
      ds.parts = [comp]
      expect(ds.parts.size).to eq 1
    end

    it "is able to nest many complex objects" do
      comp1 = SpecDatastream::Component.new nil, ds.graph
      comp1.label = ["Alternator"]
      comp2 = SpecDatastream::Component.new nil, ds.graph
      comp2.label = ["Crankshaft"]
      ds.parts = [comp1, comp2]
      expect(ds.parts.map(&:label)).to contain_exactly ["Alternator"], ["Crankshaft"]
    end

    it "is able to clear complex objects" do
      comp1 = SpecDatastream::Component.new nil, ds.graph
      comp1.label = ["Alternator"]
      comp2 = SpecDatastream::Component.new nil, ds.graph
      comp2.label = ["Crankshaft"]
      ds.parts = [comp1, comp2]
      ds.parts = []
      expect(ds.parts).to eq []
    end

    it "loads complex objects" do
      ds.content = <<END
_:g70350851837440 <http://purl.org/dc/terms/title> "Alternator" .
<#{ActiveFedora.fedora.host}/test/test:124> <http://purl.org/dc/terms/hasPart> _:g70350851837440 .
<#{ActiveFedora.fedora.host}/test/test:124> <http://purl.org/dc/terms/hasPart> _:g70350851833380 .
_:g70350851833380 <http://purl.org/dc/terms/title> "Crankshaft" .
END
      expect(ds.parts.map(&:label)).to contain_exactly ["Alternator"], ["Crankshaft"]
    end

    it "builds complex objects when a parent node doesn't exist" do
      part = ds.parts.build
      expect(part).to be_kind_of SpecDatastream::Component
      part.label = "Wheel bearing"
      expect(ds.parts.first.label).to eq ['Wheel bearing']
    end

    it "does not create a child node when hitting the accessor" do
      ds.parts
      expect(ds.parts.first).to be_nil
      expect(ds.serialize).to eq ''
    end

    it "builds complex objects when a parent node exists" do
      part = ds.parts.build
      expect(part).to be_kind_of SpecDatastream::Component
      part.label = "Wheel bearing"
      expect(ds.parts.first.label).to eq ['Wheel bearing']
    end

    describe "#first_or_create" do
      it "returns a result if the predicate exists" do
        part1 = ds.parts.build
        expect(ds.parts.first_or_create).to eq part1
      end

      it "creates a new result if the predicate doesn't exist" do
        expect(ds.parts).to eq []
        part = ds.parts.first_or_create(label: 'Front control arm bushing')
        expect(part.label).to eq ['Front control arm bushing']
        expect(ds.parts).to eq [part]
      end
    end
  end

  describe "with type" do
    describe "one class per assertion" do
      before(:each) do
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          property :mediator, predicate: ::RDF::Vocab::DC.mediator, class_name: 'MediatorUser'

          class MediatorUser < ActiveTriples::Resource
            configure type: ::RDF::Vocab::DC.AgentClass
            property :title, predicate: ::RDF::Vocab::DC.title
          end
        end
      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end
      let(:ds) { SpecDatastream.new("#{ActiveFedora.fedora.host}/test/test:124/descMd") }

      it "stores the type of complex objects when type is specified" do
        comp = SpecDatastream::MediatorUser.new nil, ds.graph
        comp.title = ["Doctor"]
        ds.mediator = comp
        expect(ds.mediator.first.type.first).to be_instance_of ::RDF::URI
        expect(ds.mediator.first.type.first.to_s).to eq "http://purl.org/dc/terms/AgentClass"
        expect(ds.mediator.first.title.first).to eq 'Doctor'
      end

      it "adds the type of complex object when it is not provided" do
        ds.content = <<END
  _:g70350851837440 <http://purl.org/dc/terms/title> "Mediation Person" .
  <#{ActiveFedora.fedora.host}/test/test:124> <http://purl.org/dc/terms/mediator> _:g70350851837440 .
END
        expect(ds.mediator.first.type.first.to_s).to eq "http://purl.org/dc/terms/AgentClass"
      end

      it "adds load the type of complex objects when provided (superceeding what is specified by the class)" do
        ds.content = <<END
  _:g70350851837440 <http://purl.org/dc/terms/title> "Mediation Orgainzation" .
  _:g70350851837440 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebu.ch/metadata/ontologies/ebucore#Organisation> .
  <#{ActiveFedora.fedora.host}/test/test:124> <http://purl.org/dc/terms/mediator> _:g70350851837440 .
END
        expect(ds.mediator.first.type.map(&:to_s)).to include "http://www.ebu.ch/metadata/ontologies/ebucore#Organisation"
      end
    end

    describe "shared assertion to different classes" do
      before(:each) do
        class EbuCore < RDF::Vocabulary("http://www.ebu.ch/metadata/ontologies/ebucore#")
          property :isEpisodeOf
          property :title
        end

        class SpecContainer < ActiveFedora::Base
          has_subresource :info, class_name: 'SpecDatastream'
        end

        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          property :series, predicate: EbuCore.isEpisodeOf, class_name: 'Series'
          property :program, predicate: EbuCore.isEpisodeOf, class_name: 'Program'

          class Series < ActiveTriples::Resource
            configure type: 'http://www.ebu.ch/metadata/ontologies/ebucore#Series'
            property :title, predicate: EbuCore.title
          end

          class Program < ActiveTriples::Resource
            configure type: 'http://www.ebu.ch/metadata/ontologies/ebucore#Programme'
            property :title, predicate: EbuCore.title
          end
        end
      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
        Object.send(:remove_const, :SpecContainer)
      end

      let(:parent) { SpecContainer.new id: '124' }
      let(:file) { parent.info }

      it "stores the type of complex objects when type is specified" do
        pending "This is no longer supported by ActiveTriples - can we deprecate this altogether?"
        series = SpecDatastream::Series.new nil, file.graph
        series.title = ["renovating bathrooms"]
        file.series = series

        program = SpecDatastream::Program.new nil, file.graph
        program.title = ["This old House"]
        file.program = program

        expect(file.program.first.type.size).to eq 1
        expect(file.program.first.type.first.to_s).to eq 'http://www.ebu.ch/metadata/ontologies/ebucore#Programme'
        expect(file.series.first.type.size).to eq 1
        expect(file.series.first.type.first.to_s).to eq 'http://www.ebu.ch/metadata/ontologies/ebucore#Series'
      end

      it "creates an object of the correct type" do
        expect(file.program.build).to be_kind_of SpecDatastream::Program
        expect(file.series.build).to be_kind_of SpecDatastream::Series
      end
    end
  end
end
