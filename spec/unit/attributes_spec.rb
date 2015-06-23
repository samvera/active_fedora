require 'spec_helper'

describe ActiveFedora::Base do
  context "with an om datastream" do
    before :all do
        class BarStream2 < ActiveFedora::OmDatastream
          set_terminology do |t|
            t.root(path: "animals", xmlns: "urn:zoobar")
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

    describe "#property" do
      context "with an xml property (default cardinality)" do
        before do
          class BarHistory4 < ActiveFedora::Base
            has_metadata type: BarStream2, name: "xmlish"
            property :cow, delegate_to: 'xmlish'
          end
        end
        after do
          Object.send(:remove_const, :BarHistory4)
        end

        let(:obj) { BarHistory4.new }

        before { obj.cow = ['one', 'two'] }
        describe "the object accessor" do
          subject { obj.cow }
          it { is_expected.to eq ['one', 'two'] }
        end

        describe "the datastream accessor" do
          subject { obj.xmlish.cow }
          it { is_expected.to eq ['one', 'two'] }
        end
      end

      context "with multiple set to false" do
        before do
          class BarHistory4 < ActiveFedora::Base
            has_metadata type: BarStream2, name: "xmlish"
            property :cow, delegate_to: 'xmlish', multiple: false
          end
        end
        after do
          Object.send(:remove_const, :BarHistory4)
        end

        let(:obj) { BarHistory4.new }

        before { obj.cow = 'one' }
        describe "the object accessor" do
          subject { obj.cow }
          it { is_expected.to eq 'one' }
        end

      end
    end

    describe "first level delegation" do
      before :all do
        class BarHistory2 < ActiveFedora::Base
          has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
            m.field "fubar", :string
            m.field "bandana", :string
            m.field "swank", :text
            m.field "animal_id", :string
          end
          has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText" do |m|
            m.field "fubar", :text
          end
          has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText2" do |m|
            m.field "fubar", :text
          end

          has_metadata :type=>BarStream2, :name=>"xmlish"
          Deprecation.silence(ActiveFedora::Attributes) do
            has_attributes :cow, datastream: 'xmlish'                      # for testing the default value of multiple
            has_attributes :fubar, datastream: 'withText', multiple: true  # test alternate datastream
            has_attributes :pig, datastream: 'xmlish', multiple: false
            has_attributes :horse, datastream: 'xmlish', multiple: true
            has_attributes :duck, datastream: 'xmlish', :at=>[:waterfowl, :ducks, :duck], multiple: true
            has_attributes :animal_id, datastream: 'someData', multiple: false
          end

          property :goose, predicate: ::RDF::URI.new('http://example.com#hasGoose')

        end
      end

      after :all do
        Object.send(:remove_const, :BarHistory2)
      end

      subject { BarHistory2.new }

      describe "#attribute_names" do
        context "on an instance" do
          it "should list the attributes" do
            expect(subject.attribute_names).to eq ["cow", "fubar", "pig", "horse", "duck", "animal_id", "goose"]
          end
        end

        context "on a class" do
          it "should list the attributes" do
            expect(BarHistory2.attribute_names).to eq ["cow", "fubar", "pig", "horse", "duck", "animal_id", "goose"]
          end
        end
      end

      describe "inspect" do
        it "should show the attributes" do
          expect(subject.inspect).to eq "#<BarHistory2 id: nil, cow: \"\", fubar: [], pig: nil, horse: [], duck: [\"\"], animal_id: nil, goose: []>"
        end

        describe "with a id" do
          before { allow(subject).to receive(:id).and_return('test:123') }

          it "should show a id" do
            expect(subject.inspect).to eq "#<BarHistory2 id: \"test:123\", cow: \"\", fubar: [], pig: nil, horse: [], duck: [\"\"], animal_id: nil, goose: []>"
          end
        end

        describe "with no attributes" do
          subject { ActiveFedora::Base.new }
          it "should show a id" do
            expect(subject.inspect).to eq "#<ActiveFedora::Base id: nil>"
          end
        end

        describe "with relationships" do
          before do
            class BarHistory3 < BarHistory2
              belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent, class_name: 'BarHistory2'
            end
            subject.library = library
          end

          let (:library) { BarHistory2.create }
          subject { BarHistory3.new }

          after do
            Object.send(:remove_const, :BarHistory3)
          end

          it "should show the library_id" do
            expect(subject.inspect).to eq "#<BarHistory3 id: nil, cow: \"\", fubar: [], pig: nil, horse: [], duck: [\"\"], animal_id: nil, goose: [], library_id: \"#{library.id}\">"
          end
        end
      end

      it "should reveal the unique properties" do
        expect(BarHistory2.unique?(:horse)).to be false
        expect(BarHistory2.unique?(:pig)).to be true
        expect(BarHistory2.unique?(:cow)).to be true
      end

      it "should save a delegated property" do
        subject.fubar= ["Quack"]
        expect(subject.fubar).to eq ["Quack"]
        expect(subject.withText.get_values(:fubar).first).to eq 'Quack'
        subject.cow="Low"
        expect(subject.cow).to eq "Low"
        expect(subject.xmlish.term_values(:cow).first).to eq 'Low'

        subject.pig="Oink"
        expect(subject.pig).to eq "Oink"
      end

      it "should allow passing parameters to the delegate accessor" do
        subject.fubar = ["one", "two"]
        expect(subject.fubar(1)).to eq ['two']
      end

      describe "assigning wrong cardinality" do
        it "should not allow passing a string to a multiple attribute writer" do
          expect { subject.fubar = "Quack" }.to raise_error ArgumentError
          expect { subject.fubar = ["Quack"] }.not_to raise_error
          expect { subject.fubar = nil }.not_to raise_error
        end

        it "should not allow passing an enumerable to a unique attribute writer" do
          expect { subject.cow = "Low" }.not_to raise_error
          expect { subject.cow = ["Low"]
            }.to raise_error ArgumentError, "You attempted to set the attribute `cow' on `BarHistory2' to an enumerable value. However, this attribute is declared as being singular."
          expect { subject.cow = nil }.not_to raise_error
        end
      end

      it "should return an array if marked as multiple" do
        subject.horse=["neigh", "whinny"]
        expect(subject.horse).to eq ["neigh", "whinny"]
      end

      it "should be able to delegate deeply into the terminology" do
        subject.duck=["Quack", "Peep"]
        expect(subject.duck).to eq ["Quack", "Peep"]
      end

      context "change tracking" do
        it "should work for delegated attributes" do
          expect {
            subject.fubar = ["Meow"]
          }.to change { subject.fubar_changed? }.from(false).to(true)
        end

        it "should work for properties" do
          expect {
            subject.goose = ["honk!"]
          }.to change { subject.goose_changed? }.from(false).to(true)
        end
      end

      describe "hash getters and setters" do
        it "should accept symbol keys" do
          subject[:duck]= ["Cluck", "Gobble"]
          expect(subject[:duck]).to eq ["Cluck", "Gobble"]
        end

        it "should accept string keys" do
          subject['duck']= ["Cluck", "Gobble"]
          expect(subject['duck']).to eq ["Cluck", "Gobble"]
        end

        it "should accept field names with _id that are not associations" do
          subject['animal_id'] = "lemur"
          expect(subject['animal_id']).to eq "lemur"
        end

        it "should raise an error on the reader when the field isn't delegated" do
          expect {subject['donkey'] }.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `donkey'"
        end

        it "should raise an error on the setter when the field isn't delegated" do
          expect {subject['donkey']="bray" }.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `donkey'"
        end
      end

      describe "attributes=" do
        it "should raise an error on an invalid attribute" do
          expect {subject.attributes = {'donkey'=>"bray" }}.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `donkey'"
        end
      end

      describe "attributes" do
        let(:vals) { {'cow'=>"moo", 'pig' => 'oink', 'horse' =>['neigh'], "fubar"=>[], 'duck'=>['quack'], 'animal_id'=>'', 'goose' => [] } }
        before { subject.attributes = vals }
        it "should return a hash" do
          expect(subject.attributes).to eq(vals.merge('id' => nil))
        end
      end

      describe '.multiple?', focus: true do
        it 'returns false if attribute has not been defined as multi-valued' do
          expect(BarHistory2.multiple?(:pig)).to be false
        end

        it 'returns true if attribute is a ActiveTriples property' do
          expect(BarHistory2.multiple?(:goose)).to be true
        end

        it 'returns true if attribute has been defined as multi-valued' do
          expect(BarHistory2.multiple?(:horse)).to be true
        end

        it 'raises an error if the attribute does not exist' do
          expect{BarHistory2.multiple?(:arbitrary_nonexistent_attribute)}.to raise_error ActiveFedora::UnknownAttributeError, "BarHistory2 does not have an attribute `arbitrary_nonexistent_attribute'"
        end
      end

      describe ".datastream_class_for_name" do
        it "should return the specifed class" do
          expect(BarHistory2.send(:datastream_class_for_name, 'someData')).to eq ActiveFedora::SimpleDatastream
        end
      end
    end

    describe "with a superclass" do
      before :all do
        class BarHistory2 < ActiveFedora::Base
          has_metadata 'xmlish', :type=>BarStream2
          Deprecation.silence(ActiveFedora::Attributes) do
            has_attributes :donkey, :cow, datastream: 'xmlish', multiple: true
          end
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
        expect(subject.donkey).to eq ["Bray", "Hee-haw"]
      end

      it "should be able to track change status" do
        expect {
          subject.cow = ["Moo"]
        }.to change { subject.cow_changed? }.from(false).to(true)
      end
    end
  end

  context "with a RDF datastream" do
    before :all do
      class BarRdfDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, predicate: ::RDF::DC.title
        property :description, predicate: ::RDF::DC.description
      end
      class BarHistory4 < ActiveFedora::Base
        has_metadata 'rdfish', :type=>BarRdfDatastream
        Deprecation.silence(ActiveFedora::Attributes) do
          has_attributes :title, datastream: 'rdfish', multiple: true
          has_attributes :description, datastream: 'rdfish', multiple: false
        end
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
      Object.send(:remove_const, :BarRdfDatastream)
    end

    subject { BarHistory4.new }

    context "with a multivalued field" do
      it "should be able to track change status" do
        expect {
          subject.title = ["Title1", "Title2"]
        }.to change { subject.title_changed? }.from(false).to(true)
      end
    end

    context "with a single-valued field" do
      it "should be able to track change status" do
        expect {
          subject.description = "A brief description"
        }.to change { subject.description_changed? }.from(false).to(true)
      end
    end
  end

  context "without a datastream" do
    before :all do
      class BarHistory4 < ActiveFedora::Base
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
    end

    subject { BarHistory4}

    describe "has_attributes" do
      it "should raise an error" do
        Deprecation.silence(ActiveFedora::Attributes) do
          expect {subject.has_attributes :title, :description, multiple: true}.to raise_error
        end
      end
    end
  end


  context "when an unknown datastream is specified" do
    before :all do
      class BarHistory4 < ActiveFedora::Base
        Deprecation.silence(ActiveFedora::Attributes) do
          has_attributes :description, datastream: 'rdfish', multiple: true
        end
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
    end

    subject { BarHistory4.new }

    let(:error_message) { "Undefined file: `rdfish' in property description" }

    it "raises an error on get" do
      expect { subject.description }.to raise_error(ArgumentError, error_message)
    end

    it "raises an error on set" do
      expect { subject.description = ['Neat'] }.to raise_error(ArgumentError, error_message)
    end

    describe ".datastream_class_for_name" do
      it "should return the default class" do
        expect(BarHistory4.send(:datastream_class_for_name, 'content')).to eq ActiveFedora::File
      end
    end
  end

  context "when a datastream is specified as a symbol" do
    before :all do
      class BarRdfDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, predicate: ::RDF::DC.title
        property :description, predicate: ::RDF::DC.description
      end
      class BarHistory4 < ActiveFedora::Base
        has_metadata 'rdfish', :type=>BarRdfDatastream
        Deprecation.silence(ActiveFedora::Attributes) do
          has_attributes :description, datastream: :rdfish
        end
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

  context "when properties are defined on an object" do
    before :all do
      class BarHistory4 < ActiveFedora::Base
        property :title, predicate: ::RDF::DC.title do |index|
          index.as :symbol
        end
        property :abstract, predicate: ::RDF::DC.abstract, multiple: false
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
    end

    let(:obj) { BarHistory4.new(title: ['test1']) }
    subject { obj }

    describe "accessing attributes" do
      context "using generated methods" do
        it "should return values" do
          expect(subject.title).to eq ['test1']
        end
      end

      context "using hash accessors" do
        context "on single value fields" do
          it "should have a default value" do
            expect(subject[:abstract]).to be_nil
          end

          context "when there are two assertions for the predicate" do
            before do
              subject.resource[:abstract] = ['foo', 'bar']
            end
            it "should raise an error if just returning the first value would cause data loss" do
              expect { subject[:abstract] }.to raise_error ActiveFedora::ConstraintError, "Expected \"abstract\" to have 0-1 statements, but there are 2"
            end
          end
        end

        context "multiple values" do
          it "should return values" do
            expect(subject[:title]).to eq ['test1']
          end
        end
      end
    end

    context "indexing" do
      let(:solr_doc) { obj.to_solr }

      it "should index the attributes" do
        expect(solr_doc['title_ssim']).to eq ['test1']
      end
    end

    describe "when an object of the wrong cardinality is set" do
      it "should not allow passing a string to a multiple property writer" do
        expect { subject.title = "Quack" }.to raise_error ArgumentError
        expect { subject.title = ["Quack"] }.not_to raise_error
        expect { subject.title = nil }.not_to raise_error
      end

      it "should not allow an enumerable to a unique attribute writer" do
        expect { subject.abstract = "Low" }.not_to raise_error
        expect { subject.abstract = ["Low"]
          }.to raise_error ArgumentError, "You attempted to set the property `abstract' to an enumerable value. However, this property is declared as singular."
        expect { subject.abstract = nil }.not_to raise_error
      end
    end
  end
end
