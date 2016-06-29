require 'spec_helper'

describe "Nesting attribute behavior of RDFDatastream" do
  describe ".attributes=" do
    context "complex properties in a datastream" do
      before do
        class DummyMADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
          # TODO: this test is order dependent. It expects to use the object created in the previous test
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
          property :title, predicate: ::RDF::Vocab::DC.title

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
            configure type: DummyMADS.TopicElement
            property :elementValue, predicate: DummyMADS.elementValue
          end
        end
      end
      after do
        Object.send(:remove_const, :ComplexRDFDatastream)
        Object.send(:remove_const, :DummyMADS)
      end
      subject { ComplexRDFDatastream.new }
      let(:params) do
        { myResource:
          {
            topic_attributes: {
              '0' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: [{
                    id: 'http://library.ucsd.edu/ark:/20775/bb3333333x',
                    elementValue: "Cosmology"
                  }]
                }]
              },
              '1' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: { '0' => { elementValue: "Quantum Behavior" } }
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
              # , "Hemings, Sally"
            ]
          }
        }
      end

      describe "on lists" do
        subject { ComplexRDFDatastream::PersonalName.new(nil) }
        it "accepts a hash" do
          subject.elementList_attributes = [{ topicElement_attributes: { '0' => { elementValue: "Quantum Behavior" }, '1' => { elementValue: "Wave Function" } } }]
          expect(subject.elementList.first[0].elementValue).to eq ["Quantum Behavior"]
          expect(subject.elementList.first[1].elementValue).to eq ["Wave Function"]
        end
        it "accepts an array" do
          subject.elementList_attributes = [{ topicElement_attributes: [{ elementValue: "Quantum Behavior" }, { elementValue: "Wave Function" }] }]
          element_values = subject.elementList.first.map(&:elementValue)
          expect(element_values).to contain_exactly ["Quantum Behavior"], ["Wave Function"]
        end
      end

      context "from nested objects" do
        before do
          # Replace the graph's contents with the Hash
          subject.attributes = params[:myResource]
        end

        it 'has attributes' do
          element_values = subject.topic.map { |x| x.elementList.first[0].elementValue }
          expect(element_values).to contain_exactly ["Cosmology"], ["Quantum Behavior"]
          expect(subject.personalName.first.elementList.first.fullNameElement).to contain_exactly "Jefferson, Thomas"
          expect(subject.personalName.first.elementList.first.dateNameElement).to contain_exactly "1743-1826"
        end

        it 'builds nodes with ids' do
          element_list_elements = subject.topic.flat_map { |y| y.elementList.first[0].rdf_subject }
          expect(element_list_elements).to include 'http://library.ucsd.edu/ark:/20775/bb3333333x'
          expect(subject.personalName.first.rdf_subject).to eq 'http://library.ucsd.edu/ark:20775/jefferson'
        end

        it 'fails when writing to a non-predicate' do
          attributes = { topic_attributes: { '0' => { elementList_attributes: [{ topicElement_attributes: [{ fake_predicate: "Cosmology" }] }] } } }
          expect { subject.attributes = attributes }.to raise_error ArgumentError
        end

        it 'fails when writing to a non-predicate with a setter method' do
          attributes = { topic_attributes: { '0' => { elementList_attributes: [{ topicElement_attributes: [{ name: "Cosmology" }] }] } } }
          expect { subject.attributes = attributes }.to raise_error ArgumentError
        end
      end
    end

    describe "with an existing object" do
      before(:each) do
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          property :parts, predicate: ::RDF::Vocab::DC.hasPart, class_name: 'Component'
          accepts_nested_attributes_for :parts, allow_destroy: true

          class Component < ActiveTriples::Resource
            property :label, predicate: ::RDF::Vocab::DC.title
          end
        end
      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end
      subject { SpecDatastream.new }
      before do
        subject.attributes = { parts_attributes: [
          { label: 'Alternator' },
          { label: 'Distributor' },
          { label: 'Transmission' },
          { label: 'Fuel Filter' }] }
      end
      let(:replace_object_id) { subject.parts.find { |x| x.label == ['Distributor'] }.rdf_subject.to_s }
      let(:remove_object_id) { subject.parts.find { |x| x.label == ['Fuel Filter'] }.rdf_subject.to_s }

      it "updates nested objects" do
        subject.parts_attributes = [{ id: replace_object_id, label: "Universal Joint" }, { label: "Oil Pump" }, { id: remove_object_id, _destroy: '1', label: "bar1 uno" }]

        expect(subject.parts.map { |p| p.label.first }).to contain_exactly 'Alternator', 'Universal Joint', 'Transmission', 'Oil Pump'
      end
      it "create a new object when the id is provided" do
        subject.parts_attributes = [{ id: 'http://example.com/part#1', label: "Universal Joint" }]
        expect(subject.parts.map(&:rdf_subject)).to include RDF::URI('http://example.com/part#1')
      end
    end
  end
end
