require 'spec_helper'

describe ActiveFedora::Base do

  describe 'deletgating multiple terms to one datastream' do
    class BarnyardDocument < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(:path => 'animals', :xmlns => 'urn:zoobar')
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
        t.duck(:ref => [:waterfowl, :ducks, :duck])
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
      has_metadata :type => BarnyardDocument, :name => 'xmlish'
      delegate_to :xmlish, [:cow, :chicken, :pig, :duck], multiple: true
      delegate_to :xmlish, [:donkey, :horse], :unique => true
      # delegate :donkey, :to=>'xmlish', :unique=>true
    end
    before :each do
      @n = Barnyard.new()
    end
    it 'should save a delegated property uniquely' do
      @n.donkey = 'Bray'
      expect(@n.donkey).to eq('Bray')
      expect(@n.xmlish.term_values(:donkey).first).to eq('Bray')
      @n.horse = 'Winee'
      expect(@n.horse).to eq('Winee')
      expect(@n.xmlish.term_values(:horse).first).to eq('Winee')
    end
    it 'should return an array if not marked as unique' do
      # Metadata datastream does not appear to support multiple value setting
      @n.cow = ['one', 'two']
      expect(@n.cow).to eq(['one', 'two'])
    end

    it 'should be able to delegate deeply into the terminology' do
      @n.duck = ['Quack', 'Peep']
      expect(@n.duck).to eq(['Quack', 'Peep'])
    end

    it 'should be able to track change status' do
      expect(@n.chicken_changed?).to be_falsey
      @n.chicken = ['Cheep']
      expect(@n.chicken_changed?).to be_truthy
    end

  end
end
