require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Foo < ActiveFedora::Base
      # Date attributes are recognized by having index.type :Date or class_name: 'DateTime'
      property :date, predicate: ::RDF::Vocab::DC.date do |index|
        index.type :date
      end
      property :single_date, multiple: false, class_name: 'DateTime', predicate: ::RDF::URI.new('http://www.example.com/single_date')
      property :missing_date, multiple: false, class_name: 'DateTime', predicate: ::RDF::URI.new('http://www.example.com/missing_date')
    end
  end

  after do
    Object.send(:remove_const, :Foo)
  end

  let(:date) { DateTime.parse("2015-10-22T10:20:03.653+01:00") }
  let(:date2) { DateTime.parse("2015-10-22T15:34:20.323-11:00") }
  subject { Foo.create(date: [date], single_date: date2).reload }

  describe "saving and loading in Fedora" do
    it "loads the correct time" do
      expect(subject.date.first).to eql date
      expect(subject.single_date).to eql date2
    end
  end

  describe "saving and loading in Solr" do
    let(:subject_solr) { subject.class.load_instance_from_solr(subject.id) }
    it "uses DateTime objects" do
      expect(subject_solr.date.first).to be_a DateTime
      expect(subject_solr.single_date).to be_a DateTime
    end
    it "loads the correct time" do
      expect(subject_solr.date.first).to eql date
      expect(subject_solr.single_date).to eql date2
    end
  end
end
