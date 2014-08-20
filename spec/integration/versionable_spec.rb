require 'spec_helper'

describe "A versionable class" do
  before do
    class WithVersions < ActiveFedora::Base
      has_many_versions
      property :title, predicate: RDF::DC.title
    end
  end

  after do
    Object.send(:remove_const, :WithVersions)
  end

  subject { WithVersions.new }

  it "should be versionable" do
    expect(subject).to be_versionable
  end

  context "after saving" do
    before do
      subject.title = "Greetings Earthlings"
      subject.save
      subject.create_version
    end

    it "should set model_type to versionable" do
      expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
    end

    it "should have one version (plus the root version)" do
      expect(subject.versions.size).to eq 2
      expect(subject.versions.first).to be_kind_of RDF::URI
    end

    context "two times" do
      before do
        subject.title= "Surrender and prepare to be boarded"
        subject.save
        subject.create_version
      end

      it "should have two versions (plus the root version)" do
        expect(subject.versions.size).to eq 3
        subject.versions.each do |version|
          expect(version).to be_kind_of RDF::URI
        end
      end
    end
  end
end

describe "a versionable rdf datastream" do
  before(:all) do
    class VersionableDatastream < ActiveFedora::NtriplesRDFDatastream
      has_many_versions
      property :title, predicate: RDF::DC.title
    end

    class MockAFBase < ActiveFedora::Base
      has_metadata "descMetadata", type: VersionableDatastream, autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
    Object.send(:remove_const, :VersionableDatastream)
  end

  subject { test_object.descMetadata }

  context "that exists in the repository" do
    let(:test_object) { MockAFBase.create }

    after do
      test_object.destroy
    end

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
    end

    context "after creating the datastream" do
      before do
        subject.title = "Greetings Earthlings"
        subject.save
        subject.create_version
      end

      it "should set model_type to versionable" do
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version (plus the root version)" do
        expect(subject.versions.size).to eq 2
        expect(subject.versions.first).to be_kind_of RDF::URI
      end

      context "two times" do
        before do
          subject.title= "Surrender and prepare to be boarded"
          subject.save
          subject.create_version
        end

        it "should have two versions (plus the root version)" do
          expect(subject.versions.size).to eq 3
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::URI
          end
        end
      end
    end
  end
end

describe "a versionable OM datastream" do
  before(:all) do
    class VersionableDatastream < ActiveFedora::OmDatastream
      has_many_versions
      set_terminology do |t|
        t.root(path: "foo")
        t.title
      end
    end

    class MockAFBase < ActiveFedora::Base
      has_metadata "descMetadata", type: VersionableDatastream, autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
    Object.send(:remove_const, :VersionableDatastream)
  end

  subject { test_object.descMetadata }

  context "that exists in the repository" do
    let(:test_object) { MockAFBase.create }

    after do
      test_object.destroy
    end

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
    end

    context "after creating the datastream" do
      before do
        subject.title = "Greetings Earthlings"
        subject.save
        subject.create_version
      end

      it "should set model_type to versionable" do
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version (plus the root version)" do
        expect(subject.versions.size).to eq 2
        expect(subject.versions.first).to be_kind_of RDF::URI
      end

      context "two times" do
        before do
          subject.title= "Surrender and prepare to be boarded"
          subject.save
          subject.create_version
        end

        it "should have two versions (plus the root version)" do
          expect(subject.versions.size).to eq 3
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::URI
          end
        end
      end
    end
  end
end
