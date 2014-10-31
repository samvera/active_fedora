require 'spec_helper'

describe "Nesting attribute behavior of RDFDatastream" do
  describe ".attributes=" do
    let(:parent) { double('inner object', uri: "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/1234", id: '1234', new_record?: true) }

    describe "complex properties" do
      before do
        class DummyMADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
  # TODO this test is order dependent. It expects to use the object created in the previous test
          # componentList and Types of components
          property :componentList
          property :Topic
          property :Temporal
          property :PersonalName
          property :CorporateName
          property :ComplexSubject


          # elementList and elementList values
          property :elementList
          property :elementValue
          property :TopicElement
          property :TemporalElement
          property :NameElement
          property :FullNameElement
          property :DateNameElement
        end

        class ComplexRDFDatastream < ActiveFedora::NtriplesRDFDatastream
          property :topic, predicate: DummyMADS.Topic, class_name: "Topic"
          property :personalName, predicate: DummyMADS.PersonalName, class_name: "PersonalName"
          property :title, predicate: RDF::DC.title


          accepts_nested_attributes_for :topic, :personalName

          class Topic < ActiveTriples::Resource
            property :elementList, predicate: DummyMADS.elementList, class_name: "ComplexRDFDatastream::ElementList"
            accepts_nested_attributes_for :elementList
          end
          class PersonalName < ActiveTriples::Resource
            property :elementList, predicate: DummyMADS.elementList, class_name: "ComplexRDFDatastream::ElementList"
            property :extraProperty, predicate: DummyMADS.elementValue, class_name: "ComplexRDFDatastream::Topic"
            accepts_nested_attributes_for :elementList, :extraProperty
          end
          class ElementList < ActiveTriples::List
            configure type: DummyMADS.elementList
            property :topicElement, predicate: DummyMADS.TopicElement, class_name: "ComplexRDFDatastream::MadsTopicElement"
            property :temporalElement, predicate: DummyMADS.TemporalElement
            property :fullNameElement, predicate: DummyMADS.FullNameElement
            property :dateNameElement, predicate: DummyMADS.DateNameElement
            property :nameElement, predicate: DummyMADS.NameElement
            property :elementValue, predicate: DummyMADS.elementValue
            accepts_nested_attributes_for :topicElement
          end
          class MadsTopicElement < ActiveTriples::Resource
            configure :type => DummyMADS.TopicElement
            property :elementValue, predicate: DummyMADS.elementValue
          end
        end
      end
      after do
        Object.send(:remove_const, :ComplexRDFDatastream)
        Object.send(:remove_const, :DummyMADS)
      end
      subject { ComplexRDFDatastream.new(parent, 'descMetadata') }
      let(:params) do
        { myResource:
          {
            topic_attributes: {
              '0' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: [{
                    id: 'http://library.ucsd.edu/ark:/20775/bb3333333x',
                    elementValue:"Cosmology"
                     }]
                  }]
              },
              '1' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: {'0' => {elementValue:"Quantum Behavior"}}
                }]
              }
            },
            personalName_attributes: [
              {
                id: 'http://library.ucsd.edu/ark:20775/jefferson',
                elementList_attributes: [{                         
                  fullNameElement: "Jefferson, Thomas",
                  dateNameElement: "1743-1826"
                }]
              }
              #, "Hemings, Sally"
            ],
          }
        }
      end

      describe "on lists" do
        subject { ComplexRDFDatastream::PersonalName.new(RDF::Graph.new) }
        it "should accept a hash" do
          subject.elementList_attributes =  [{ topicElement_attributes: {'0' => { elementValue:"Quantum Behavior" }, '1' => { elementValue:"Wave Function" }}}]
          expect(subject.elementList.first[0].elementValue).to eq ["Quantum Behavior"]
          expect(subject.elementList.first[1].elementValue).to eq ["Wave Function"]

        end
        it "should accept an array" do
          subject.elementList_attributes =  [{ topicElement_attributes: [{ elementValue:"Quantum Behavior" }, { elementValue:"Wave Function" }]}]
          expect(subject.elementList.first[0].elementValue).to eq ["Quantum Behavior"]
          expect(subject.elementList.first[1].elementValue).to eq ["Wave Function"]
        end
      end

      context "from nested objects" do
        before do
          # Replace the graph's contents with the Hash
          subject.attributes = params[:myResource]
        end

        it 'should have attributes' do
          expect(subject.topic[0].elementList.first[0].elementValue).to eq ["Cosmology"]
          expect(subject.topic[1].elementList.first[0].elementValue).to eq ["Quantum Behavior"]
          expect(subject.personalName.first.elementList.first.fullNameElement).to eq ["Jefferson, Thomas"]
          expect(subject.personalName.first.elementList.first.dateNameElement).to eq ["1743-1826"]
        end
        
        it 'should build nodes with ids' do
          expect(subject.topic[0].elementList.first[0].rdf_subject).to eq 'http://library.ucsd.edu/ark:/20775/bb3333333x'
          expect(subject.personalName.first.rdf_subject).to eq  'http://library.ucsd.edu/ark:20775/jefferson'
        end
        
        it 'should fail when writing to a non-predicate' do
          attributes = { topic_attributes: { '0' => { elementList_attributes: [{ topicElement_attributes: [{ fake_predicate:"Cosmology" }] }]}}}
          expect{ subject.attributes = attributes }.to raise_error ArgumentError
        end

        it 'should fail when writing to a non-predicate with a setter method' do
          attributes = { topic_attributes: { '0' => { elementList_attributes: [{ topicElement_attributes: [{ name:"Cosmology" }] }]}}}
          expect{ subject.attributes = attributes }.to raise_error ArgumentError
        end
      end
    end

    describe "with an existing object" do
      before(:each) do
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          property :parts, predicate: RDF::DC.hasPart, :class_name=>'Component'
          accepts_nested_attributes_for :parts, allow_destroy: true

          class Component < ActiveTriples::Resource
            property :label, predicate: RDF::DC.title
          end
        end

      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end
      subject { SpecDatastream.new(parent, 'descMetadata') }
      before do
        subject.attributes = { parts_attributes: [
                                  {label: 'Alternator'},
                                  {label: 'Distributor'},
                                  {label: 'Transmission'},
                                  {label: 'Fuel Filter'}]}
      end
      let (:replace_object_id) { subject.parts[1].rdf_subject.to_s }
      let (:remove_object_id) { subject.parts[3].rdf_subject.to_s }

      it "should update nested objects" do
        subject.parts_attributes= [{id: replace_object_id, label: "Universal Joint"}, {label:"Oil Pump"}, {id: remove_object_id, _destroy: '1', label: "bar1 uno"}]

        expect(subject.parts.map{|p| p.label.first}).to eq ['Alternator', 'Universal Joint', 'Transmission', 'Oil Pump']

      end
      it "create a new object when the id is provided" do
       subject.parts_attributes= [{id: 'http://example.com/part#1', label: "Universal Joint"}]
       expect(subject.parts.last.rdf_subject).to eq RDF::URI('http://example.com/part#1')
      end
    end
  end
end
