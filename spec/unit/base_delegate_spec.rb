require File.join( File.dirname(__FILE__), "../spec_helper" )

describe ActiveFedora::Base do

  describe "first level delegation" do 
    class BarStream < ActiveFedora::NokogiriDatastream 
      set_terminology do |t|
        t.root(:path=>"first", :xmlns=>"urn:foobar")
        t.duck()
        t.cow()
      end

      def self.xml_template
            Nokogiri::XML::Document.parse '<first xmlns="urn:foobar"> 
              <duck></duck>
              <cow></cow>
            </first>'
      end
    end

    class BarHistory < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "bandana", :string
        m.field "swank", :text
      end
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText" do |m|
        m.field "fubar", :text
      end
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText2", :label=>"withLabel" do |m|
        m.field "fubar", :text
      end 

      has_metadata :type=>BarStream, :name=>"xmlish"
      delegate :fubar, :to=>'withText', :unique=>true
      delegate :duck, :to=>'xmlish', :unique=>true
      delegate :cow, :to=>'xmlish'
    end
    before :each do
      @n = BarHistory.new(:pid=>"monkey:99")
    end
    it "should save a delegated property uniquely" do
      @n.fubar="Quack"
      @n.fubar.should == "Quack"
      @n.withText.get_values(:fubar).first.should == 'Quack'
      @n.duck="Quack"
      @n.duck.should == "Quack"
      @n.xmlish.term_values(:duck).first.should == 'Quack'
    end
    it "should return an array if not marked as unique" do
      ### Metadata datastream does not appear to support multiple value setting
      @n.cow=["one", "two"]
      @n.cow.should == ["one", "two"]
    end

  end
end


