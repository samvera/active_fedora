require 'spec_helper'

describe ActiveFedora::Base do

  describe "first level delegation" do 
    class BarStream2 < ActiveFedora::OmDatastream 
      set_terminology do |t|
        t.root(:path=>"animals", :xmlns=>"urn:zoobar")
        t.waterfowl do
          t.ducks do 
            t.duck
          end
        end
        t.donkey()
        t.cow()
      end

      def self.xml_template
            Nokogiri::XML::Document.parse '<animals xmlns="urn:zoobar"> 
              <waterfowl>
                <ducks>
                  <duck/>
                </ducks>
              </waterfowl>
              <donkey></donkey>
              <cow></cow>
            </animals>'
      end
    end

    class BarHistory2 < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "bandana", :string
        m.field "swank", :text
      end
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText" do |m|
        m.field "fubar", :text
      end
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText2", :label=>"withLabel" do |m|
        m.field "fubar", :text
      end 

      has_metadata :type=>BarStream2, :name=>"xmlish"
      delegate :fubar, :to=>'withText', :unique=>true
      delegate :donkey, :to=>'xmlish', :unique=>true
      delegate :cow, :to=>'xmlish'
      delegate :duck, :to=>'xmlish', :at=>[:waterfowl, :ducks]
    end
    before :each do
      @n = BarHistory2.new()
    end

    it "should save a delegated property uniquely" do
      @n.fubar="Quack"
      @n.fubar.should == "Quack"
      @n.withText.get_values(:fubar).first.should == 'Quack'
      @n.donkey="Bray"
      @n.donkey.should == "Bray"
      @n.xmlish.term_values(:donkey).first.should == 'Bray'
    end
    it "should return an array if not marked as unique" do
      ### Metadata datastream does not appear to support multiple value setting
      @n.cow=["one", "two"]
      @n.cow.should == ["one", "two"]
    end

    it "should be able to delegate deeply into the terminology" do
      @n.duck=["Quack", "Peep"]
      @n.duck.should == ["Quack", "Peep"]
    end

    it "should accept the array getters and setters" do
      @n[:duck]= ["Cluck", "Gobble"]
      @n[:duck].should == ["Cluck", "Gobble"]
    end
  end
end


