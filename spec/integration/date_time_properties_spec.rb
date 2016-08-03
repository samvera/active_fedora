require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Foo < ActiveFedora::Base
      # Date attributes are recognized by having index.type :Date or class_name: 'DateTime'
      property :date, predicate: ::RDF::Vocab::DC.date do |index|
        index.type :date
      end
      property :integer, predicate: ::RDF::URI.new('http://www.example.com/integer'), multiple: false do |index|
        index.type :integer
      end
      property :single_date, multiple: false, class_name: 'DateTime', predicate: ::RDF::URI.new('http://www.example.com/single_date')
      property :missing_date, multiple: false, class_name: 'DateTime', predicate: ::RDF::URI.new('http://www.example.com/missing_date')
      property :empty_date, multiple: false, class_name: 'DateTime', predicate: ::RDF::URI.new('http://www.example.com/empty_date')
    end
  end

  after do
    Object.send(:remove_const, :Foo)
  end

  let(:date) { DateTime.parse("2015-10-22T10:20:03.653+01:00") }
  let(:date2) { DateTime.parse("2015-10-22T15:34:20.323-11:00") }

  describe "saving and loading in Fedora" do
    let(:object) { Foo.create!(date: [date], single_date: date2, empty_date: '', integer: 1).reload }
    it "loads the correct time" do
      expect(object.date.first).to eql date
      expect(object.single_date).to eql date2
    end
  end

  describe 'serializing' do
    let(:object) { Foo.new(date: [date]) }
    let(:triple) { object.resource.query(predicate: ::RDF::Vocab::DC.date).to_a.first }
    it 'time zone must have semicolin to be a cannonical XMLSchema#dateTime' do
      expect(triple.to_s).to match(/\+01:00/)
    end
  end
end
