require 'spec_helper'

describe ActiveFedora::RDFDatastream do
  before do
    class DummySubnode < ActiveTriples::Resource
      property :title, predicate: ::RDF::Vocab::DC[:title], class_name: ::RDF::Literal
      property :relation, predicate: ::RDF::Vocab::DC[:relation]
    end

    class DummyResource < ActiveFedora::RDFDatastream
      property :title, predicate: ::RDF::Vocab::DC[:title], class_name: ::RDF::Literal
      property :license, predicate: ::RDF::Vocab::DC[:license], class_name: DummySubnode
      property :creator, predicate: ::RDF::Vocab::DC[:creator], class_name: 'DummyAsset'

      def serialization_format
        :ntriples
      end
    end

    class DummyAsset < ActiveFedora::Base
      has_subresource 'descMetadata', class_name: 'DummyResource'
      property :something, predicate: ::RDF::URI('http://example.com/thing')
    end
  end

  after do
    Object.send(:remove_const, "DummyAsset")
    Object.send(:remove_const, "DummyResource")
    Object.send(:remove_const, "DummySubnode")
  end

  subject(:resource) { DummyResource.new("#{ActiveFedora.fedora.host}/test/test:1") }

  describe "attribute setting" do
    context "on text attributes" do
      before do
        resource.title = "bla"
      end

      it "lets you access" do
        expect(resource.title).to eq ["bla"]
      end

      it "marks it as changed" do
        expect(resource).to be_changed
      end

      context "after it is persisted" do
        before do
          resource.save
          resource.reload
        end

        it "is persisted" do
          expect(resource.resource).to be_persisted
        end

        context "and it's reloaded" do
          before do
            resource.reload
          end

          it "is accessible after being saved" do
            expect(resource.title).to eq ["bla"]
          end

          it "serializes to content" do
            expect(resource.content).not_to be_blank
          end
        end

        context "and it is found again" do
          before do
            @object = DummyResource.new(resource.uri)
          end

          it "serializes to content" do
            expect(@object.content).not_to be_blank
          end

          it "is accessible after being saved" do
            expect(@object.title).to eq ["bla"]
          end

          it "has datastream content" do
            expect(@object.remote_content).not_to be_blank
          end
        end
      end
    end

    context "on rdf resource attributes" do
      context "persisted to parent" do
        before do
          dummy = DummySubnode.new
          dummy.title = 'subbla'
          resource.license = dummy
        end

        it "lets you access" do
          expect(resource.license.first.title).to eq ['subbla']
        end

        it "marks it as changed" do
          expect(resource).to be_changed
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
          resource.license = dummy
        end

        it "lets you access" do
          expect(resource.license.first.title).to eq ['subbla']
        end

        it "marks it as changed" do
          expect(resource).to be_changed
        end
      end
    end
  end

  describe "relationships" do
    before do
      @new_object = DummyAsset.create(something: ["subbla"])
      resource.title = ["bla"]
      resource.creator = @new_object
    end

    it "can set sub-properties to AF objects" do
      expect(resource.creator).to eq [@new_object]
    end

    it "has accessible relationship attributes" do
      expect(resource.creator.first.something).to eq ["subbla"]
    end

    it "lets me get to an AF:Base object" do
      resource.save
      new_resource = DummyResource.new(resource.uri)
      expect(new_resource.creator.first).to be_kind_of(ActiveFedora::Base)
    end

    context "when the AF:Base object is deleted" do
      before do
        resource.save
        @resource = DummyResource.new(resource.uri)
        @new_object.destroy
      end
      it "gives back an ActiveTriples::Resource" do
        expect(@resource.creator.first).to be_kind_of(ActiveTriples::Resource)
        expect(@resource.creator.first.rdf_subject).to eq @new_object.resource.rdf_subject
      end
    end

    it "allows for deep attributes to be set directly" do
      resource.creator.first.something = ["Bla"]
      expect(resource.creator.first.something).to eq ["Bla"]
    end

    context "when the subject is set with base_uri" do
      before do
        @old_uri = DummyResource.resource_class.base_uri
        DummyResource.resource_class.configure base_uri: 'http://example.org/'
        new_object = DummyAsset.new
        new_object.save
        resource.creator = new_object
      end
      after do
        DummyResource.resource_class.configure base_uri: @old_uri
      end

      it "lets me get to an AF:Base object" do
        resource.save
        new_resource = DummyResource.new(resource.uri)
        expect(new_resource.creator.first).to be_kind_of(ActiveFedora::Base)
      end
    end

    context "when the object with a relationship is saved" do
      before do
        resource.save
      end

      it "is retrievable" do
        expect(resource.creator.first.something).to eq ["subbla"]
      end
    end

    context "when the object with a relationship is frozen" do
      before do
        resource.save
        resource.freeze
      end

      it "is retrievable" do
        expect(resource.creator.first.something).to eq ["subbla"]
      end
    end
  end
end
