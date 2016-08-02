require 'spec_helper'

describe ActiveFedora::Base do
  describe "active model methods" do
    class BarHistory < ActiveFedora::Base
      property :fubar, predicate: ::RDF::URI('http://example.com/fubar'), multiple: false
      property :duck, predicate: ::RDF::URI('http://example.com/duck'), multiple: false
    end
    subject(:history) { BarHistory.new }

    describe "attributes=" do
      it "sets attributes" do
        history.attributes = { fubar: "baz", duck: "Quack" }
        expect(history.fubar).to eq "baz"
        expect(history.duck).to eq "Quack"
      end
    end

    describe "update_attributes" do
      it "sets attributes and save" do
        history.update_attributes(fubar: "baz", duck: "Quack")
        history.reload
        expect(history.fubar).to eq "baz"
        expect(history.duck).to eq "Quack"
      end
    end
  end
end
