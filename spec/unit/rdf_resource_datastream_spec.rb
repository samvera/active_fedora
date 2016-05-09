require 'spec_helper'

describe ActiveFedora::RDFDatastream do
  before do
    class DummySubnode < ActiveTriples::Resource
      property :title, predicate: ::RDF::Vocab::DC[:title], class_name: ::RDF::Literal
      property :relation, predicate: ::RDF::Vocab::DC[:relation]
    end

    class DummyResource < ActiveFedora::RDFDatastream
      Deprecation.silence(ActiveFedora::RDFDatastream) do
        property :title, predicate: ::RDF::Vocab::DC[:title], class_name: ::RDF::Literal do |index|
          index.as :searchable, :displayable
        end
        property :license, predicate: ::RDF::Vocab::DC[:license], class_name: DummySubnode do |index|
          index.as :searchable, :displayable
        end
        property :creator, predicate: ::RDF::Vocab::DC[:creator], class_name: 'DummyAsset' do |index|
          index.as :searchable
        end
      end
      def serialization_format
        :ntriples
      end
    end

    class DummyAsset < ActiveFedora::Base
      has_subresource 'descMetadata', class_name: 'DummyResource'
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :title, :license, datastream: 'descMetadata', multiple: true
        has_attributes :relation, datastream: 'descMetadata', at: [:license, :relation], multiple: false
      end
    end
  end

  after do
    Object.send(:remove_const, "DummyAsset")
    Object.send(:remove_const, "DummyResource")
    Object.send(:remove_const, "DummySubnode")
  end

  subject { DummyAsset.new }

  describe "#to_solr" do
    before { subject.descMetadata.title = "bla" }

    it "does not be blank" do
      expect(subject.to_solr).not_to be_blank
    end

    it "solrizes" do
      expect(subject.to_solr["desc_metadata__title_teim"]).to eq ["bla"]
    end

    context "with ActiveFedora::Base resources" do
      let(:dummy_asset) { DummyAsset.new }

      before do
        allow(dummy_asset).to receive(:uri).and_return("http://foo")
        subject.descMetadata.creator = dummy_asset
      end

      it "solrizes objects" do
        expect(subject.to_solr["desc_metadata__creator_teim"]).to eq ["http://foo"]
      end
    end

    context "with ActiveTriples resources" do
      before { subject.descMetadata.license = DummySubnode.new('http://example.org/blah') }

      it "solrizes uris" do
        expect(subject.to_solr["desc_metadata__license_teim"]).to eq ['http://example.org/blah']
      end
    end
  end

  describe "delegation" do
    it "retrieves values" do
      subject.descMetadata.title = "bla"
      expect(subject.title).to eq ["bla"]
    end

    it "sets values" do
      subject.title = ["blah"]
      expect(subject.descMetadata.title).to eq ["blah"]
    end
  end

  describe "attribute setting" do
    context "on text attributes" do
      before do
        subject.descMetadata.title = "bla"
      end

      it "lets you access" do
        expect(subject.descMetadata.title).to eq ["bla"]
      end

      it "marks it as changed" do
        expect(subject.descMetadata).to be_changed
      end

      context "after it is persisted" do
        before do
          subject.save
          subject.reload
        end

        it "is persisted" do
          expect(subject.descMetadata.resource).to be_persisted
        end

        context "and it's reloaded" do
          before do
            subject.reload
          end

          it "is accessible after being saved" do
            expect(subject.descMetadata.title).to eq ["bla"]
          end

          it "serializes to content" do
            expect(subject.descMetadata.content).not_to be_blank
          end
        end

        context "and it is found again" do
          before do
            @object = DummyAsset.find(subject.id)
          end

          it "serializes to content" do
            expect(@object.descMetadata.content).not_to be_blank
          end

          it "is accessible after being saved" do
            expect(@object.descMetadata.title).to eq ["bla"]
          end

          it "has datastream content" do
            expect(@object.descMetadata.remote_content).not_to be_blank
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

        it "lets you access" do
          expect(subject.descMetadata.license.first.title).to eq ['subbla']
        end

        it "marks it as changed" do
          expect(subject.descMetadata).to be_changed
        end
      end
      context "persisted to repository" do
        before do
          allow_any_instance_of(DummySubnode).to receive(:repository).and_return(RDF::Repository.new)
          dummy = DummySubnode.new(RDF::URI('http://example.org/dummy/blah'))
          dummy.title = 'subbla'
          # We want to have to manually persist to the repository.
          # Parent objects shouldn't be persisting children they share with other parents
          dummy.persist!
          subject.descMetadata.license = dummy
        end

        it "lets you access" do
          expect(subject.descMetadata.license.first.title).to eq ['subbla']
        end

        it "marks it as changed" do
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

    it "has accessible relationship attributes" do
      expect(subject.descMetadata.creator.first.title).to eq ["subbla"]
    end

    it "lets me get to an AF:Base object" do
      subject.save
      subject.reload
      expect(subject.descMetadata.creator.first).to be_kind_of(ActiveFedora::Base)
    end

    context "when the AF:Base object is deleted" do
      before do
        subject.save
        @new_object.destroy
      end
      it "gives back an ActiveTriples::Resource" do
        subject.reload
        expect(subject.descMetadata.creator.first).to be_kind_of(ActiveTriples::Resource)
        expect(subject.descMetadata.creator.first.rdf_subject).to eq @new_object.resource.rdf_subject
      end
    end

    it "allows for deep attributes to be set directly" do
      subject.descMetadata.creator.first.title = ["Bla"]
      expect(subject.descMetadata.creator.first.title).to eq ["Bla"]
    end

    context "when the subject is set with base_uri" do
      before do
        @old_uri = DummyResource.resource_class.base_uri
        DummyResource.resource_class.configure base_uri: 'http://example.org/'
        new_object = DummyAsset.new
        new_object.save
        subject.descMetadata.creator = new_object
      end
      after do
        DummyResource.resource_class.configure base_uri: @old_uri
      end

      it "lets me get to an AF:Base object" do
        subject.save
        subject.reload
        expect(subject.descMetadata.creator.first).to be_kind_of(ActiveFedora::Base)
      end
    end

    context "when the object with a relationship is saved" do
      before do
        subject.save
        @object = subject.class.find(subject.id)
      end

      it "is retrievable" do
        expect(subject.descMetadata.creator.first.title).to eq ["subbla"]
      end
    end

    context "when the object with a relationship is frozen" do
      before do
        subject.save
        @object = subject.class.find(subject.id)
        @object.freeze
        subject.freeze
      end

      it "is retrievable" do
        expect(subject.descMetadata.creator.first.title).to eq ["subbla"]
      end
    end
  end
end
