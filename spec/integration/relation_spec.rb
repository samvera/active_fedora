require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class Library < ActiveFedora::Base 
      has_many :books, property: :has_member
    end
    class Book < ActiveFedora::Base; end
  end
  after :all do
    Library.delete_all
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end

  subject {Library.all} 
  its(:class) {should eq ActiveFedora::Relation }

  describe "#find" do
    before do
      Library.create
      @library = Library.create
    end
    it "should find one of them" do
      expect(subject.find(@library.id)).to eq @library
    end
    it "should find with a block" do
      expect(subject.find { |l| l.id == @library.id}).to eq @library
    end
  end

  describe "#select" do
    before do
      Library.create
      @library = Library.create
    end
    it "should find with a block" do
      expect(subject.select { |l| l.id == @library.id}).to eq [@library]
    end
  end
end

