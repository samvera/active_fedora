require 'spec_helper'

describe ActiveFedora::Base do
  describe "active model methods" do
    class BarStream < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path: "first", xmlns: "urn:foobar")
        t.duck
      end

      def self.xml_template
        Nokogiri::XML::Document.parse '<first xmlns="urn:foobar">
          <duck></duck>
        </first>'
      end
    end

    class BazStream < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path: "first", xmlns: "urn:foobar")
        t.fubar
      end

      def self.xml_template
        Nokogiri::XML::Document.parse '<first xmlns="urn:foobar">
          <fubar></fubar>
        </first>'
      end
    end

    class BarHistory < ActiveFedora::Base
      has_subresource 'xmlish', class_name: 'BarStream'
      has_subresource 'withText', class_name: 'BazStream'
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :fubar, datastream: 'withText', multiple: false
        has_attributes :duck, datastream: 'xmlish', multiple: false
      end
    end
    before :each do
      @n = BarHistory.new
    end
    describe "attributes=" do
      it "sets attributes" do
        @n.attributes = { fubar: "baz", duck: "Quack" }
        expect(@n.fubar).to eq "baz"
        expect(@n.withText.get_values(:fubar).first).to eq 'baz'
        expect(@n.duck).to eq "Quack"
        expect(@n.xmlish.term_values(:duck).first).to eq 'Quack'
      end
    end
    describe "update_attributes" do
      it "sets attributes and save" do
        @n.update_attributes(fubar: "baz", duck: "Quack")
        @q = BarHistory.find(@n.id)
        expect(@q.fubar).to eq "baz"
        expect(@q.duck).to eq "Quack"
      end
      after do
        @n.delete
      end
    end
  end
end
