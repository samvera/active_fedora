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
          accepts_nested_attributes_for :elementList
        end
        class Temporal
          include ActiveFedora::RdfObject
          def default_write_point_for_values 
            [:elementList, :temporalElement]
          end
          map_predicates do |map|
            map.elementList(in: DummyMADS, class_name:"DummyMADS::ElementList")
          end
          accepts_nested_attributes_for :elementList
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
          accepts_nested_attributes_for :elementList
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
          accepts_nested_attributes_for :elementList
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
          accepts_nested_attributes_for :componentList
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
          accepts_nested_attributes_for :topic, :temporal, :personalName, :corporateName
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
        accepts_nested_attributes_for :topic, :temporal, :personalName, :corporateName, :complexSubject
      end
      @ds = ComplexRDFDatastream.new(stub('inner object', :pid=>'foo', :new? =>true), 'descMetadata')
    end
    after do
      Object.send(:remove_const, :ComplexRDFDatastream)
      Object.send(:remove_const, :DummyMADS)
    end
    subject { @ds } 


    describe "assignment operator `=`" do
      it "should wipe out existing values then append the given values"
    end
    
    describe "insertion operator `<<`" do
      it "when given a Node should simply insert it" do
        pending "TODO: Should this be the behavior?  -MZ 05/2013"
        new_node = RDF::Node.new
        @ds.topic << new_node
        @ds.topic.first.should == new_node
      end
      describe "when given a String" do
        it "should raise an ArgumentError if corresponding property declares a class_name" do
          pending "TODO: Should we be this strict, or just insert literals where they're not expected? -MZ 05/2013"
          lambda{ @ds.topic << "A String Literal" }.should raise_error ArgumentError
        end
        it "should insert the String as a literal if possible" do
          @ds.title << "My Title"
          @ds.title.should == ["My Title"]
        end
      end
      
      it "should build proper rdf graph" do
        @ds.topic.build("Cosmology")
        @ds.topic.build("Quantum States")
        
        # (Grabbing node ids for use in expected_xml assertion)
        list1_id = @ds.topic[0].elementList[0].rdf_subject.id
        list2_id = @ds.topic[1].elementList[0].rdf_subject.id
        
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
    end
    
    describe "build" do
      it "should create a node and insert it" do
        @ds.personalName.count.should == 0
        built_node = @ds.personalName.build 
        @ds.personalName.count.should == 1
        @ds.personalName.first.should == built_node
      end
      
      it "when given an Array should return an Array of built nodes" do
        pending "TODO: Should .build accept arrays (and return an Array of new nodes)?  Would this be useful? - MZ 05/2013"
        attributes_array = [{ 
            elementList: {
              fullNameElement: "Jefferson, Thomas",
              dateNameElement: "1743-1826"                  
            }
          }, 
          "Hemings, Sally"
        ]
        result = @ds.personalName.build(attributes_array)
        result.should be_instance_of Array
        result.length.should == 2
        result.each {|built_node| built_node.should be_instance_of DummyMADS::PersonalName }
        result[0].elementList[0].fullNameElement.should == ["Jefferson, Thomas"]
        result[0].elementList[0].dateNameElement.should == ["1743-1826"]
        result[1].elementList[0].fullNameElement.should == ["Hemings, Sally"]
      end
      
    end
    
    describe "attributes=" do
      
      describe "(called on a Node)" do
      
        it "when given a String should create the necessary node and put the string into its default_write_point_for_values" do
          built_node= @ds.topic.build
          built_node.attributes = "Software Testing"
          # built_node.value.should = ["Software Testing"]
          built_node.should be_instance_of DummyMADS::Topic
          built_node.default_write_point_for_values.should == [:elementList, :topicElement]
          built_node.elementList[0].topicElement.should == ["Software Testing"]
        end
      
        it "when given a Hash should rely on nested_attributes behavior to build nodes" do
          values_hash = { 
            elementList_attributes: {
              fullNameElement: "Jefferson, Thomas",
              dateNameElement: "1743-1826"                  
            }
          }
          built_node = @ds.personalName.build
          built_node.attributes = values_hash
          built_node.should be_instance_of DummyMADS::PersonalName
          built_node.elementList[0].fullNameElement.should == ["Jefferson, Thomas"]
          built_node.elementList[0].dateNameElement.should == ["1743-1826"]
        end
      
      end
      
    
      describe "(called on a datastream)" do
        describe "when given a Hash" do
            it "should use nested attributes behavior" do
              values_hash = {
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
                temporal_attributes: {
                  elementList_attributes: {
                    temporalElement:"16th Century"
                  }
                }
              }
              @ds.attributes = values_hash
              @ds.topic[0].elementList[0].topicElement.should == ["Cosmology"]
              @ds.temporal[0].elementList[0].temporalElement.should == ["16th Century"]
            end
              
            it "should support auto-building of complex sub-nodes" do
              values_hash = {
                topic_attributes: "Cosmology",
                temporal_attributes: "16th Century",
                personalName_attributes: "Hemings, Sally"
              }
              @ds.attributes = values_hash
              # @ds.topic.should == ["Cosmology"]
              # @ds.temporal.should == ["16th Century"]
              # @ds.personalName.values.should == ["Hemings, Sally"]
              @ds.topic[0].elementList[0].topicElement.should == ["Cosmology"]
              @ds.temporal[0].elementList[0].temporalElement.should == ["16th Century"]
              @ds.personalName[0].elementList[0].fullNameElement.should == ["Hemings, Sally"]
            end
        end
        it "when given an Array of values should build a node based on each of the items from the array as a node corresponding to the specified property behavior" do
          values_hash = {
            personalName_attributes:[
            { 
              elementList_attributes: {
                fullNameElement: "Jefferson, Thomas",
                dateNameElement: "1743-1826"                  
              }
            }, 
            "Hemings, Sally"
          ]}
        
          @ds.attributes = values_hash
          debugger
          @ds.personalName.map {|pn| pn.elementList[0].fullNameElement.first }.should == ["Jefferson, Thomas", "Hemings, Sally"]
          @ds.personalName[0].elementList[0].fullNameElement.should == ["Jefferson, Thomas"]
          @ds.personalName[0].elementList[0].dateNameElement.should == ["1743-1826"]
          @ds.personalName[1].elementList[0].fullNameElement.should == ["Hemings, Sally"]
        end
      
        it "when given a complex Hash should recursively call build on sub-properties" do
          values_hash = {
            complexSubject_attributes: [{
              componentList_attributes: {
                personalName_attributes: {
                  elementList_attributes: {
                    fullNameElement: "Callender, James T.",
                    dateNameElement: "1805" 
                  }
                },
                topic_attributes: {
                  elementList_attributes: {
                    topicElement:"Presidency"
                  }
                }, 
                temporal_attributes: "1801-1809"
              },
            },
            {
              componentList_attributes: {
                personalName_attributes: {
                  elementList_attributes: {
                    fullNameElement: "Hemings, Sally",
                    dateNameElement: "1802" 
                  }
                },
                topic_attributes: "Slavery"
              }
            }]
          }
          @ds.attributes = values_hash
          debugger
          # @ds.complexSubject[0].componentList[0].personalName.map {|pn| pn.values.first }.should == ["Callender, James T."]
          @ds.complexSubject[0].componentList[0].personalName[0].elementList[0].fullNameElement.should == ["Callender, James T."]
          @ds.complexSubject[0].componentList[0].personalName[0].elementList[0].dateNameElement.should == ["1805"]
          
          # @ds.complexSubject[0].componentList[0].topic.map {|t| t.value}.should == ["Presidency"]
          @ds.complexSubject[0].componentList[0].topic[0].elementList[0].topicElement.should ==  ["Presidency"]
        
          # @ds.complexSubject[0].componentList[0].temporal.map {|t| t.value}.should == ["1801-1809"]
          @ds.complexSubject[0].componentList[0].temporal[0].elementList[0].temporalElement.should ==  ["1801-1809"]
        
          # @ds.complexSubject[1].componentList[0].personalName.map {|pn| pn.value}.should == ["Hemings, Sally"]
          @ds.complexSubject[1].componentList[0].personalName[0].elementList[0].fullNameElement.should == ["Hemings, Sally"]
          @ds.complexSubject[1].componentList[0].personalName[0].elementList[0].dateNameElement.should == ["1802"]
          @ds.complexSubject[1].componentList[0].topic.first.elementList[0].topicElement.should == ["Slavery"]
        end
      end
    end
    
    

end
