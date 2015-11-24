require 'spec_helper'

describe ActiveFedora::Base do
  describe ".property" do
    context "when the same predicate is used for two properties" do
      let(:warningMsg) { "Same predicate (http://purl.org/dc/terms/title) used for properties title1 and title2" }

      it "warns" do
        # Note that the expect test must be before the class is parsed.
        expect(described_class.logger).to receive(:warn).with(warningMsg)

        module TestModel1
          class Book < ActiveFedora::Base
            property :title1, predicate: ::RDF::Vocab::DC.title
            property :title2, predicate: ::RDF::Vocab::DC.title
          end
        end
      end
    end

    context "when properties are created with different predicates" do
      it "does not warn" do
        # Note that the expect test must be before the class is parsed.
        expect(described_class.logger).to_not receive(:warn)

        module TestModel2
          class Book < ActiveFedora::Base
            property :title1, predicate: ::RDF::Vocab::DC.title
            property :title2, predicate: ::RDF::Vocab::DC.creator
          end
        end
      end
    end
  end
end
