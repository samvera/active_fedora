require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
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
                <cow></cow>
              </animals>'
        end
      end
  end
  after :all do
    Object.send(:remove_const, :BarStream2)
  end

  describe "first level delegation" do 
    before :all do
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
        has_attributes :cow, datastream: 'xmlish'                      # for testing the default value of multiple
        has_attributes :fubar, datastream: 'withText', multiple: true  # test alternate datastream
        has_attributes :pig, datastream: 'xmlish', multiple: false
        has_attributes :horse, datastream: 'xmlish', multiple: true
        has_attributes :duck, datastream: 'xmlish', :at=>[:waterfowl, :ducks, :duck], multiple: true
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory2)
    end

    subject { BarHistory2.new }

    describe "inspect" do
      it "should show the attributes" do
        expect(subject.inspect).to eq "#<BarHistory2 pid: nil, cow: \"\", fubar: [], pig: nil, horse: [], duck: [\"\"]>"
      end
      describe "with a pid" do
        before { subject.stub(pid: 'test:123') }
        it "should show a pid" do
          expect(subject.inspect).to eq "#<BarHistory2 pid: \"test:123\", cow: \"\", fubar: [], pig: nil, horse: [], duck: [\"\"]>"
        end
      end
      describe "with no attributes" do
        subject { ActiveFedora::Base.new }
        it "should show a pid" do
          expect(subject.inspect).to eq "#<ActiveFedora::Base pid: nil>"
        end
      end

      describe "with relationships" do
        before do
          class BarHistory3 < BarHistory2
            belongs_to :library, property: :has_constituent, class_name: 'BarHistory2'
          end
          subject.library = library
        end
        let (:library) { BarHistory2.create }
        subject {BarHistory3.new}
        after do 
          Object.send(:remove_const, :BarHistory3)
        end
        it "should show the library_id" do
          expect(subject.inspect).to eq "#<BarHistory3 pid: nil, cow: \"\", fubar: [], pig: nil, horse: [], duck: [\"\"], library_id: \"#{library.pid}\">"
        end
      end
    end



    it "should reveal the unique properties" do
      BarHistory2.unique?(:horse).should be_false
      BarHistory2.unique?(:pig).should be_true
      BarHistory2.unique?(:cow).should be_true
    end

    it "should save a delegated property uniquely" do
      subject.fubar="Quack"
      subject.fubar.should == ["Quack"]
      subject.withText.get_values(:fubar).first.should == 'Quack'
      subject.cow="Low"
      subject.cow.should == "Low"
      subject.xmlish.term_values(:cow).first.should == 'Low'

      subject.pig="Oink"
      subject.pig.should == "Oink"
    end

    it "should allow passing parameters to the delegate accessor" do
      subject.cow=["one", "two"]
      subject.cow(1).should == 'two'
    end

    it "should return a single value if not marked as multiple" do
      subject.cow=["one", "two"]
      subject.cow.should == "one"
    end

    it "should return an array if marked as multiple" do
      subject.horse=["neigh", "whinny"]
      subject.horse.should == ["neigh", "whinny"]
    end

    it "should be able to delegate deeply into the terminology" do
      subject.duck=["Quack", "Peep"]
      subject.duck.should == ["Quack", "Peep"]
    end

    it "should be able to track change status" do
      subject.fubar_changed?.should be_false
      subject.fubar = "Meow"
      subject.fubar_changed?.should be_true
    end

    describe "array getters and setters" do
      it "should accept symbol keys" do
        subject[:duck]= ["Cluck", "Gobble"]
        subject[:duck].should == ["Cluck", "Gobble"]
      end

      it "should accept string keys" do
        subject['duck']= ["Cluck", "Gobble"]
        subject['duck'].should == ["Cluck", "Gobble"]
      end

      it "should raise an error on the reader when the field isn't delegated" do
        expect {subject['goose'] }.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `goose'"
      end

      it "should raise an error on the setter when the field isn't delegated" do
        expect {subject['goose']="honk" }.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `goose'"
      end
    end

    describe "attributes=" do
      it "should raise an error on an invalid attribute" do
        expect {subject.attributes = {'goose'=>"honk" }}.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `goose'"
      end
    end

    describe "attributes" do
      let(:vals) { {'cow'=>["moo"], 'pig' => ['oink'], 'horse' =>['neigh'], "fubar"=>[], 'duck'=>['quack'] } }
      before { subject.attributes = vals }
      it "should return a hash" do
        expect(subject.attributes).to eq(vals.merge('id' => nil))
      end
    end

  end

  describe "with a superclass" do
    before :all do
      class BarHistory2 < ActiveFedora::Base
        has_metadata 'xmlish', :type=>BarStream2
        has_attributes :donkey, :cow, datastream: 'xmlish', multiple: true
      end
      class BarHistory3 < BarHistory2
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory3)
      Object.send(:remove_const, :BarHistory2)
    end

    subject { BarHistory3.new }

    it "should be able to delegate deeply into the terminology" do
      subject.donkey=["Bray", "Hee-haw"]
      subject.donkey.should == ["Bray", "Hee-haw"]
    end

    it "should be able to track change status" do
      subject.cow_changed?.should be_false
      subject.cow = ["Moo"]
      subject.cow_changed?.should be_true
    end 
  end

  describe "with a RDF datastream" do
    before :all do
      class BarRdfDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, :predicate => RDF::DC.title
        property :description, :predicate => RDF::DC.description, :multivalue => false
      end
      class BarHistory4 < ActiveFedora::Base
        has_metadata 'rdfish', :type=>BarRdfDatastream
        has_attributes :title, :description, datastream: 'rdfish', multiple: true
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
      Object.send(:remove_const, :BarRdfDatastream)
    end

    subject { BarHistory4.new }

    describe "with a multivalued field" do
      it "should be able to track change status" do
        subject.title_changed?.should be_false
        subject.title = ["Title1", "Title2"]
        subject.title_changed?.should be_true
      end
    end
    describe "with a single-valued field" do
      it "should be able to track change status" do
        subject.description_changed?.should be_false
        subject.description = "A brief description"
        subject.description_changed?.should be_true
      end
    end
  end 

  describe "without a datastream" do
    before :all do
      class BarHistory4 < ActiveFedora::Base
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
    end

    subject { BarHistory4}

    it "should raise an error" do
      expect {subject.has_attributes :title, :description, multiple: true}.to raise_error
    end
  end

  describe "when an unknown datastream is specified" do
    before :all do
      class BarHistory4 < ActiveFedora::Base
        has_attributes :description, datastream: 'rdfish', multiple: true
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
    end

    subject { BarHistory4.new }

    it "should raise an error on get" do
      expect {subject.description}.to raise_error(ArgumentError, "Undefined datastream id: `rdfish' in has_attributes")
    end

    it "should raise an error on set" do
      expect {subject.description = 'Neat'}.to raise_error(ArgumentError, "Undefined datastream id: `rdfish' in has_attributes")
    end
  end

  describe "when a datastream is specified as a symbol" do
    before :all do
      class BarRdfDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, :predicate => RDF::DC.title
        property :description, :predicate => RDF::DC.description
      end
      class BarHistory4 < ActiveFedora::Base
        has_metadata 'rdfish', :type=>BarRdfDatastream
        has_attributes :description, datastream: :rdfish
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
      Object.send(:remove_const, :BarRdfDatastream)
    end

    subject { BarHistory4.new(description: 'test1') }

    it "should be able to access the attributes" do
      expect(subject.description).to eq 'test1'
    end
  end
end


