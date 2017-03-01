require 'spec_helper'

describe ActiveFedora::Base do
  describe ".uri_prefix" do
    before do
      class FooHistory < ActiveFedora::Base
        def uri_prefix
          "foo"
        end
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end

    after do
      Object.send(:remove_const, :FooHistory)
    end

    subject(:history) { FooHistory.new(title: ["Root foo"]) }
    let(:path) { "foo" }

    it { is_expected.to have_uri_prefix }

    it "uses the root path in the uri" do
      expect(history.uri_prefix).to eql path
    end

    context "when the object is saved" do
      before { history.save }

      it "persists the path in the uri" do
        expect(history.uri.to_s).to include(path)
      end
    end
  end
end
