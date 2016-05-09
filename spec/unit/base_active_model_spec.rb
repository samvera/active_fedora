require 'spec_helper'

describe ActiveFedora::Base do
  describe "active model methods" do
    class BarHistory < ActiveFedora::Base
      property :fubar, predicate: ::RDF::URI('http://example.com/fubar'), multiple: false
      property :duck, predicate: ::RDF::URI('http://example.com/duck'), multiple: false
    end
    subject { BarHistory.new }

    describe "attributes=" do
      it "sets attributes" do
        subject.attributes = { fubar: "baz", duck: "Quack" }
        expect(subject.fubar).to eq "baz"
        expect(subject.duck).to eq "Quack"
      end
    end

    describe "update_attributes" do
      it "sets attributes and save" do
        subject.update_attributes(fubar: "baz", duck: "Quack")
        subject.reload
        expect(subject.fubar).to eq "baz"
        expect(subject.duck).to eq "Quack"
      end
    end
  end
end
