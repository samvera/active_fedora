require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
      class BarStream2 < ActiveFedora::OmDatastream
        set_terminology do |t|
          t.root(:path => 'animals', :xmlns => 'urn:zoobar')
          t.waterfowl do
            t.ducks do
              t.duck
            end
          end
          t.donkey()
          t.cow()
          t.pig()
          t.horse()
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
  end
  after :all do
    Object.send(:remove_const, :BarStream2)
  end

  describe 'first level delegation' do
    before :all do
      class BarHistory2 < ActiveFedora::Base
        has_metadata :type => ActiveFedora::SimpleDatastream, :name => 'someData' do |m|
          m.field 'fubar', :string
          m.field 'bandana', :string
          m.field 'swank', :text
        end
        has_metadata :type => ActiveFedora::SimpleDatastream, :name => 'withText' do |m|
          m.field 'fubar', :text
        end
        has_metadata :type => ActiveFedora::SimpleDatastream, :name => 'withText2', :label => 'withLabel' do |m|
          m.field 'fubar', :text
        end

        has_metadata :type => BarStream2, :name => 'xmlish'
        delegate :fubar, :to => 'withText', :unique => true
        delegate :donkey, :to => 'xmlish', :unique => true
        delegate :cow, :to => 'xmlish'  # for testing the default value of multiple
        delegate :pig, :to => 'xmlish', multiple: false
        delegate :horse, :to => 'xmlish', multiple: true
        delegate :duck, :to => 'xmlish', :at => [:waterfowl, :ducks], multiple: true
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory2)
    end

    subject { BarHistory2.new() }

    it 'should reveal the unique properties' do
      expect(BarHistory2.unique?(:fubar)).to be_truthy
      expect(BarHistory2.unique?(:cow)).to be_falsey
    end

    it 'should save a delegated property uniquely' do
      subject.fubar = 'Quack'
      expect(subject.fubar).to eq('Quack')
      expect(subject.withText.get_values(:fubar).first).to eq('Quack')
      subject.donkey = 'Bray'
      expect(subject.donkey).to eq('Bray')
      expect(subject.xmlish.term_values(:donkey).first).to eq('Bray')

      subject.pig = 'Oink'
      expect(subject.pig).to eq('Oink')
    end

    it 'should allow passing parameters to the delegate accessor' do
      subject.cow = ['one', 'two']
      expect(subject.cow(1)).to eq(['two'])
    end


    it 'should return an array if not marked as unique' do
      ### Metadata datastream does not appear to support multiple value setting
      subject.cow = ['one', 'two']
      expect(subject.cow).to eq(['one', 'two'])

      subject.horse = ['neigh', 'whinny']
      expect(subject.horse).to eq(['neigh', 'whinny'])
    end

    it 'should be able to delegate deeply into the terminology' do
      subject.duck = ['Quack', 'Peep']
      expect(subject.duck).to eq(['Quack', 'Peep'])
    end

    it 'should be able to track change status' do
      expect(subject.fubar_changed?).to be_falsey
      subject.fubar = 'Meow'
      expect(subject.fubar_changed?).to be_truthy
    end

    describe 'array getters and setters' do
      it 'should accept symbol keys' do
        subject[:duck] = ['Cluck', 'Gobble']
        expect(subject[:duck]).to eq(['Cluck', 'Gobble'])
      end

      it 'should accept string keys' do
        subject['duck'] = ['Cluck', 'Gobble']
        expect(subject['duck']).to eq(['Cluck', 'Gobble'])
      end

      it "should raise an error on the reader when the field isn't delegated" do
        expect {subject['goose'] }.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `goose'"
      end

      it "should raise an error on the setter when the field isn't delegated" do
        expect {subject['goose'] = 'honk' }.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `goose'"
      end
    end

  end

  describe 'with a superclass' do
    before :all do
      class BarHistory2 < ActiveFedora::Base
        has_metadata 'xmlish', :type => BarStream2
        delegate_to 'xmlish', [:donkey, :cow], multiple: true
      end
      class BarHistory3 < BarHistory2
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory3)
      Object.send(:remove_const, :BarHistory2)
    end

    subject { BarHistory3.new }

    it 'should be able to delegate deeply into the terminology' do
      subject.donkey = ['Bray', 'Hee-haw']
      expect(subject.donkey).to eq(['Bray', 'Hee-haw'])
    end

    it 'should be able to track change status' do
      expect(subject.cow_changed?).to be_falsey
      subject.cow = ['Moo']
      expect(subject.cow_changed?).to be_truthy
    end
  end

  describe 'with a RDF datastream' do
    before :all do
      class BarRdfDatastream < ActiveFedora::NtriplesRDFDatastream
        map_predicates do |map|
          map.title(in: RDF::DC)
          map.description(in: RDF::DC, multivalue: false)
        end
      end
      class BarHistory4 < ActiveFedora::Base
        has_metadata 'rdfish', :type => BarRdfDatastream
        delegate_to 'rdfish', [:title, :description], multiple: true
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
      Object.send(:remove_const, :BarRdfDatastream)
    end

    subject { BarHistory4.new }

    describe 'with a multivalued field' do
      it 'should be able to track change status' do
        expect(subject.title_changed?).to be_falsey
        subject.title = ['Title1', 'Title2']
        expect(subject.title_changed?).to be_truthy
      end
    end
    describe 'with a single-valued field' do
      it 'should be able to track change status' do
        expect(subject.description_changed?).to be_falsey
        subject.description = 'A brief description'
        expect(subject.description_changed?).to be_truthy
      end
    end
  end
end
