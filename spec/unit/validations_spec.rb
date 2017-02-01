require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class ValidationStub < ActiveFedora::Base
      property :fubar, predicate: ::RDF::URI('http://example.com/fubar')
      property :swank, predicate: ::RDF::URI('http://example.com/swank'), multiple: false

      validates_presence_of :fubar
      validates_length_of :swank, minimum: 5
    end
  end

  subject(:validation_stub) { ValidationStub.new }

  after :all do
    Object.send(:remove_const, :ValidationStub)
  end

  describe "a valid object" do
    before do
      validation_stub.attributes = { fubar: ['here'], swank: 'long enough' }
    end

    it { is_expected.to be_valid }
  end
  describe "an invalid object" do
    before do
      validation_stub.attributes = { swank: 'smal' }
    end
    it "has errors" do
      expect(validation_stub).to_not be_valid
      expect(validation_stub.errors[:fubar]).to eq ["can't be blank"]
      expect(validation_stub.errors[:swank]).to eq ["is too short (minimum is 5 characters)"]
    end
  end

  describe "required terms" do
    it { is_expected.to be_required(:fubar) }
    it { is_expected.to_not be_required(:swank) }
  end

  describe "#save!" do
    before { expect(validation_stub).to receive(:_create_record) } # prevent saving to Fedora/Solr

    it "validates only once" do
      expect(validation_stub).to receive(:perform_validations).once.and_return(true)
      validation_stub.save!
    end
  end

  describe "#update!" do
    before do
      allow(validation_stub).to receive(:new_record?).and_return(false)
    end
    context "when validations work" do
      it "saves the record" do
        expect(validation_stub).to receive(:_update_record) # prevent saving to Fedora/Solr
        expect(validation_stub).to receive(:perform_validations).once.and_return(true)
        validation_stub.update!(fubar: ['here'], swank: 'long enough')
        expect(validation_stub.fubar).to eq ['here']
      end
    end

    context "when validations fail" do
      it "raises an error" do
        expect(validation_stub).not_to receive(:_update_record)
        expect(validation_stub).to receive(:perform_validations).once.and_return(false)
        expect { validation_stub.update!(fubar: ['here'], swank: 'long enough') }.to raise_error ActiveFedora::RecordInvalid
        expect(validation_stub.fubar).to eq ['here']
      end
    end
  end
end
