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

        
        property :authoritativeLabel
        class Topic
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:elementList, :topicElement]
          end
          map_predicates do |map|
            map.elementList(in: DummyMADS, class_name:"DummyMADS::ElementList")
          end
        end
        class Temporal
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:elementList, :temporalElement]
          end
          map_predicates do |map|
            map.elementList(in: DummyMADS, class_name:"DummyMADS::ElementList")
          end
        end
        class PersonalName
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:elementList, :fullNameElement]
          end
          
          # rdf_type DummyMADS.Topic
          map_predicates do |map|
            map.elementList(in: DummyMADS, to: "elementList", class_name:"DummyMADS::ElementList")
          end
        end
        class CorporateName
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:elementList, :nameElement]
          end
          
          # rdf_type DummyMADS.Topic
          map_predicates do |map|
            map.elementList(in: DummyMADS, class_name:"DummyMADS::ElementList")
          end
        end
        
        class ComplexSubject
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:componentList, :topic]
          end
          # rdf_type DummyMADS.Topic
          map_predicates do |map|
            map.componentList(in: DummyMADS, class_name:"DummyMADS::ComponentList")
          end
        end
        
        class ElementList
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:elementValue]
          end
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
        
        class ComponentList
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:topic]
          end
          rdf_type DummyMADS.componentList
          map_predicates do |map|
            map.topic(in: DummyMADS, to: "Topic", class_name:"DummyMADS::Topic")
            map.temporal(in: DummyMADS, to: "Temporal", class_name:"DummyMADS::Temporal")
            map.personalName(in: DummyMADS, to: "PersonalName", class_name:"DummyMADS::PersonalName")
            map.corporateName(in: DummyMADS, to: "CorporateName", class_name:"DummyMADS::CorporateName")
          end
        end
      end
      class ComplexRDFDatastream < ActiveFedora::NtriplesRDFDatastream
        map_predicates do |map|
          map.topic(in: DummyMADS, to: "Topic", class_name:"DummyMADS::Topic")
          map.temporal(in: DummyMADS, to: "Temporal", class_name:"DummyMADS::Temporal")
          map.personalName(in: DummyMADS, to: "PersonalName", class_name:"DummyMADS::PersonalName")
          map.corporateName(in: DummyMADS, to: "CorporateName", class_name:"DummyMADS::CorporateName")
          map.complexSubject(in: DummyMADS, to: "ComplexSubject", class_name:"DummyMADS::ComplexSubject")
          map.title(in: RDF::DC)
        end
      end
      @ds = ComplexRDFDatastream.new(stub('inner object', :pid=>'foo', :new? =>true), 'descMetadata')
    end
    after do
      Object.send(:remove_const, :ComplexRDFDatastream)
      Object.send(:remove_const, :DummyMADS)
    end
    subject { @ds } 
    
    describe "complex properties" do
      it "should insert values at default_write_point_for_values" do
        @ds.topic = "Software Testing"
        @ds.topic.should = ["Software Testing"]
        @ds.topic.nodeset.first.default_write_point_for_values.should == [:elementList, :topicElement]
        @ds.topic(0).elementList(0).topicElement.should == ["Software Testing"]
      end
      it "should support assignment operator and insertion operator" do
        @ds.topic = ["Cosmology"]
        @ds.topic << "Quantum States"
        @ds.topic.should == ["Cosmology", "Quantum States"]
        @ds.topic.nodeset.first.default_write_point_for_values.should == [:elementList, :topicElement]
        @ds.topic(0).elementList(0).topicElement.should == ["Cosmology"] 
        
        list1_id = @ds.topic(0).elementList(0).rdf_subject.id
        list2_id = @ds.topic(1).elementList(0).rdf_subject.id
        
        expected_xml = '<?xml version="1.0" encoding="UTF-8"?>
               <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:ns0="http://www.loc.gov/mads/rdf/v1#">
                 <rdf:Description rdf:about="info:fedora/foo">
                   <ns0:Topic>
                     <rdf:Description>
                       <ns0:elementList rdf:nodeID="'+list1_id+'"/>
                     </rdf:Description>
                   </ns0:Topic>
                   <ns0:Topic>
                     <rdf:Description>
                       <ns0:elementList rdf:nodeID="'+list2_id+'"/>
                     </rdf:Description>
                   </ns0:Topic>
                 </rdf:Description>
                 <ns0:elementList rdf:nodeID="'+list1_id+'">
                   <ns0:TopicElement>Cosmology</ns0:TopicElement>
                 </ns0:elementList>
                 <ns0:elementList rdf:nodeID="'+list2_id+'">
                   <ns0:TopicElement>Quantum States</ns0:TopicElement>
                 </ns0:elementList>
               </rdf:RDF>'
        
        @ds.graph.dump(:rdfxml).should be_equivalent_to expected_xml
      end
      
      it "should support mass-assignment" do
          params = {
            myResource: {
              topic: "Cosmology",
              temporal: "16th Century",
              personalName: [
                { 
                  elementList: {
                    fullNameElement: "Jefferson, Thomas",
                    dateNameElement: "1743-1826"                  
                  }
                }, 
                "Hemings, Sally"
              ],
              corporateName: {
                elementList: {
                  nameElement: "University of California, San Diego.",
                  nameElement: "University Library",  
                }
              },
              complexSubject: {
                componentList: {
                  personalName: {
                    elementList: {
                      fullNameElement: "Callender, James T.",
                      dateNameElement: "1802" 
                    }
                  },
                  topic: "Presidency", 
                  temporal: "1801-1809"
                },
              },  

            }
          }
          
          # In this case, update_attributes is misleading because you can either replace the graph 
          # or append to the graph but can't update it.
          # @ds.update_attributes(params[:myResource])
          
          # Replace the graph's contents with the Hash
          @ds.attributes = params[:myResource]
          @ds.personalName.should == ["Jefferson, Thomas", "Hemings, Sally"]  
          
          @ds.personalName(0).elementList(0).fullNameElement.should == ["Jefferson, Thomas"]
          @ds.personalName(0).elementList(0).dateNameElement.should == ["1743-1826"]
          @ds.personalName(1).elementList(0).fullNameElement.should == ["Hemings, Sally"]
          
          @ds.topic.should == ["Cosmology"]
      end
      
    end    

    describe "Insertion Operator `<<`" do
    
      it "when given a String should create the necessary node and put the string into its default value location" do
        @ds.personalName << "Jefferson Randolph, Martha"
        @ds.personalName.should == ["Jefferson Randolph, Martha"]
        @ds.personalName(0).elementList(0).fullNameElement.should == ["Jefferson Randolph, Martha"]
      end
      
      it "when given a Node should simply insert it" do
        new_name = DummyMADS::PersonalName.new(@ds.graph)
        new_name.elementList.build
        # new_name.elementList(0).fullNameElement.build
        # new_name.elementList(0).dateNameElement.build
        new_name.elementList(0).fullNameElement = "Callender, James T."
        new_name.elementList(0).dateNameElement = "1802"
        @ds.personalName << new_name
        @ds.personalName.should == ["Callender, James T."]
        @ds.personalName(0).elementList(0).fullNameElement.should == ["Callender, James T."]
        @ds.personalName(0).elementList(0).dateNameElement.should == ["1802"]
      end
      
      it "when given a Hash should rely on properties to build nodes" do
        @ds.personalName << { 
          elementList: {
            fullNameElement: "Jefferson, Thomas",
            dateNameElement: "1743-1826"                  
          }
        }
        @ds.personalName.should == ["Jefferson, Thomas"]
        @ds.personalName(0).elementList(0).fullNameElement.should == ["Jefferson, Thomas"]
        @ds.personalName(0).elementList(0).dateNameElement.should == ["1743-1826"]
      end
      
    end
      
    describe "attributes=" do
      it "when given a Hash should use update_attributes behavior" do
        values_hash = {topic: "Cosmology",
          temporal: "16th Century",
          personalName: "Hemings, Sally"
        }
        @ds.attributes = values_hash
        @ds.topic.should == ["Cosmology"]
        @ds.temporal.should == ["16th Century"]
        @ds.personalName.should == ["Hemings, Sally"]
        @ds.topic(0).elementList(0).topicElement.should == ["Cosmology"]
        @ds.temporal(0).elementList(0).temporalElement.should == ["16th Century"]
        @ds.personalName(0).elementList(0).fullNameElement.should == ["Hemings, Sally"]
      end
      
      it "when given an Array of Hashes should add each of the items from the array as a node corresponding to the specified property behavior" do
        values_array = {
          personalName:[
          { 
            elementList: {
              fullNameElement: "Jefferson, Thomas",
              dateNameElement: "1743-1826"                  
            }
          }, 
          "Hemings, Sally"
        ]}
        
        @ds.attributes = values_array
        debugger
        @ds.personalName.should == ["Jefferson, Thomas", "Hemings, Sally"]
        @ds.personalName(0).elementList(0).fullNameElement.should == ["Jefferson, Thomas"]
        @ds.personalName(0).elementList(0).dateNameElement.should == ["1743-1826"]
        @ds.personalName(1).elementList(0).fullNameElement.should == ["Hemings, Sally"]
      end
      
      it "when given a complex Hash should rely on properties to build the graph" do
        values_hash = {
          complexSubject: [{
            componentList: {
              personalName: {
                elementList: {
                  fullNameElement: "Callender, James T.",
                  dateNameElement: "1805" 
                }
              },
              topic: "Presidency", 
              temporal: "1801-1809"
            },
          },
          {
            componentList: {
              personalName: {
                elementList: {
                  fullNameElement: "Hemings, Sally",
                  dateNameElement: "1802" 
                }
              },
              topic: "Slavery"
            }
          }]
        }
        @ds.attributes = values_hash
        @ds.complexSubject(0).componentList(0).personalName.should == ["Callender, James T."]
        @ds.complexSubject(0).componentList(0).personalName(0).elementList(0).fullNameElement.should == ["Callender, James T."]
        @ds.complexSubject(0).componentList(0).personalName(0).elementList(0).dateNameElement.should == ["1805"]
          
        @ds.complexSubject(0).componentList(0).topic.should == ["Presidency"]
        @ds.complexSubject(0).componentList(0).topic(0).elementList(0).topicElement.should ==  ["Presidency"]
        
        @ds.complexSubject(0).componentList(0).temporal.should == ["1801-1809"]
        @ds.complexSubject(0).componentList(0).temporal(0).elementList(0).temporalElement.should ==  ["1801-1809"]
        
        @ds.complexSubject(1).componentList(0).personalName.should == ["Hemings, Sally"]
        @ds.complexSubject(1).componentList(0).personalName(0).elementList(0).fullNameElement.should == ["Hemings, Sally"]
        @ds.complexSubject(1).componentList(0).personalName(0).elementList(0).dateNameElement.should == ["1802"]
        @ds.complexSubject(1).componentList(0).topic.should == ["Slavery"]
      end
    end

end
