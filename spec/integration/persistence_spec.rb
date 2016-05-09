require 'spec_helper'

describe "persisting objects" do
  describe "#create!" do
    before do
      class MockAFBaseRelationship < ActiveFedora::Base
        property :name, predicate: ::RDF::Vocab::DC.title, multiple: false
        validates :name, presence: true
      end
    end

    after do
      Object.send(:remove_const, :MockAFBaseRelationship)
    end

    it "validates" do
      expect { MockAFBaseRelationship.create! }.to raise_error ActiveFedora::RecordInvalid, "Validation failed: Name can't be blank"
    end
  end

  describe "#save" do
    context "With undefined contains associations" do
      let(:f1) { ActiveFedora::Base.create }
      let!(:f2) { ActiveFedora::Base.create(id: "#{f1.id}/part2") }

      before do
        f1.reload # so it learns about f2
      end

      it "doesn't load the children" do
        allow(f1).to receive(:update_index) # solrizing can load the attached files.
        expect(ActiveFedora::File).not_to receive(:new)
        f1.save
      end
    end
  end
end
