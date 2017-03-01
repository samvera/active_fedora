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

    subject(:object) { WithVersions.new }

    let(:current_year) { DateTime.now.year.to_s }

    context "saved with no versions" do
      it "does not have versions" do
        object.update(title: ["Greetings Earthlings"])
        expect(object).not_to have_versions
      end
    end

    context "saved with versions" do
      it "has versions" do
        object.update(title: ["Greetings Earthlings"])
        object.create_version
        expect(object).to have_versions
      end
    end

    describe 'sorting versions' do
      subject(:graph) { ActiveFedora::VersionsGraph.new }

      before do
        allow(graph).to receive(:fedora_versions) { versions }
      end

      let(:version1) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e711aa993d-e1d2-4a65-93ee-3a12fc9541ab', label: 'version1', created: '2015-04-02T19:54:45.962Z') }
      let(:version2) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e790373a67-c9ee-447d-b740-4faa882b1a1f', label: 'version2', created: '2015-04-02T19:54:45.96Z') }
      let(:versions) { [version1, version2] }

      it 'sorts by DateTime' do
        expect(graph.first).to eq version2
      end

      context 'with an unparseable created date' do
        let(:version2) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e790373a67-c9ee-447d-b740-4faa882b1a1f', label: 'version2', created: '') }

        it 'raises an exception' do
          expect { graph.first }.to raise_error(ActiveFedora::VersionLacksCreateDate)
        end
      end

      context 'with a missing created date' do
        before do
          # Because mocks raise RSpec::Mocks::MockExpectationError instead
          allow(version2).to receive(:created) { raise NoMethodError }
        end

        let(:version2) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/87a0a8c317f1e790373a67-c9ee-447d-b740-4faa882b1a1f', label: 'version2') }

        it 'raises an exception' do
          expect { graph.first }.to raise_error(ActiveFedora::VersionLacksCreateDate)
        end
      end
    end

    context "after saving" do
      before do
        object.title = ["Greetings Earthlings"]
        object.save
        object.create_version
      end

      it { is_expected.to have_versions }

      it "has one version" do
        expect(object.versions).to be_kind_of ActiveFedora::VersionsGraph
        expect(object.versions.all.first).to be_kind_of ActiveFedora::VersionsGraph::ResourceVersion
        expect(object.versions.all.first.label).to eql "version1"
        expect(object.versions.all.first.created).to start_with current_year
      end

      context "two times" do
        before do
          object.title = ["Surrender and prepare to be boarded"]
          object.save
          object.create_version
        end

        it "has two versions" do
          expect(object.versions.all.size).to eq 2
          object.versions.all.each_index do |index|
            expect(object.versions.all[index].label).to end_with "version" + (index + 1).to_s
            expect(object.versions.all[index].created).to start_with current_year
          end
        end

        context "then restoring" do
          let(:first_version) { "version1" }
          before do
            object.restore_version(first_version)
          end

          it "will return to the first version's values" do
            expect(object.title).to eq(["Greetings Earthlings"])
          end

          context "and creating additional versions" do
            before do
              object.title = ["Now, surrender and prepare to be boarded"]
              object.save!
              object.create_version
            end

            it "has three versions" do
              expect(object.versions.all.size).to eq 3
              expect(object.title).to eq(["Now, surrender and prepare to be boarded"])
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

    let(:content) { test_object.content }

    let(:current_year) { DateTime.now.year.to_s }

    context "that exists in the repository" do
      let(:test_object) { MockAFBase.create }

      context "before creating the file" do
        it "does not have versions" do
          expect(content.versions).to be_empty
        end
      end

      context "after creating the file" do
        let(:first_file) { File.new(File.join(File.dirname(__FILE__), "../fixtures/dino.jpg")) }
        let(:first_name) { "dino.jpg" }
        before do
          content.content = first_file
          content.original_name = first_name
          content.save
          content.create_version
        end

        it "links to versions endpoint" do
          expect(content.metadata.ldp_source.graph.query(predicate: ::RDF::Vocab::Fcrepo4.hasVersions).objects).to_not be_empty
        end

        it "has one version" do
          expect(content.versions.all.size).to eq 1
          expect(content.original_name).to eql(first_name)
          expect(content.content.size).to eq first_file.size
          expect(content.versions.first.label).to eql "version1"
          expect(content.versions.first.created).to start_with current_year
        end

        context "two times" do
          let(:second_file) { File.new(File.join(File.dirname(__FILE__), "../fixtures/minivan.jpg")) }
          let(:second_name) { "minivan.jpg" }
          before do
            content.content = second_file
            content.original_name = second_name
            content.save
            content.create_version
          end

          it "has two unique versions" do
            expect(content.versions.all.size).to eq 2
            expect(content.original_name).to eql(second_name)
            expect(content.content.size).to eq second_file.size
            content.versions.all.each_index do |index|
              expect(content.versions.all[index].label).to end_with "version" + (index + 1).to_s
              expect(content.versions.all[index].created).to start_with current_year
            end
          end

          context "with fixity checking" do
            let(:results) do
              results = []
              content.versions.all.each do |version|
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
              content.restore_version(first_version)
            end

            it "stills have two unique versions" do
              expect(content.versions.all.size).to eq 2
            end

            it "loads the restored file's content" do
              expect(content.content.size).to eq first_file.size
            end

            it "loads the restored file's original name" do
              expect(content.original_name).to eql(first_name)
            end

            context "and creating additional versions" do
              before do
                content.content = first_file
                content.original_name = first_name
                content.save
                content.create_version
              end

              it "has three unique versions" do
                expect(content.versions.all.size).to eq 3
                expect(content.original_name).to eql(first_name)
                expect(content.content.size).to eq first_file.size
                content.versions.all.each_index do |index|
                  expect(content.versions.all[index].label).to end_with "version" + (index + 1).to_s
                  expect(content.versions.all[index].created).to start_with current_year
                end
              end
            end
          end
        end
      end
    end
  end
end
