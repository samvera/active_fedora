require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Library < ActiveFedora::Base
    end
    class Book < ActiveFedora::Base
      belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
      property :title, predicate: ::RDF::Vocab::DC.title, multiple: false
      property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: false
    end
  end

  subject(:book) { Book.new(library: library, title: "War and Peace", publisher: "Random House") }
  let(:library) { Library.create }

  after do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Library)
  end

  it "asserts a content model" do
    expect(book.has_model).to eq ['Book']
  end

  describe "initialize" do
    context "with a block" do
      subject(:book) { Book.new { |b| b.title = "The Sun also Rises" } }

      it "has set the title" do
        expect(book.title).to eq "The Sun also Rises"
      end
    end

    context "with an identifier" do
      subject(:book) { Book.new(attributes) }
      let(:attributes) { { id: '1234' } }

      it "sets the id and doesn't modify the passed hash" do
        expect(book.id).to eq '1234'
        expect(attributes[:id]).to eq '1234'
      end
    end
  end

  describe '#etag' do
    let(:attributes) { { id: '1234' } }

    it 'before save raises an error' do
      expect { book.etag }
        .to raise_error 'Unable to produce an etag for a unsaved object'
    end

    context 'after save' do
      before { book.save! }

      it 'has the etag from the ldp_source' do
        expect(book.etag).to eq book.ldp_source.head.etag
      end

      it 'after delete raises Ldp::Gone' do
        book.destroy!
        expect { book.etag }.to raise_error Ldp::Gone
      end
    end
  end

  describe "#freeze" do
    before { book.freeze }

    it "is frozen" do
      expect(book).to be_frozen
    end

    it "makes the associations immutable" do
      expect {
        book.library_id = Library.create!.id
      }.to raise_error RuntimeError, "can't modify frozen Book"
      expect(book.library_id).to eq library.id
    end

    describe "when the association is set via an id" do
      subject(:book) { Book.new(library_id: library.id) }
      it "is able to load the association" do
        expect(book.library).to eq library
      end
    end

    it "makes the properties immutable" do
      expect {
        book.publisher = "HEY"
      }.to raise_error TypeError
      expect(book.publisher).to eq "Random House"
    end
  end

  describe "an object that hasn't loaded the associations" do
    before { book.save! }

    it "accesses associations" do
      f = Book.find(book.id)
      f.freeze
      expect(f.library_id).to_not be_nil
    end
  end

  describe "#translate_id_to_uri" do
    subject(:uri) { described_class.translate_id_to_uri }
    context "when it's not set" do
      it "is a FedoraIdTranslator" do
        expect(uri).to eq ActiveFedora::Core::FedoraIdTranslator
      end
    end
    context "when it's set to nil" do
      before do
        described_class.translate_id_to_uri = nil
      end
      it "is a FedoraIdTranslator" do
        expect(uri).to eq ActiveFedora::Core::FedoraIdTranslator
      end
    end
  end

  describe "#translate_uri_to_id" do
    subject(:uri) { described_class.translate_uri_to_id }
    context "when it's not set" do
      it "is a FedoraUriTranslator" do
        expect(uri).to eq ActiveFedora::Core::FedoraUriTranslator
      end
    end
    context "when it's set to nil" do
      before do
        described_class.translate_uri_to_id = nil
      end
      it "is a FedoraIdTranslator" do
        expect(uri).to eq ActiveFedora::Core::FedoraUriTranslator
      end
    end
  end

  describe "id_to_uri" do
    subject(:uri) { described_class.id_to_uri(id) }
    let(:id) { '123456w' }

    context "with no custom proc is set" do
      it { is_expected.to eq "#{ActiveFedora.fedora.base_uri}/123456w" }
      it "justs call #translate_id_to_uri" do
        allow(described_class).to receive(:translate_id_to_uri).and_call_original
        allow(ActiveFedora::Core::FedoraIdTranslator).to receive(:call).and_call_original

        uri

        expect(ActiveFedora::Core::FedoraIdTranslator).to have_received(:call).with(id)
      end
    end

    context "when custom proc is set" do
      before do
        described_class.translate_id_to_uri = lambda { |id| "#{ActiveFedora.fedora.base_uri}/foo/#{id}" }
      end
      after { described_class.translate_id_to_uri = nil }

      it { is_expected.to eq "#{ActiveFedora.fedora.base_uri}/foo/123456w" }
    end

    context "with an empty base path" do
      it "produces a valid URI" do
        allow(ActiveFedora.fedora).to receive(:base_path).and_return("/")
        expect(uri).to eq("#{ActiveFedora.fedora.host}/#{id}")
      end
    end

    context "with a really empty base path" do
      it "produces a valid URI" do
        allow(ActiveFedora.fedora).to receive(:base_path).and_return("")
        expect(uri).to eq("#{ActiveFedora.fedora.host}/#{id}")
      end
    end
  end

  describe "uri_to_id" do
    subject(:uri_id) { described_class.uri_to_id(uri) }
    let(:uri) { "#{ActiveFedora.fedora.base_uri}/foo/123456w" }

    context "with no custom proc is set" do
      it { is_expected.to eq 'foo/123456w' }
      it "justs call #translate_uri_to_id" do
        allow(described_class).to receive(:translate_uri_to_id).and_call_original
        allow(ActiveFedora::Core::FedoraUriTranslator).to receive(:call).and_call_original

        uri_id

        expect(ActiveFedora::Core::FedoraUriTranslator).to have_received(:call).with(uri)
      end
    end

    context "when custom proc is set" do
      before do
        described_class.translate_uri_to_id = lambda { |uri| uri.to_s.split('/')[-1] }
      end
      after { described_class.translate_uri_to_id = nil }

      it { is_expected.to eq '123456w' }
    end
  end

  describe "to_class_uri" do
    before do
      module SpecModel
        class CamelCased < ActiveFedora::Base
        end
      end
    end

    after do
      Object.send(:remove_const, :SpecModel)
    end
    subject do
      Deprecation.silence(ActiveFedora::Core::ClassMethods) do
        SpecModel::CamelCased.to_class_uri
      end
    end

    it { is_expected.to eq 'SpecModel::CamelCased' }
  end

  describe "to_rdf_representation" do
    before do
      module SpecModel
        class CamelCased < ActiveFedora::Base
        end
      end
    end

    after do
      Object.send(:remove_const, :SpecModel)
    end
    subject { SpecModel::CamelCased.to_rdf_representation }

    it { is_expected.to eq 'SpecModel::CamelCased' }
  end
end
