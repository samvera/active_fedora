require 'spec_helper'

describe "Nesting attribute behavior of RDFDatastream" do
  describe ".attributes=" do
    describe "complex properties" do
      before do
        class DummyMADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
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

          class Topic < ActiveFedora::Rdf::Resource
            property :elementList, predicate: DummyMADS.elementList, class_name: "ComplexRDFDatastream::ElementList"
            accepts_nested_attributes_for :elementList
          end
          class PersonalName < ActiveFedora::Rdf::Resource
            property :elementList, predicate: DummyMADS.elementList, class_name: "ComplexRDFDatastream::ElementList"
            property :extraProperty, predicate: DummyMADS.elementValue, class_name: "ComplexRDFDatastream::Topic"
            accepts_nested_attributes_for :elementList, :extraProperty
          end
          class ElementList < ActiveFedora::Rdf::List
            configure type: DummyMADS.elementList
            property :topicElement, predicate: DummyMADS.TopicElement, class_name: "ComplexRDFDatastream::MadsTopicElement"
            property :temporalElement, predicate: DummyMADS.TemporalElement
            property :fullNameElement, predicate: DummyMADS.FullNameElement
            property :dateNameElement, predicate: DummyMADS.DateNameElement
            property :nameElement, predicate: DummyMADS.NameElement
            property :elementValue, predicate: DummyMADS.elementValue
            accepts_nested_attributes_for :topicElement
          end
          class MadsTopicElement < ActiveFedora::Rdf::Resource
            configure :type => DummyMADS.TopicElement
            property :elementValue, predicate: DummyMADS.elementValue
          end
        end
      end
      after do
        Object.send(:remove_const, :ComplexRDFDatastream)
        Object.send(:remove_const, :DummyMADS)
      end
      subject { ComplexRDFDatastream.new(double('inner object', :pid=>'foo', :new_record? =>true), 'descMetadata') }
      let(:params) do
        { myResource:
          {
            topic_attributes: {
              '0' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: [{elementValue:"Cosmology"}]
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
          subject.elementList.first[0].elementValue.should == ["Quantum Behavior"]
          subject.elementList.first[1].elementValue.should == ["Wave Function"]

        end
        it "should accept an array" do
          subject.elementList_attributes =  [{ topicElement_attributes: [{ elementValue:"Quantum Behavior" }, { elementValue:"Wave Function" }]}]
          subject.elementList.first[0].elementValue.should == ["Quantum Behavior"]
          subject.elementList.first[1].elementValue.should == ["Wave Function"]
        end
      end

      it "should create nested objects" do
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
        subject.topic[0].elementList.first[0].elementValue.should == ["Cosmology"]
        subject.topic[1].elementList.first[0].elementValue.should == ["Quantum Behavior"]
        subject.personalName.first.elementList.first.fullNameElement.should == ["Jefferson, Thomas"]
        subject.personalName.first.elementList.first.dateNameElement.should == ["1743-1826"]
      end
    end

    describe "with an existing object" do
      before(:each) do
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          property :parts, predicate: RDF::DC.hasPart, :class_name=>'Component'
          accepts_nested_attributes_for :parts, allow_destroy: true

          class Component < ActiveFedora::Rdf::ObjectResource
            property :label, predicate: RDF::DC.title
          end
        end

      end

      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end
      subject { SpecDatastream.new(double('inner object', :pid=>'foo', :new_record? =>true), 'descMetadata') }
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

        subject.parts.map{|p| p.label.first}.should == ['Alternator', 'Universal Joint', 'Transmission', 'Oil Pump']

      end
      it "create a new object when the id is provided" do
       subject.parts_attributes= [{id: 'http://example.com/part#1', label: "Universal Joint"}]
       expect(subject.parts.last.rdf_subject).to eq RDF::URI('http://example.com/part#1')
      end
    end
  end
end
