require 'spec_helper'

describe "rdf associations" do
  context "when there is one relationship for the predicate" do
    before do
      class Foo < ActiveFedora::Base
      end
      class Library < ActiveFedora::Base
        has_and_belongs_to_many :foos, predicate: ::RDF::URI('http://example.com')
      end
    end
    after do
      Object.send(:remove_const, :Foo)
      Object.send(:remove_const, :Library)
    end

    let(:library) { Library.new }

    it "doesn't not bother to filter by class type" do
      expect(library.association(:foo_ids)).not_to receive(:filter_by_class)
      library.foos.to_a
    end

    describe "the id setter" do
      it "can handle nil" do
        library.foo_ids = nil
        expect(library.foo_ids).to eq []
      end

      it "can handle array with nils" do
        library.foo_ids = [nil, nil]
        expect(library.foo_ids).to eq []
      end
    end
  end

  context "when two relationships have the same predicate" do
    before do
      class Foo < ActiveFedora::Base
      end
      class Bar < ActiveFedora::Base
      end
      class Library < ActiveFedora::Base
        has_and_belongs_to_many :foos, predicate: ::RDF::URI('http://example.com')
        has_and_belongs_to_many :bars, predicate: ::RDF::URI('http://example.com')
      end
    end
    after do
      Object.send(:remove_const, :Foo)
      Object.send(:remove_const, :Bar)
      Object.send(:remove_const, :Library)
    end

    let(:library) { Library.new }

    it "filters by class type" do
      expect(library.association(:foo_ids)).to receive(:filter_by_class).and_call_original
      library.foos.to_a
    end
  end
end
