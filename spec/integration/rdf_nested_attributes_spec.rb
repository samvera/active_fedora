require 'spec_helper'

describe 'Nesting attribute behavior of RDFDatastream' do
  describe '.attributes=' do
    describe 'complex properties' do
      before do
        class DummyMADS < RDF::Vocabulary('http://www.loc.gov/mads/rdf/v1#')
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
          map_predicates do |map|
            map.topic(in: DummyMADS, to: 'Topic', class_name: 'Topic')
            map.personalName(in: DummyMADS, to: 'PersonalName', class_name: 'PersonalName')
            map.title(in: RDF::DC)
          end

          accepts_nested_attributes_for :topic, :personalName

          class Topic
            include ActiveFedora::RdfObject
            map_predicates do |map|
              map.elementList(in: DummyMADS, class_name: 'ComplexRDFDatastream::ElementList')
            end
            accepts_nested_attributes_for :elementList
          end
          class PersonalName
            include ActiveFedora::RdfObject
            map_predicates do |map|
              map.elementList(in: DummyMADS, to: 'elementList', class_name: 'ComplexRDFDatastream::ElementList')
              map.extraProperty(in: DummyMADS, to: 'elementValue', class_name: 'ComplexRDFDatastream::Topic')
            end
            accepts_nested_attributes_for :elementList, :extraProperty
          end
          class ElementList
            include ActiveFedora::RdfList
            rdf_type DummyMADS.elementList
            map_predicates do |map|
              map.topicElement(in: DummyMADS, to: 'TopicElement', :class_name => 'MadsTopicElement')
              map.temporalElement(in: DummyMADS, to: 'TemporalElement')
              map.fullNameElement(in: DummyMADS, to: 'FullNameElement')
              map.dateNameElement(in: DummyMADS, to: 'DateNameElement')
              map.nameElement(in: DummyMADS, to: 'NameElement')
              map.elementValue(in: DummyMADS)
            end
            accepts_nested_attributes_for :topicElement
          end
          class MadsTopicElement
            include ActiveFedora::RdfObject
            rdf_type DummyMADS.TopicElement
            map_predicates do |map|
              map.elementValue(in: DummyMADS)
            end
          end
        end
      end
      after do
        Object.send(:remove_const, :ComplexRDFDatastream)
        Object.send(:remove_const, :DummyMADS)
      end
      subject { ComplexRDFDatastream.new(double('inner object', :pid => 'foo', :new_record? => true), 'descMetadata') }
      let(:params) do
        { myResource:
          {
            topic_attributes: {
              '0' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: [{elementValue: 'Cosmology'}]
                  }]
              },
              '1' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: {'0' => {elementValue: 'Quantum Behavior'}}
                }]
              }
            },
            personalName_attributes: [
              {
                elementList_attributes: [{
                  fullNameElement: 'Jefferson, Thomas',
                  dateNameElement: '1743-1826'
                }]
              }
              #, "Hemings, Sally"
            ]
          }
        }
      end

      describe 'on lists' do
        subject { ComplexRDFDatastream::PersonalName.new(RDF::Graph.new) }
        it 'should accept a hash' do
          subject.elementList_attributes =  [{ topicElement_attributes: {'0' => { elementValue: 'Quantum Behavior' }, '1' => { elementValue: 'Wave Function' }}}]
          expect(subject.elementList.first[0].elementValue).to eq(['Quantum Behavior'])
          expect(subject.elementList.first[1].elementValue).to eq(['Wave Function'])

        end
        it 'should accept an array' do
          subject.elementList_attributes =  [{ topicElement_attributes: [{ elementValue: 'Quantum Behavior' }, { elementValue: 'Wave Function' }]}]
          expect(subject.elementList.first[0].elementValue).to eq(['Quantum Behavior'])
          expect(subject.elementList.first[1].elementValue).to eq(['Wave Function'])
        end
      end

      it 'should create nested objects' do
          # Replace the graph's contents with the Hash
          subject.attributes = params[:myResource]

          # Here's how this would happen if we didn't have attributes=
          # personal_name = subject.personalName.build
          # elem_list = personal_name.elementList.build
          # elem_list.fullNameElement = "Jefferson, Thomas"
          # elem_list.dateNameElement = "1743-1826"
          # topic = subject.topic.build
          # elem_list = topic.elementList.build
          # elem_list.fullNameElement = 'Cosmology'

          expect(subject.topic[0].elementList.first[0].elementValue).to eq(['Cosmology'])
          expect(subject.topic[1].elementList.first[0].elementValue).to eq(['Quantum Behavior'])
          expect(subject.personalName.first.elementList.first.fullNameElement).to eq(['Jefferson, Thomas'])
          expect(subject.personalName.first.elementList.first.dateNameElement).to eq(['1743-1826'])
      end
    end

    describe 'with an existing object' do
      before(:each) do
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          map_predicates do |map|
            map.parts(:in => RDF::DC, :to => 'hasPart', :class_name => 'Component')
          end
          accepts_nested_attributes_for :parts, allow_destroy: true

          class Component
            include ActiveFedora::RdfObject
            map_predicates do |map|
              map.label(:in => RDF::DC, :to => 'title')
            end
          end
        end

      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end
      subject { SpecDatastream.new(double('inner object', :pid => 'foo', :new_record? => true), 'descMetadata') }
      before do
        subject.attributes = { parts_attributes: [
                                  {label: 'Alternator'},
                                  {label: 'Distributor'},
                                  {label: 'Transmission'},
                                  {label: 'Fuel Filter'}]}
      end
      let (:replace_object_id) { subject.parts[1].rdf_subject.to_s }
      let (:remove_object_id) { subject.parts[3].rdf_subject.to_s }

      it 'should update nested objects' do
        subject.parts_attributes = [{id: replace_object_id, label: 'Universal Joint'}, {label: 'Oil Pump'}, {id: remove_object_id, _destroy: '1', label: 'bar1 uno'}]

        expect(subject.parts.map{|p| p.label.first}).to eq(['Alternator', 'Universal Joint', 'Transmission', 'Oil Pump'])

      end
      it 'create a new object when the id is provided' do
       subject.parts_attributes = [{id: 'http://example.com/part#1', label: 'Universal Joint'}]
       expect(subject.parts.last.rdf_subject).to eq('http://example.com/part#1')
      end
    end
  end
end
