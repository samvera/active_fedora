require 'spec_helper'

describe "a versionable class" do
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

  it { is_expected.to be_versionable }

  context "after saving" do
    before do
      subject.title = "Greetings Earthlings"
      subject.save
      subject.create_version
    end

    it "should set model_type to versionable" do
      expect(subject.reload.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
    end

    it "should have one version" do
      expect(subject.versions.size).to eq 1
      expect(subject.versions.first).to be_kind_of RDF::Literal
    end

    context "two times" do
      before do
        subject.title = "Surrender and prepare to be boarded"
        subject.save
        subject.create_version
      end

      it "should have two versions" do
        expect(subject.versions.size).to eq 2
        subject.versions.each do |version|
          expect(version).to be_kind_of RDF::Literal
        end
      end

      context "then restoring" do
        let(:first_version) { "version1" }
        before do
          subject.restore_version(first_version)
        end

        it "will return to the first version's values" do
          expect(subject.title).to eql(["Greetings Earthlings"])
        end

        context "and creating additional versions" do
          before do
            subject.title = "Now, surrender and prepare to be boarded"
            subject.save!
            subject.create_version
          end

          it "should have three versions" do
            expect(subject.versions.size).to eq 3
            expect(subject.title).to eql(["Now, surrender and prepare to be boarded"])
          end

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

  it "should create the object" do
    MockAFBase.create
  end

  subject { test_object.descMetadata }

  context "that exists in the repository" do
    let(:test_object) { MockAFBase.create }

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
      it "should not have a title" do
        expect(subject.title).to be_empty
      end
    end

    context "after creating the datastream" do
      before do
        subject.title = "Greetings Earthlings"
        subject.save
        subject.create_version
        @original_size = subject.size
      end

      it "should set model_type to versionable" do
        pending "This isn't getting saved because it should probaly go on fcr:metadata"
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version" do
        expect(subject.versions.first).to be_kind_of RDF::Literal
      end

      it "should have a title" do
        expect(subject.title).to eql(["Greetings Earthlings"])
      end

      it "should have a size" do
        expect(subject.size).to_not be_nil
      end

      context "two times" do
        before do
          subject.title = "Surrender and prepare to be boarded"
          subject.save
          subject.create_version
        end

        it "should have two versions" do
          expect(subject.versions.size).to eq 2
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::Literal
          end
        end

        it "should have the new title" do
          expect(subject.title).to eql(["Surrender and prepare to be boarded"])
        end

        it "should have a new size" do
          expect(subject.size).to_not be_nil
          expect(subject.size).to_not eq(@original_size)
        end

        context "then restoring" do
          let(:first_version) { "version1" }
          before do
            subject.restore_version(first_version)
          end

          it "should have two unique versions" do
            expect(subject.versions.size).to eq 2      
          end

          it "should load the restored datastream's content" do
            expect(subject.title).to eql(["Greetings Earthlings"])
          end

          it "should be the same size as the original datastream" do
            expect(subject.size).to eq @original_size
          end

          context "and creating additional versions" do
            before do
              subject.title = "Now, surrender and prepare to be boarded"
              subject.save
              subject.create_version
            end

            it "should have three unique versions" do
              expect(subject.versions.size).to eq 3
            end

            it "should have a new title" do
              expect(subject.title).to eql(["Now, surrender and prepare to be boarded"])
            end

            it "should have a new size" do
              expect(subject.size).to_not eq @original_size
            end

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

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
      it "should not have a title" do
        expect(subject.title).to be_empty
      end
    end

    context "after creating the datastream" do
      before do
        subject.title = "Greetings Earthlings"
        subject.save
        subject.create_version
        @original_size = subject.size
      end

      it "should set model_type to versionable" do
        pending "This isn't getting saved because it should probaly go on fcr:metadata"
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version" do
        expect(subject.versions.size).to eq 1
        expect(subject.versions.first).to be_kind_of RDF::Literal
      end

      it "should have a title" do
        expect(subject.title).to eql(["Greetings Earthlings"])
      end

      it "should have a size" do
        expect(subject.size).to_not be_nil
      end

      context "two times" do

        before do
          subject.title = "Surrender and prepare to be boarded"
          subject.save
          subject.create_version
        end

        it "should have two unique versions" do
          expect(subject.versions.size).to eq 2
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::Literal
          end
        end

        it "should have the new title" do
          expect(subject.title).to eql(["Surrender and prepare to be boarded"])
        end

        it "should have a new size" do
          expect(subject.size).to_not be_nil
          expect(subject.size).to_not eq(@original_size)
        end

        context "then restoring" do
          let(:first_version) { "version1" }
          before do
            subject.restore_version(first_version)
          end

          it "should still have two unique versions" do
            expect(subject.versions.size).to eq 2
          end

          it "should load the restored datastream's content" do
            expect(subject.title).to eql(["Greetings Earthlings"])
          end

          it "should be the same size as the original datastream" do
            expect(subject.size).to eq @original_size
          end

          context "and creating additional versions" do
            before do
              subject.title = "Now, surrender and prepare to be boarded"
              subject.save
              subject.create_version
            end

            it "should have three unique versions" do
              expect(subject.versions.size).to eq 3
            end

            it "should have a new title" do
              expect(subject.title).to eql(["Now, surrender and prepare to be boarded"])
            end

            it "should have a new size" do
              expect(subject.size).to_not eq @original_size
            end

          end
        end
      end
    end
  end
end

describe "a versionable binary datastream" do
  before(:all) do
    class BinaryDatastream < ActiveFedora::File
      has_many_versions
    end

    class MockAFBase < ActiveFedora::Base
      has_file_datastream "content", type: BinaryDatastream, autocreate: true
    end
  end

  after(:all) do
    Object.send(:remove_const, :MockAFBase)
    Object.send(:remove_const, :BinaryDatastream)
  end

  subject { test_object.content }

  context "that exists in the repository" do
    let(:test_object) { MockAFBase.create }

    it "should be versionable" do
      expect(subject).to be_versionable
    end

    context "before creating the datastream" do
      it "should not have versions" do
        expect(subject.versions).to be_empty
      end
    end

    context "after creating the datastream" do
      let(:first_file) { File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" )) }
      let(:first_name) { "dino.jpg" }
      before do
        subject.content = first_file
        subject.original_name = first_name
        subject.save
        subject.create_version
      end

      it "should set model_type to versionable" do
        pending "This isn't getting saved because it should probaly go on fcr:metadata"
        expect(subject.model_type).to include RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')
      end

      it "should have one version" do
        expect(subject.versions.size).to eq 1
        expect(subject.original_name).to eql(first_name)
        expect(subject.content.size).to eq first_file.size
        expect(subject.versions.first).to be_kind_of RDF::Literal
      end

      context "two times" do
        let(:second_file) { File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg" )) }
        let(:second_name) { "minivan.jpg" }
        before do
          subject.content = second_file
          subject.original_name = second_name
          subject.save
          subject.create_version
        end

        it "should have two unique versions" do
          expect(subject.versions.size).to eq 2
          expect(subject.original_name).to eql(second_name)
          expect(subject.content.size).to eq second_file.size
          subject.versions.each do |version|
            expect(version).to be_kind_of RDF::Literal
          end
        end

        context "then restoring" do
          let(:first_version) { "version1" }
          before do
            subject.restore_version(first_version)
          end

          it "should still have two unique versions" do
            expect(subject.versions.size).to eq 2
          end

          it "should load the restored datastream's content" do
            expect(subject.content.size).to eq first_file.size
          end

          it "should load the restored datastream's original name" do
            expect(subject.original_name).to eql(first_name)
          end

          context "and creating additional versions" do
            before do
              subject.content = first_file
              subject.original_name = first_name
              subject.save
              subject.create_version
            end

            it "should have three unique versions" do
              expect(subject.versions.size).to eq 3
              expect(subject.original_name).to eql(first_name)
              expect(subject.content.size).to eq first_file.size
              expect(subject.versions.first).to be_kind_of RDF::Literal
            end

          end
        end
      end
    end
  end
end

describe "a non-versionable resource" do 
  before(:all) do
    class NotVersionableWithVersions < ActiveFedora::Base
      # explicitly don't call has_many_versions 
      property :title, predicate: RDF::DC.title
    end
  end

  after(:all) do
    Object.send(:remove_const, :NotVersionableWithVersions)
  end

  subject { NotVersionableWithVersions.new }

  context "saved with no versions" do
    it "should not have versions" do
      subject.update(title: "Greetings Earthlings")
      expect(subject).not_to have_versions
    end
  end

  context "saved with versions" do
    it "should have versions" do
      subject.update(title: "Greetings Earthlings")
      subject.create_version
      expect(subject).to have_versions
    end
  end
end