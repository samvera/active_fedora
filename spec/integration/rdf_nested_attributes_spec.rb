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
          map_predicates do |map|
            map.topic(in: DummyMADS, to: "Topic", class_name:"Topic")
            map.personalName(in: DummyMADS, to: "PersonalName", class_name:"PersonalName")
            map.title(in: RDF::DC)
          end

          accepts_nested_attributes_for :topic, :personalName

          class Topic
            include ActiveFedora::RdfObject
            map_predicates do |map|
              map.elementList(in: DummyMADS, class_name:"ComplexRDFDatastream::ElementList")
            end
            accepts_nested_attributes_for :elementList
          end
          class PersonalName
            include ActiveFedora::RdfObject
            map_predicates do |map|
              map.elementList(in: DummyMADS, to: "elementList", class_name:"ComplexRDFDatastream::ElementList")
              map.extraProperty(in: DummyMADS, to: "elementValue", class_name:"ComplexRDFDatastream::Topic")
            end
            accepts_nested_attributes_for :elementList, :extraProperty
          end
          class ElementList
            include ActiveFedora::RdfObject
            rdf_type DummyMADS.elementList
            map_predicates do |map|
              map.topicElement(in: DummyMADS, to: "TopicElement")
              map.temporalElement(in: DummyMADS, to: "TemporalElement")
              map.fullNameElement(in: DummyMADS, to: "FullNameElement")
              map.dateNameElement(in: DummyMADS, to: "DateNameElement")
              map.nameElement(in: DummyMADS, to: "NameElement")
              map.elementValue(in: DummyMADS)
            end
          end
        end
      end
      after do
        Object.send(:remove_const, :ComplexRDFDatastream)
        Object.send(:remove_const, :DummyMADS)
      end
      subject { ComplexRDFDatastream.new(double('inner object', :pid=>'foo', :new? =>true), 'descMetadata') }
      let(:params) do 
        { myResource: 
          {
            topic_attributes: {
              '0' =>
              {
                elementList_attributes: [{
                  topicElement:"Cosmology"
                  }]
              },
              '1' =>
              {
                elementList_attributes: [{
                  topicElement:"Quantum Behavior"
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

          subject.topic.first.elementList.first.topicElement.should == ["Cosmology"]
          subject.topic[1].elementList.first.topicElement.should == ["Quantum Behavior"]
          subject.personalName.first.elementList.first.fullNameElement.should == ["Jefferson, Thomas"]
          subject.personalName.first.elementList.first.dateNameElement.should == ["1743-1826"]
      end
    end

    describe "with an existing object" do
      before(:each) do 
        class SpecDatastream < ActiveFedora::NtriplesRDFDatastream
          map_predicates do |map|
            map.parts(:in=> RDF::DC, :to=>'hasPart', :class_name=>'Component')
          end
          accepts_nested_attributes_for :parts, allow_destroy: true

          class Component
            include ActiveFedora::RdfObject
            map_predicates do |map|
              map.label(:in=> RDF::DC, :to=>'title')
            end
          end
        end

      end
      
      after(:each) do
        Object.send(:remove_const, :SpecDatastream)
      end
      subject { SpecDatastream.new(double('inner object', :pid=>'foo', :new? =>true), 'descMetadata') }
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
       subject.parts.last.rdf_subject.should == 'http://example.com/part#1'
      end
    end    
  end
end
