require 'spec_helper'

describe ActiveFedora::RDFDatastream do
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
    subject { ComplexRDFDatastream.new(stub('inner object', :pid=>'foo', :new? =>true), 'descMetadata') }
    
    describe ".attributes=" do
      describe "complex properties" do
        let(:params) do 
          { myResource: 
            {
              topic_attributes: [
                {
                  elementList_attributes: {
                    topicElement:"Cosmology"
                    }
                },
                {
                  elementList_attributes: {
                    topicElement:"Quantum Behavior"
                  }
                }
              ],
              personalName_attributes: [
                { 
                  elementList_attributes: {
                    fullNameElement: "Jefferson, Thomas",
                    dateNameElement: "1743-1826"                  
                  }
                } 
                #, "Hemings, Sally"
              ],
            }
          }
        end
        it "should support mass-assignment" do
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
    end
end
