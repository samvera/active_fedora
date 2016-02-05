require 'spec_helper'

describe ActiveFedora::Versionable do
  context "For ActiveFedora::Base" do
    before do
      class WithVersions < ActiveFedora::Base
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end

    after do
      Object.send(:remove_const, :WithVersions)
    end

    subject { WithVersions.new }

    let(:current_year) { DateTime.now.year.to_s }

    context "saved with no versions" do
      it "does not have versions" do
        subject.update(title: ["Greetings Earthlings"])
        expect(subject).not_to have_versions
      end
    end

    context "saved with versions" do
      it "has versions" do
        subject.update(title: ["Greetings Earthlings"])
        subject.create_version
        expect(subject).to have_versions
      end
    end

    describe 'sorting versions' do
      before do
        allow(subject).to receive(:fedora_versions) { versions }
      end

      let(:version1) { double('version1', uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e711aa993d-e1d2-4a65-93ee-3a12fc9541ab', label: 'version1', created: '2015-04-02T19:54:45.962Z') }
      let(:version2) { double('version2', uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e790373a67-c9ee-447d-b740-4faa882b1a1f', label: 'version2', created: '2015-04-02T19:54:45.96Z') }
      let(:versions) { [version1, version2] }

      subject { ActiveFedora::VersionsGraph.new }

      it 'sorts by DateTime' do
        expect(subject.first).to eq version2
      end

      context 'with an unparseable created date' do
        let(:version2) { double('version2', uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e790373a67-c9ee-447d-b740-4faa882b1a1f', label: 'version2', created: '') }

        it 'raises an exception' do
          expect { subject.first }.to raise_error(ActiveFedora::VersionLacksCreateDate)
        end
      end

      context 'with a missing created date' do
        before do
          # Because mocks raise RSpec::Mocks::MockExpectationError instead
          allow(version2).to receive(:created) { raise NoMethodError }
        end

        let(:version2) { double('version2', uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e790373a67-c9ee-447d-b740-4faa882b1a1f', label: 'version2') }

        it 'raises an exception' do
          expect { subject.first }.to raise_error(ActiveFedora::VersionLacksCreateDate)
        end
      end
    end

    context "after saving" do
      before do
        subject.title = ["Greetings Earthlings"]
        subject.save
        subject.create_version
      end

      it { is_expected.to have_versions }

      it "has one version" do
        expect(subject.versions).to be_kind_of ActiveFedora::VersionsGraph
        expect(subject.versions.all.first).to be_kind_of ActiveFedora::VersionsGraph::ResourceVersion
        expect(subject.versions.all.first.label).to eql "version1"
        expect(subject.versions.all.first.created).to start_with current_year
      end

      context "two times" do
        before do
          subject.title = ["Surrender and prepare to be boarded"]
          subject.save
          subject.create_version
        end

        it "has two versions" do
          expect(subject.versions.all.size).to eq 2
          subject.versions.all.each_index do |index|
            expect(subject.versions.all[index].label).to end_with "version" + (index + 1).to_s
            expect(subject.versions.all[index].created).to start_with current_year
          end
        end

        context "then restoring" do
          let(:first_version) { "version1" }
          before do
            subject.restore_version(first_version)
          end

          it "will return to the first version's values" do
            expect(subject.title).to eq(["Greetings Earthlings"])
          end

          context "and creating additional versions" do
            before do
              subject.title = ["Now, surrender and prepare to be boarded"]
              subject.save!
              subject.create_version
            end

            it "has three versions" do
              expect(subject.versions.all.size).to eq 3
              expect(subject.title).to eq(["Now, surrender and prepare to be boarded"])
            end
          end
        end
      end
    end
  end

  describe ActiveFedora::NtriplesRDFDatastream do
    before(:all) do
      class VersionableDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, predicate: ::RDF::Vocab::DC.title
      end

      class MockAFBase < ActiveFedora::Base
        has_subresource "descMetadata", class_name: 'VersionableDatastream', autocreate: true
      end
    end

    after(:all) do
      Object.send(:remove_const, :MockAFBase)
      Object.send(:remove_const, :VersionableDatastream)
    end

    it "creates the object" do
      MockAFBase.create
    end

    subject { test_object.descMetadata }

    let(:current_year) { DateTime.now.year.to_s }

    context "that exists in the repository" do
      let(:test_object) { MockAFBase.create }

      context "before creating the file" do
        it "does not have versions" do
          expect(subject.versions).to be_empty
        end
        it "does not have a title" do
          expect(subject.title).to be_empty
        end
      end

      context "after creating the file" do
        before do
          subject.title = "Greetings Earthlings"
          subject.save
          subject.create_version
          @original_size = subject.size
        end

        it "links to versions endpoint" do
          expect(subject.metadata.ldp_source.graph.query(predicate: ::RDF::Vocab::Fcrepo4.hasVersions).objects).to_not be_empty
        end

        it "has one version" do
          expect(subject.versions.first.label).to eql "version1"
        end

        it "has a title" do
          expect(subject.title).to eq(["Greetings Earthlings"])
        end

        it "has a size" do
          expect(subject.size).to_not be_nil
        end

        context "two times" do
          before do
            subject.title = "Surrender and prepare to be boarded"
            subject.save
            subject.create_version
          end

          it "has two versions" do
            expect(subject.versions.all.size).to eq 2
            subject.versions.all.each_index do |index|
              expect(subject.versions.all[index].label).to end_with "version" + (index + 1).to_s
              expect(subject.versions.all[index].created).to start_with current_year
            end
          end

          it "has the new title" do
            expect(subject.title).to eq(["Surrender and prepare to be boarded"])
          end

          it "has a new size" do
            expect(subject.size).to_not be_nil
            expect(subject.size).to_not eq(@original_size)
          end

          context "then restoring" do
            let(:first_version) { "version1" }
            before do
              subject.restore_version(first_version)
            end

            it "has two unique versions" do
              expect(subject.versions.all.size).to eq 2
            end

            it "loads the restored file's content" do
              expect(subject.title).to eq(["Greetings Earthlings"])
            end

            it "is the same size as the original file" do
              expect(subject.size).to eq @original_size
            end

            context "and creating additional versions" do
              before do
                subject.title = "Now, surrender and prepare to be boarded"
                subject.save
                subject.create_version
              end

              it "has three unique versions" do
                expect(subject.versions.all.size).to eq 3
              end

              it "has a new title" do
                expect(subject.title).to eq(["Now, surrender and prepare to be boarded"])
              end

              it "has a new size" do
                expect(subject.size).to_not eq @original_size
              end
            end
          end
        end
      end
    end
  end

  describe ActiveFedora::OmDatastream do
    before(:all) do
      class VersionableDatastream < ActiveFedora::OmDatastream
        set_terminology do |t|
          t.root(path: "foo")
          t.title
        end
      end

      class MockAFBase < ActiveFedora::Base
        has_subresource "descMetadata", class_name: 'VersionableDatastream', autocreate: true
      end
    end

    after(:all) do
      Object.send(:remove_const, :MockAFBase)
      Object.send(:remove_const, :VersionableDatastream)
    end

    subject { test_object.descMetadata }

    let(:current_year) { DateTime.now.year.to_s }

    context "that exists in the repository" do
      let(:test_object) { MockAFBase.create }

      context "before creating the file" do
        it "does not have versions" do
          expect(subject.versions).to be_empty
        end
        it "does not have a title" do
          expect(subject.title).to be_empty
        end
      end

      context "after creating the file" do
        before do
          subject.title = "Greetings Earthlings"
          subject.save
          subject.create_version
          @original_size = subject.size
        end

        it "links to versions endpoint" do
          expect(subject.metadata.ldp_source.graph.query(predicate: ::RDF::Vocab::Fcrepo4.hasVersions).objects).to_not be_empty
        end

        it "has one version" do
          expect(subject.versions.first.label).to eql "version1"
          expect(subject.versions.first.created).to start_with current_year
        end

        it "has a title" do
          expect(subject.title).to eql(["Greetings Earthlings"])
        end

        it "has a size" do
          expect(subject.size).to_not be_nil
        end

        context "two times" do
          before do
            subject.title = "Surrender and prepare to be boarded"
            subject.save
            subject.create_version
          end

          it "has two unique versions" do
            expect(subject.versions.all.size).to eq 2
            subject.versions.all.each_index do |index|
              expect(subject.versions.all[index].label).to end_with "version" + (index + 1).to_s
              expect(subject.versions.all[index].created).to start_with current_year
            end
          end

          it "has the new title" do
            expect(subject.title).to eql(["Surrender and prepare to be boarded"])
          end

          it "has a new size" do
            expect(subject.size).to_not be_nil
            expect(subject.size).to_not eq(@original_size)
          end

          context "then restoring" do
            let(:first_version) { "version1" }
            before do
              subject.restore_version(first_version)
            end

            it "stills have two unique versions" do
              expect(subject.versions.all.size).to eq 2
            end

            it "loads the restored file's content" do
              expect(subject.title).to eql(["Greetings Earthlings"])
            end

            it "is the same size as the original file" do
              expect(subject.size).to eq @original_size
            end

            context "and creating additional versions" do
              before do
                subject.title = "Now, surrender and prepare to be boarded"
                subject.save
                subject.create_version
              end

              it "has three unique versions" do
                expect(subject.versions.all.size).to eq 3
              end

              it "has a new title" do
                expect(subject.title).to eql(["Now, surrender and prepare to be boarded"])
              end

              it "has a new size" do
                expect(subject.size).to_not eq @original_size
              end
            end
          end
        end
      end
    end
  end

  describe ActiveFedora::File do
    before(:all) do
      class BinaryDatastream < ActiveFedora::File
      end

      class MockAFBase < ActiveFedora::Base
        has_subresource "content", class_name: 'BinaryDatastream', autocreate: true
      end
    end

    after(:all) do
      Object.send(:remove_const, :MockAFBase)
      Object.send(:remove_const, :BinaryDatastream)
    end

    subject { test_object.content }

    let(:current_year) { DateTime.now.year.to_s }

    context "that exists in the repository" do
      let(:test_object) { MockAFBase.create }

      context "before creating the file" do
        it "does not have versions" do
          expect(subject.versions).to be_empty
        end
      end

      context "after creating the file" do
        let(:first_file) { File.new(File.join(File.dirname(__FILE__), "../fixtures/dino.jpg")) }
        let(:first_name) { "dino.jpg" }
        before do
          subject.content = first_file
          subject.original_name = first_name
          subject.save
          subject.create_version
        end

        it "links to versions endpoint" do
          expect(subject.metadata.ldp_source.graph.query(predicate: ::RDF::Vocab::Fcrepo4.hasVersions).objects).to_not be_empty
        end

        it "has one version" do
          expect(subject.versions.all.size).to eq 1
          expect(subject.original_name).to eql(first_name)
          expect(subject.content.size).to eq first_file.size
          expect(subject.versions.first.label).to eql "version1"
          expect(subject.versions.first.created).to start_with current_year
        end

        context "two times" do
          let(:second_file) { File.new(File.join(File.dirname(__FILE__), "../fixtures/minivan.jpg")) }
          let(:second_name) { "minivan.jpg" }
          before do
            subject.content = second_file
            subject.original_name = second_name
            subject.save
            subject.create_version
          end

          it "has two unique versions" do
            expect(subject.versions.all.size).to eq 2
            expect(subject.original_name).to eql(second_name)
            expect(subject.content.size).to eq second_file.size
            subject.versions.all.each_index do |index|
              expect(subject.versions.all[index].label).to end_with "version" + (index + 1).to_s
              expect(subject.versions.all[index].created).to start_with current_year
            end
          end

          context "with fixity checking" do
            let(:results) do
              results = []
              subject.versions.all.each do |version|
                results << ActiveFedora::FixityService.new(version.uri).check
              end
              return results
            end

            it "reports on the fixity of each version" do
              results.each do |result|
                expect(result).to be true
              end
            end
          end

          context "then restoring" do
            let(:first_version) { "version1" }
            before do
              subject.restore_version(first_version)
            end

            it "stills have two unique versions" do
              expect(subject.versions.all.size).to eq 2
            end

            it "loads the restored file's content" do
              expect(subject.content.size).to eq first_file.size
            end

            it "loads the restored file's original name" do
              expect(subject.original_name).to eql(first_name)
            end

            context "and creating additional versions" do
              before do
                subject.content = first_file
                subject.original_name = first_name
                subject.save
                subject.create_version
              end

              it "has three unique versions" do
                expect(subject.versions.all.size).to eq 3
                expect(subject.original_name).to eql(first_name)
                expect(subject.content.size).to eq first_file.size
                subject.versions.all.each_index do |index|
                  expect(subject.versions.all[index].label).to end_with "version" + (index + 1).to_s
                  expect(subject.versions.all[index].created).to start_with current_year
                end
              end
            end
          end
        end
      end
    end
  end
end
