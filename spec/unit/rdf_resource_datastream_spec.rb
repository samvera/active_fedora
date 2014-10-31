require 'spec_helper'

describe ActiveFedora::RDFDatastream do
  before do
    class DummySubnode < ActiveTriples::Resource
      property :title, predicate:  RDF::DC[:title], class_name: RDF::Literal
      property :relation, predicate:  RDF::DC[:relation]
    end

    class DummyResource < ActiveFedora::RDFDatastream
      property :title, predicate:  RDF::DC[:title], class_name: RDF::Literal do |index|
        index.as :searchable, :displayable
      end
      property :license, predicate:  RDF::DC[:license], class_name: DummySubnode do |index|
        index.as :searchable, :displayable
      end
      property :creator, predicate: RDF::DC[:creator], class_name: 'DummyAsset' do |index|
        index.as :searchable
      end
      def serialization_format
        :ntriples
      end
    end

    class DummyAsset < ActiveFedora::Base
      has_metadata  'descMetadata', type: DummyResource
      has_attributes :title, :license, datastream: 'descMetadata', multiple: true
      has_attributes :relation, datastream: 'descMetadata', at: [:license, :relation], multiple: false
    end
  end

  after do
    Object.send(:remove_const, "DummyAsset")
    Object.send(:remove_const, "DummyResource")
    Object.send(:remove_const, "DummySubnode")
  end

  subject { DummyAsset.new }

  describe "#to_solr" do
    before do
      subject.descMetadata.title = "bla"
      subject.descMetadata.license = DummySubnode.new('http://example.org/blah')
    end

    it "should not be blank" do
      expect(subject.to_solr).not_to be_blank
    end

    it "should solrize" do
      expect(subject.to_solr["desc_metadata__title_teim"]).to eq ["bla"]
    end

    it "should solrize uris" do
      expect(subject.to_solr["desc_metadata__license_teim"]).to eq ['http://example.org/blah']
    end
  end

  describe "delegation" do
    it "should retrieve values" do
      subject.descMetadata.title = "bla"
      expect(subject.title).to eq ["bla"]
    end

    it "should set values" do
      subject.title = ["blah"]
      expect(subject.descMetadata.title).to eq ["blah"]
    end
  end

  describe "attribute setting" do
    context "on text attributes" do
      before do
        subject.descMetadata.title = "bla"
      end

      it "should let you access" do
        expect(subject.descMetadata.title).to eq ["bla"]
      end

      it "should mark it as changed" do
        expect(subject.descMetadata).to be_changed
      end

      context "after it is persisted" do
        before do
          subject.save
          subject.reload
        end

        it "should be persisted" do
          expect(subject.descMetadata.resource).to be_persisted
        end

        context "and it's reloaded" do
          before do
            subject.reload
          end

          it "should be accessible after being saved" do
            expect(subject.descMetadata.title).to eq ["bla"]
          end

          it "should serialize to content" do
            expect(subject.descMetadata.content).not_to be_blank
          end
        end

        context "and it is found again" do
          before do
            @object = DummyAsset.find(subject.pid)
          end

          it "should serialize to content" do
            expect(@object.descMetadata.content).not_to be_blank
          end

          it "should be accessible after being saved" do
            expect(@object.descMetadata.title).to eq ["bla"]
          end

          it "should have datastream content" do
            expect(@object.descMetadata.datastream_content).not_to be_blank
          end
        end
      end
    end

    context "on rdf resource attributes" do
      context "persisted to parent" do
        before do
          dummy = DummySubnode.new
          dummy.title = 'subbla'
          subject.descMetadata.license = dummy
        end

        it "should let you access" do
          expect(subject.descMetadata.license.first.title).to eq ['subbla']
        end

        it "should mark it as changed" do
          expect(subject.descMetadata).to be_changed
        end
      end
      context "persisted to repository" do
        before do
          DummySubnode.configure :repository => :default
          allow_any_instance_of(DummySubnode).to receive(:repository).and_return(RDF::Repository.new)
          dummy = DummySubnode.new(RDF::URI('http://example.org/dummy/blah'))
          dummy.title = 'subbla'
          # We want to have to manually persist to the repository.
          # Parent objects shouldn't be persisting children they share with other parents
          dummy.persist!
          subject.descMetadata.license = dummy
        end

        it "should let you access" do
          expect(subject.descMetadata.license.first.title).to eq ['subbla']
        end

        it "should mark it as changed" do
          expect(subject.descMetadata).to be_changed
        end
      end
    end
  end

  describe "relationships" do
    before do
      @new_object = DummyAsset.new
      @new_object.title = ["subbla"]
      @new_object.save
      subject.title = ["bla"]
      subject.descMetadata.creator = @new_object
    end

    it "should have accessible relationship attributes" do
      expect(subject.descMetadata.creator.first.title).to eq ["subbla"]
    end

    it "should let me get to an AF:Base object" do
      subject.save
      subject.reload
      expect(subject.descMetadata.creator.first).to be_kind_of(ActiveFedora::Base)
    end

    context "when the AF:Base object is deleted" do
      before do
        subject.save
        @new_object.destroy
      end
      it "should give back an ActiveTriples::Resource" do
        subject.reload
        expect(subject.descMetadata.creator.first).to be_kind_of(ActiveTriples::Resource)
        expect(subject.descMetadata.creator.first.rdf_subject).to eq @new_object.resource.rdf_subject
      end
    end

    it "should allow for deep attributes to be set directly" do
      subject.descMetadata.creator.first.title = ["Bla"]
      expect(subject.descMetadata.creator.first.title).to eq ["Bla"]
    end

    context "when the subject is set with base_uri" do
      before do
        @old_uri = DummyResource.resource_class.base_uri
        DummyResource.resource_class.configure :base_uri => 'http://example.org/'
        new_object = DummyAsset.new
        new_object.save
        subject.descMetadata.creator = new_object
      end
      after do
        DummyResource.resource_class.configure :base_uri => @old_uri
      end

      it "should let me get to an AF:Base object" do
        subject.save
        subject.reload
        expect(subject.descMetadata.creator.first).to be_kind_of(ActiveFedora::Base)
      end
    end

    context "when the object with a relationship is saved" do
      before do
        subject.save
        @object = subject.class.find(subject.pid)
      end

      it "should be retrievable" do
        expect(subject.descMetadata.creator.first.title).to eq ["subbla"]
      end
    end

    context "when the object with a relationship is frozen" do
      before do
        subject.save
        @object = subject.class.find(subject.pid)
        @object.freeze
        subject.freeze
      end

      it "should be retrievable" do
        expect(subject.descMetadata.creator.first.title).to eq ["subbla"]
      end
    end
  end
end
