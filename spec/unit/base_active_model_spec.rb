require File.join( File.dirname(__FILE__), "../spec_helper" )

describe ActiveFedora::Base do

  describe "active model methods" do 
    class BarStream < ActiveFedora::NokogiriDatastream 
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
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText" do |m|
        m.field "fubar", :text
      end
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText2", :label=>"withLabel" do |m|
        m.field "fubar", :text
      end 

      has_metadata :type=>BarStream, :name=>"xmlish"
      delegate :fubar, :to=>'withText'
      delegate :duck, :to=>'xmlish'
    end
    before :each do
      @n = BarHistory.new(:pid=>"monkey:99")
    end
    describe "attributes=" do
      it "should set attributes" do
        @n.attributes = {:fubar=>"baz", :duck=>"Quack"}
        @n.fubar.should == "baz"
        @n.withText.get_values(:fubar).first.should == 'baz'
        @n.duck.should == "Quack"
        @n.xmlish.term_values(:duck).first.should == 'Quack'
      end
    end
    describe "update_attributes" do
      it "should set attributes and save " do
        pending
        @n.update_attributes(:fubar=>"baz", :duck=>"Quack")
        @q = BarHistory.find('monkey:99')
        @q.fubar.should == "baz"
        @q.duck.should == "Quack"
      end
      after do
        @n.delete
      end
    end

  end
end

