require 'spec_helper'

describe ActiveFedora::Base do
  describe "active model methods" do 
    class BarStream < ActiveFedora::OmDatastream 
      set_terminology do |t|
        t.root(:path=>"first", :xmlns=>"urn:foobar")
        t.duck()
      end

      def self.xml_template
            Nokogiri::XML::Document.parse '<first xmlns="urn:foobar"> 
              <duck></duck>
            </first>'
      end
    end

    class BarHistory < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText" do |m|
        m.field "fubar", :text
      end
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText2" do |m|
        m.field "fubar", :text
      end

      has_metadata :type=>BarStream, :name=>"xmlish"
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :fubar, datastream: 'withText', multiple: false
        has_attributes :duck, datastream: 'xmlish', multiple: false
      end
    end
    before :each do
      @n = BarHistory.new()
    end
    describe "attributes=" do
      it "should set attributes" do
        @n.attributes = {:fubar=>"baz", :duck=>"Quack"}
        expect(@n.fubar).to eq "baz"
        expect(@n.withText.get_values(:fubar).first).to eq 'baz'
        expect(@n.duck).to eq "Quack"
        expect(@n.xmlish.term_values(:duck).first).to eq 'Quack'
      end
    end
    describe "update_attributes" do
      it "should set attributes and save " do
        @n.update_attributes(:fubar=>"baz", :duck=>"Quack")
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

