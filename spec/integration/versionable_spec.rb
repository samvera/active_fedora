require 'spec_helper'
require 'time'

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

      let(:version1) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/20180518230244', created: "20180518230244") }
      let(:version2) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/20180518230544', created: "20180518230544") }
      let(:versions) { [version1, version2] }

      it 'sorts by DateTime' do
        expect(graph.last).to eq version2
      end

      context 'with an unparseable created date' do
        let(:version2) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions/version2', created: '') }

        it 'raises an exception' do
          expect { graph.first }.to raise_error(ActiveFedora::VersionLacksCreateDate)
        end
      end

      context 'with a missing created date' do
        before do
          # Because mocks raise RSpec::Mocks::MockExpectationError instead
          allow(version2).to receive(:created) { raise NoMethodError }
        end

        let(:version2) { instance_double(ActiveFedora::VersionsGraph::ResourceVersion, uri: 'http://localhost:8983/fedora/rest/test/84/61/63/98/84616398-f63a-4572-ba01-0689339e4fcb/fcr:versions') }

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
        expect(object.versions.all.first.created).to start_with current_year
      end

      context "two times" do
        before do
          sleep(1)
          object.title = ["Surrender and prepare to be boarded"]
          object.save
          object.create_version
        end

        it "has two versions" do
          expect(object.versions.all.size).to eq 2
          object.versions.all.each_index do |index|
            expect(object.versions.all[index].created).to start_with current_year
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

        it "has one version" do
          expect(content.versions.all.size).to eq 1
          expect(content.original_name).to eql(first_name)
          expect(content.content.size).to eq first_file.size
          expect(content.versions.first.created).to start_with current_year
        end

        context "two times" do
          let(:second_file) { File.new(File.join(File.dirname(__FILE__), "../fixtures/minivan.jpg")) }
          let(:second_name) { "minivan.jpg" }
          before do
            sleep(1)
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
        end
      end
    end
  end
end
