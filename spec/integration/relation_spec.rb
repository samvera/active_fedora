require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class Library < ActiveFedora::Base
      has_many :books, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end
    class Book < ActiveFedora::Base; end
  end
  after :all do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end

  subject { Library.all }

  it "should be a relation" do
    expect(subject.class).to be ActiveFedora::Relation
  end

  before :each do
    Library.create
    @library = Library.create
  end

  let(:library1) { @library }

  describe "is cached" do
    before do
      subject.to_a # trigger initial load
    end

    it "should be loaded" do
      expect(subject).to be_loaded
    end
    it "shouldn't reload" do
      expect_any_instance_of(ActiveFedora::Relation).to_not receive :find_each
      subject[0]
    end
  end

  describe "#find" do
    it "should find one of them" do
      expect(subject.find(library1.id)).to eq library1
    end
    it "should find with a block" do
      expect(subject.find { |l| l.id == library1.id}).to eq library1
    end
  end

  describe "#select" do
    it "should find with a block" do
      expect(subject.select { |l| l.id == library1.id}).to eq [library1]
    end
  end
end

