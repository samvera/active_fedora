require 'spec_helper'

describe ActiveFedora::File do
  let(:file) { described_class.new }

  subject { file }

  it { is_expected.not_to be_metadata }

  describe "#behaves_like_io?" do
    subject { file.send(:behaves_like_io?, object) }

    context "with a File" do
      let(:object) { File.new __FILE__ }
      it { is_expected.to be true }
    end

    context "with a Tempfile" do
      after { object.close; object.unlink }
      let(:object) { Tempfile.new('foo') }
      it { is_expected.to be true }
    end

    context "with a StringIO" do
      let(:object) { StringIO.new('foo') }
      it { is_expected.to be true }
    end
  end

  describe "#uri" do
    subject { file.uri }

    context "when the file is in an ldp:BasicContainer" do
      let(:parent) { ActiveFedora::Base.new(id: '1234') }
      before { allow(Deprecation).to receive(:warn) }
      let(:file) { described_class.new(parent, 'FOO1') }

      it "sets the uri using the parent as the base" do
        expect(subject).to eq "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/1234/FOO1"
      end

      context "and it's initialized with the URI" do
        let(:file) { described_class.new(parent.uri + "/FOO1") }
        it "works" do
          expect(subject.to_s).to eq "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/1234/FOO1"
        end
      end

      context "and it's initialized with an ID" do
        let(:file) { described_class.new(parent.id + "/FOO1") }
        it "works" do
          expect(subject.to_s).to eq "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/1234/FOO1"
        end
      end
    end

    context "when the file doesn't have a uri" do
      it { is_expected.to eq ::RDF::URI(nil) }
    end
  end

  context "content" do
    let(:mock_conn) do
      Faraday.new do |builder|
        builder.adapter :test, conn_stubs do |_stub|
        end
      end
    end

    let(:mock_client) do
      Ldp::Client.new mock_conn
    end

    let(:conn_stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.head(path) { [200, { 'Content-Length' => '9999' }] }
      end
    end

    let(:path) { '/fedora/rest/test/1234/abcd' }

    let(:ldp_source) { Ldp::Resource.new(mock_client, path) }

    before do
      allow(subject).to receive(:ldp_source).and_return(ldp_source)
    end

    describe '#persisted_size' do
      it 'loads the file size attribute from the fedora repository' do
        expect(subject.size).to eq 9999
      end

      it 'returns nil without making a head request to Ldp::Resource::BinarySource if it is a new record' do
        allow(subject).to receive(:new_record?).and_return(true)
        expect(subject.ldp_source).not_to receive(:head)
        expect(subject.persisted_size).to eq nil
      end
    end

    describe '#dirty_size' do
      context 'when content has changed from what is currently persisted' do
        context 'and has been set to something that has a #size method (i.e. string or File)' do
          it 'returns the size of the dirty content' do
            dirty_content = double
            allow(dirty_content).to receive(:size) { 8_675_309 }
            subject.content = dirty_content
            expect(subject.size).to eq dirty_content.size
          end
        end
      end

      context 'when content has not changed from what is currently persisted' do
        it 'returns nil, indicating that the content is not "dirty", but its not necessarily 0 either.' do
          expect(subject.dirty_size).to be_nil
        end
      end
    end

    describe '#size' do
      context 'when content has not changed' do
        it 'returns the value of .persisted_size' do
          expect(subject.size).to eq subject.persisted_size
        end
      end

      context 'when content has changed' do
        it 'returns the value of .dirty_size' do
          subject.content = "i have changed!"
          expect(subject.size).to eq subject.dirty_size
        end
      end

      it 'returns nil when #persisted_size and #dirty_size return nil' do
        allow(subject).to receive(:persisted_size) { nil }
        allow(subject).to receive(:dirty_size) { nil }
        expect(subject.size).to be_nil
      end
    end

    describe ".empty?" do
      it "does not be empty" do
        expect(subject.empty?).to be false
      end
    end

    describe ".has_content?" do
      context "when there's content" do
        before do
          allow(subject).to receive(:size).and_return(10)
        end
        it "returns true" do
          expect(subject.has_content?).to be true
        end
      end

      context "when size is nil" do
        before do
          allow(subject).to receive(:size).and_return(nil)
        end
        it "does not have content" do
          expect(subject).to_not have_content
        end
      end

      context "when content is zero" do
        before do
          allow(subject).to receive(:size).and_return(0)
        end
        it "returns false" do
          expect(subject.has_content?).to be false
        end
      end
    end
  end

  context "when the file has local content" do
    before do
      file.uri = "http://localhost:8983/fedora/rest/test/1234/abcd"
      file.content = "hi there"
    end

    describe "#inspect" do
      subject { file.inspect }
      it { is_expected.to eq "#<ActiveFedora::File uri=\"http://localhost:8983/fedora/rest/test/1234/abcd\" >" }
    end
  end

  describe "#mime_type" do
    let(:parent) { ActiveFedora::Base.create }
    before do
      parent.add_file('banana', path: 'apple', mime_type: 'video/webm')
      parent.save!
    end
    it "persists" do
      expect(parent.reload.apple.mime_type).to eq "video/webm"
    end
    it "can be updated" do
      parent.reload
      parent.apple.mime_type = "text/awesome"
      expect(parent.apple.mime_type).to eq "text/awesome"
      parent.save

      expect(parent.reload.apple.mime_type).to eq "text/awesome"
    end
  end

  context "original_name" do
    subject { file.original_name }

    context "on a new file" do
      context "that has a name set locally" do
        before { file.original_name = "my_image.png" }
        it { is_expected.to eq "my_image.png" }
      end

      context "that doesn't have a name set locally" do
        it { is_expected.to be_nil }
      end
    end

    context "when it's saved" do
      let(:parent) { ActiveFedora::Base.create }
      before do
        parent.add_file('one1two2threfour', path: 'abcd', mime_type: 'video/webm', original_name: 'my image.png')
        parent.save!
      end

      it "has original_name" do
        expect(parent.reload.abcd.original_name).to eq 'my image.png'
      end
    end

    context "with special characters" do
      let(:parent) { ActiveFedora::Base.create }
      before do
        parent.add_file('one1two2threfour', path: 'abcd', mime_type: 'video/webm', original_name: 'my "image".png')
        parent.save!
      end
      it "saves OK and preserve name" do
        expect(parent.reload.abcd.original_name).to eq 'my "image".png'
      end
    end
  end

  context "digest" do
    subject { file.digest }

    context "on a new file" do
      it { is_expected.to be_empty }
    end

    context "when it's saved" do
      let(:parent) { ActiveFedora::Base.create }
      before do
        parent.add_file('one1two2threfour', path: 'abcd', mime_type: 'video/webm')
        parent.save!
      end

      it "has digest" do
        expect(parent.reload.abcd.digest.first).to be_kind_of RDF::URI
      end
    end
    context "with pre-4.3.0 predicate" do
      before do
        predicate = ::RDF::URI("http://fedora.info/definitions/v4/repository#digest")
        object = RDF::URI.new("urn:sha1:f1d2d2f924e986ac86fdf7b36c94bcdf32beec15")
        graph = ActiveTriples::Resource.new
        graph << RDF::Statement.new(file.uri, predicate, object)
        allow(file).to receive_message_chain(:metadata, :ldp_source, :graph).and_return(graph)
      end
      it "falls back on fedora:digest if premis:hasMessageDigest is not present" do
        expect(file.digest.first).to be_kind_of RDF::URI
      end
    end
  end

  describe "#checksum" do
    let(:digest) { RDF::URI.new("urn:sha1:f1d2d2f924e986ac86fdf7b36c94bcdf32beec15") }
    before do
      allow(subject).to receive(:digest) { [digest] }
    end
    its(:checksum) { is_expected.to be_a(ActiveFedora::Checksum) }
    it "has the right value" do
      expect(subject.checksum.value).to eq("f1d2d2f924e986ac86fdf7b36c94bcdf32beec15")
    end
    it "has the right algorithm" do
      expect(subject.checksum.algorithm).to eq("SHA1")
    end
  end

  describe "#save" do
    let(:file) { described_class.new }
    context "when there is nothing to save" do
      it "does not write" do
        expect(file.ldp_source).not_to receive(:create)
        expect(file.save).to be false
      end
    end
  end

  describe "#create_date" do
    subject { file.create_date }
    describe "when new record" do
      it { is_expected.to be_nil }
    end
    describe "when persisted" do
      before do
        file.content = "foo"
        file.save!
      end
      it { is_expected.to be_a(DateTime) }
    end
  end

  describe "callbacks" do
    before do
      class MyFile < ActiveFedora::File
        after_initialize :a_init
        before_create :b_create
        after_create :a_create
        before_update :b_update
        after_update :a_update
        before_save :b_save
        after_save :a_save
        before_destroy :b_destroy
        after_destroy :a_destroy

        def a_init; end

        def b_create; end

        def a_create; end

        def b_save; end

        def a_save; end

        def b_destroy; end

        def a_destroy; end

        def b_update; end

        def a_update; end
      end
    end

    after do
      Object.send(:remove_const, :MyFile)
    end

    subject { MyFile.new }

    describe "initialize" do
      specify {
        expect_any_instance_of(MyFile).to receive(:a_init)
        MyFile.new
      }
    end

    describe "create" do
      describe "when content is not nil" do
        specify {
          expect(subject).to receive(:b_create).once
          expect(subject).to receive(:a_create).once
          expect(subject).to receive(:b_save).once
          expect(subject).to receive(:a_save).once
          subject.content = "foo"
          subject.save
        }
      end
      describe "when content is nil" do
        specify {
          expect(subject).to receive(:b_create).once
          expect(subject).not_to receive(:a_create)
          expect(subject).to receive(:b_save).once
          expect(subject).not_to receive(:a_save)
          subject.save
        }
      end
    end

    describe "update" do
      describe "when content has changed" do
        specify {
          subject.content = "foo"
          subject.save
          expect(subject).to receive(:b_save).once
          expect(subject).to receive(:a_save).once
          expect(subject).to receive(:b_update).once
          expect(subject).to receive(:a_update).once
          subject.content = "bar"
          subject.save
        }
      end
      describe "when content has not changed" do
        specify {
          subject.content = "foo"
          subject.save
          expect(subject).to receive(:b_save).once
          expect(subject).to receive(:a_save)
          expect(subject).to receive(:b_update).once
          expect(subject).to receive(:a_update)
          subject.save
        }
      end
    end

    describe "destroy" do
      specify {
        subject.content = "foo"
        subject.save
        expect(subject).to receive(:b_destroy).once
        expect(subject).to receive(:a_destroy).once
        subject.destroy
      }
    end
  end
end
