require 'spec_helper'

require 'active_fedora'
require "rexml/document"

describe ActiveFedora::File do
  let(:file) { described_class.new }
  describe "#save" do
    context "with new files" do
      context "with a string" do
        before { file.content = "hello" }
        it "saves" do
          expect(file.save).to be true
        end
      end

      context "with no content" do
        before { file.content = nil }
        it "does not save" do
          expect(file.save).to be false
        end
      end
    end

    context "with UploadedFile" do
      before do
        module ActionDispatch
          module Http
            class UploadedFile
              def initialize
                @content = StringIO.new("hello world")
              end

              def read(a, b)
                @content.read(a, b)
              end

              def size
                @content.length
              end
            end
          end
        end
      end

      it "saves" do
        file.content = ActionDispatch::Http::UploadedFile.new
        file.save
        expect(file).not_to be_new_record
      end
    end
  end

  context "with a sub-resource that autocreates" do
    before do
      class MockAFBase < ActiveFedora::Base
        has_subresource "descMetadata", class_name: 'SampleResource', autocreate: true
      end

      class SampleResource < ActiveFedora::File
        def content
          'something to save'
        end
      end
    end

    after do
      Object.send(:remove_const, :SampleResource)
      Object.send(:remove_const, :MockAFBase)
    end

    let(:test_object) { MockAFBase.create }
    let(:descMetadata) { test_object.descMetadata }

    describe "changed attributes are set" do
      it "marks profile as changed" do
        expect_any_instance_of(SampleResource).to receive(:attribute_will_change!).with(:ldp_source)
        test_object
      end
    end

    describe "content_changed? is called" do
      before do
        allow_any_instance_of(SampleResource).to receive(:content_changed?).and_return(true)
      end
      subject { descMetadata.described_by }
      it { is_expected.to eq descMetadata.uri + '/fcr:metadata' }
    end
  end

  describe "#content" do
    let(:file) { described_class.new { |ds| ds.content = content } }

    before do
      file.save
    end

    describe "#content" do
      subject(:resource) { described_class.new(file.uri).content }

      before { content.rewind }

      context "when encoding is not set" do
        let(:content) { fixture('dino.jpg') }

        it "is read from fedora" do
          expect(resource).to eq content.read
          expect(resource.encoding).to eq Encoding::ASCII_8BIT
        end
      end

      context "when encoding is set" do
        let(:file) do
          described_class.new do |f|
            f.content = content
            f.mime_type = 'text/plain;charset=UTF-8'
          end
        end
        let(:content) { StringIO.new "I'm a little teåpot" }

        it "is read from fedora" do
          expect(resource).to eq content.read
          expect(resource.encoding).to eq Encoding::UTF_8
        end
      end
    end
  end

  context "with a sub-resource" do
    before do
      class MockAFBase < ActiveFedora::Base
        has_subresource "descMetadata", class_name: 'SampleResource'
      end

      class SampleResource < ActiveFedora::File
      end
    end

    after do
      Object.send(:remove_const, :SampleResource)
      Object.send(:remove_const, :MockAFBase)
    end

    let(:test_object) { MockAFBase.create }
    let(:descMetadata) { test_object.descMetadata }

    describe "the metadata file" do
      subject { descMetadata }
      it { is_expected.to be_a_kind_of(described_class) }
    end

    context "a binary file" do
      let(:path) { "ds#{Time.now.to_i}" }
      let(:content) { fixture('dino.jpg') }
      let(:file) { described_class.new { |ds| ds.content = content } }

      before do
        test_object.attach_file(file, path)
        test_object.save
      end

      it "is not changed" do
        expect(test_object.attached_files[path]).to_not be_content_changed
      end

      describe "streaming the response" do
        let(:stream_reader) { instance_double(IO) }
        it "streams the response" do
          expect(stream_reader).to receive(:read).at_least(:once)
          test_object.attached_files[path].stream.each { |buff| stream_reader.read(buff) }
        end

        context "with a range request" do
          before do
            test_object.add_file('one1two2threfour', path: 'webm', mime_type: 'video/webm')
            test_object.save!
          end
          subject { str = ''; test_object.webm.stream(range).each { |chunk| str << chunk }; str }
          context "whole thing" do
            let(:range) { 'bytes=0-15' }
            it { is_expected.to eq 'one1two2threfour' }
          end
          context "open ended" do
            let(:range) { 'bytes=0-' }
            it { is_expected.to eq 'one1two2threfour' }
          end
          context "not starting at the beginning" do
            let(:range) { 'bytes=3-15' }
            it { is_expected.to eq '1two2threfour' }
          end
          context "not ending at the end" do
            let(:range) { 'bytes=4-11' }
            it { is_expected.to eq 'two2thre' }
          end
        end

        context "when the request results in a redirect" do
          before do
            test_object.add_file('one1two2threfour', path: 'webm', mime_type: 'video/webm')
            test_object.add_file('', path: 'redirector', mime_type: 'video/webm', external_uri: test_object.webm.uri, external_handling: 'redirect')
            test_object.save!
            test_object.reload
          end
          subject { str = ''; test_object.redirector.stream.each { |chunk| str << chunk }; str }
          it { is_expected.to eq 'one1two2threfour' }
        end

        context "when there are more than 3 requests because of redirects" do
          before do
            test_object.add_file('', path: 'one', external_uri: test_object.attached_files[path].uri, external_handling: 'redirect')
            test_object.add_file('', path: 'two', external_uri: test_object.one.uri, external_handling: 'redirect')
            test_object.add_file('', path: 'three', external_uri: test_object.two.uri, external_handling: 'redirect')
            test_object.save!
          end
          it "raises a HTTP redirect too deep Error" do
            expect { test_object.three.stream.each { |chunk| chunk } }.to raise_error('HTTP redirect too deep')
          end
        end
      end
    end
  end
end
