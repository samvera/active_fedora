require 'spec_helper'

describe ActiveFedora::Base do
  describe ".uri_prefix" do
    let(:path) { "foo" }

    before do
      class FooHistory < ActiveFedora::Base
        def uri_prefix
          "foo"
        end
        property :title, predicate: ::RDF::DC.title
      end
    end

    after do
      Object.send(:remove_const, :FooHistory)
    end

    subject { FooHistory.new(title: ["Root foo"]) }

    it { is_expected.to have_uri_prefix }

    it "uses the root path in the uri" do
      expect(subject.uri_prefix).to eql path
    end

    context "when the object is saved" do
      before { subject.save }

      it "should persist the path in the uri" do
        expect(subject.uri.to_s).to include(path)
      end

    end
  end
end
