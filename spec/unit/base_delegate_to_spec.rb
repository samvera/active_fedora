require 'spec_helper'

#TODO merge this with spec/unit/base_delegate_spec.rb
describe ActiveFedora::Base do

  describe "deletgating multiple terms to one datastream" do
    class BarnyardDocument < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(:path=>"animals", :xmlns=>"urn:zoobar")
        t.waterfowl do
          t.ducks do
            t.duck
          end
        end
        t.donkey()
        t.cow()
        t.horse()
        t.chicken()
        t.pig()
        t.duck(:ref=>[:waterfowl,:ducks,:duck])
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
              <horse></horse>
              <chicken></chicken>
              <pig></pig>
            </animals>'
      end
    end

    class Barnyard < ActiveFedora::Base
      has_metadata :type=>BarnyardDocument, :name=>"xmlish"
      has_attributes :cow, :chicken, :pig, :duck, datastream: 'xmlish', multiple: true
      has_attributes :donkey, :horse, datastream: 'xmlish', multiple: false
    end
    before :each do
      @n = Barnyard.new()
    end
    it "should save a delegated property uniquely" do
      @n.donkey="Bray"
      @n.donkey.should == "Bray"
      @n.xmlish.term_values(:donkey).first.should == 'Bray'
      @n.horse="Winee"
      @n.horse.should == "Winee"
      @n.xmlish.term_values(:horse).first.should == 'Winee'
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

    it "should be able to track change status" do
      @n.chicken_changed?.should be_false
      @n.chicken = ["Cheep"]
      @n.chicken_changed?.should be_true
    end 

  end
end


