require 'spec_helper'

describe ActiveFedora::Rdf::List do
  before :each do
    class MADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
      property :MADSScheme
      property :isMemberOfMADSScheme
      property :authoritativeLabel
      property :elementList
      property :elementValue
      property :Topic
      property :TopicElement
      property :TemporalElement
      property :hasExactExternalAuthority
    end

    class TopicElement < ActiveFedora::Rdf::Resource
      configure :type => MADS.TopicElement
      property :elementValue, :predicate => MADS.elementValue
    end
    class TemporalElement < ActiveFedora::Rdf::Resource
      configure :type => MADS.TemporalElement
      property :elementValue, :predicate => MADS.elementValue
    end
    class ElementList < ActiveFedora::Rdf::List
      property :topicElement, :predicate => MADS.TopicElement, :class_name => 'TopicElement'
      property :temporalElement, :predicate => MADS.TemporalElement, :class_name => 'TemporalElement'
      accepts_nested_attributes_for :topicElement, :temporalElement
    end

    class Topic < ActiveFedora::Rdf::Resource
      configure :type => MADS.Topic
      configure :base_uri => "http://example.org/id_namespace#"
      property :name, :predicate => MADS.authoritativeLabel
      property :elementList, :predicate => MADS.elementList, :class_name => 'ElementList'
      property :externalAuthority, :predicate => MADS.hasExactExternalAuthority

      accepts_nested_attributes_for :elementList
    end
  end
  after(:each) do
    Object.send(:remove_const, :Topic)
    Object.send(:remove_const, :ElementList)
    Object.send(:remove_const, :TopicElement)
    Object.send(:remove_const, :TemporalElement)
    Object.send(:remove_const, :MADS)
  end

  describe "nested_attributes" do
    it "should insert new nodes into RdfLists (rather than calling .build)" do
      params = {
        topic: {
          name: "Baseball",
          externalAuthority: "http://id.loc.gov/authorities/subjects/sh85012026",
          elementList_attributes: [
            topicElement_attributes: [{ elementValue: "Baseball" }, elementValue: "Football"],
          ]
        }
      }

      topic = Topic.new
      topic.attributes = params[:topic]
      topic.elementList.first.size.should == 2
      topic.elementList.first[0].should be_kind_of(TopicElement)
      topic.elementList.first[0].elementValue.should == ["Baseball"]
      topic.elementList.first[1].should be_kind_of(TopicElement)
      topic.elementList.first[1].elementValue.should == ["Football"]

      # only one rdf:rest rdf:nil
      topic.query([nil, RDF.rest, RDF.nil]).size.should == 1
    end
    it "should insert new nodes of varying types into RdfLists (rather than calling .build)" do
      # It's Not clear what the syntax should be when an RDF list contains multiple types of sub-nodes.
      # This is a guess, which currently works.
      params = {
        topic: {
          name: "Baseball",
          externalAuthority: "http://id.loc.gov/authorities/subjects/sh85012026",
          elementList_attributes: [
            topicElement_attributes: [{ elementValue: "Baseball" }, elementValue: "Football"],
            temporalElement_attributes: [{elementValue: "1960"}, {elementValue:"Twentieth Century"}],
          ]
        }
      }

      topic = Topic.new
      topic.attributes = params[:topic]
      topic.elementList.first.size.should == 4
      topic.elementList.first[0].should be_kind_of(TopicElement)
      topic.elementList.first[0].elementValue.should == ["Baseball"]
      topic.elementList.first[1].should be_kind_of(TopicElement)
      topic.elementList.first[1].elementValue.should == ["Football"]
      topic.elementList.first[2].should be_kind_of(TemporalElement)
      topic.elementList.first[2].elementValue.should == ["1960"]
      topic.elementList.first[3].should be_kind_of(TemporalElement)
      topic.elementList.first[3].elementValue.should == ["Twentieth Century"]
    end
  end
end
