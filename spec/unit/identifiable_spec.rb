require 'spec_helper'

describe ActiveFedora::Identifiable do
  context "when translate_id_to_uri is set a subclass " do
    before do
      class SubClass < ActiveFedora::Base; end
      SubClass.translate_id_to_uri = double
    end

    after { Object.send(:remove_const, :SubClass) }

    it "is should not be changed in the base class" do
      expect(ActiveFedora::Core::FedoraIdTranslator).to receive(:call).with('1234')
      ActiveFedora::Base.id_to_uri('1234')
    end
  end

  describe "#translate_id_to_uri" do
    subject { ActiveFedora::Base.translate_id_to_uri }
    context "when it's not set" do
      it "should be a FedoraIdTranslator" do
        expect(subject).to eq ActiveFedora::Core::FedoraIdTranslator
      end
    end
  end

  describe "#translate_uri_to_id" do
    subject { ActiveFedora::Base.translate_uri_to_id }
    context "when it's not set" do
      it "should be a FedoraUriTranslator" do
        expect(subject).to eq ActiveFedora::Core::FedoraUriTranslator
      end
    end
  end

  describe "id_to_uri" do
    let(:id) { '123456w' }
    subject { ActiveFedora::Base.id_to_uri(id) }

    context "with no custom proc is set" do
      it { should eq "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/123456w" }
      it "should just call #translate_id_to_uri" do
        allow(ActiveFedora::Base).to receive(:translate_id_to_uri).and_call_original
        allow(ActiveFedora::Core::FedoraIdTranslator).to receive(:call).and_call_original

        subject

        expect(ActiveFedora::Core::FedoraIdTranslator).to have_received(:call).with(id)
      end
    end

    context "when custom proc is set" do
      before do
        ActiveFedora::Base.translate_id_to_uri = lambda { |id| "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/foo/#{id}" }
      end
      after { ActiveFedora::Base.translate_id_to_uri = ActiveFedora::Core::FedoraIdTranslator }

      it { should eq "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/foo/123456w" }
    end

    context "with an empty base path" do
      it "should produce a valid URI" do
        allow(ActiveFedora.fedora).to receive(:base_path).and_return("/")
        expect(subject).to eq("#{ActiveFedora.fedora.host}/#{id}")
      end
    end

    context "with a really empty base path" do
      it "should produce a valid URI" do
        allow(ActiveFedora.fedora).to receive(:base_path).and_return("")
        expect(subject).to eq("#{ActiveFedora.fedora.host}/#{id}")
      end
    end
  end

  describe "uri_to_id" do
    let(:uri) { "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/foo/123456w" }
    subject { ActiveFedora::Base.uri_to_id(uri) }

    context "with no custom proc is set" do
      it { should eq 'foo/123456w' }
      it "should just call #translate_uri_to_id" do
        allow(ActiveFedora::Base).to receive(:translate_uri_to_id).and_call_original
        allow(ActiveFedora::Core::FedoraUriTranslator).to receive(:call).and_call_original

        subject

        expect(ActiveFedora::Core::FedoraUriTranslator).to have_received(:call).with(uri)
      end
    end

    context "when custom proc is set" do
      before do
        ActiveFedora::Base.translate_uri_to_id = lambda { |uri| uri.to_s.split('/')[-1] }
      end
      after { ActiveFedora::Base.translate_uri_to_id = ActiveFedora::Core::FedoraUriTranslator }

      it { should eq '123456w' }
    end
  end

end
