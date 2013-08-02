require 'spec_helper'

describe ActiveFedora::RdfList do
  before :each do
    class MADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
      property :complexSubject
      property :authoritativeLabel
      property :elementList
      property :elementValue
      property :TopicElement
      property :TemporalElement
    end
    class DemoList < ActiveFedora::RdfxmlRDFDatastream
      map_predicates do |map|
        map.elementList(:in => MADS, :to => 'elementList', :class_name=>'List')
      end 
      class List 
        include ActiveFedora::RdfList
        map_predicates do |map|
          map.topicElement(:in=> MADS, :to =>"TopicElement", :class_name => "TopicElement")
          map.temporalElement(:in=> MADS, :to =>"TemporalElement", :class_name => "TemporalElement")
        end
          
        class TopicElement
          include ActiveFedora::RdfObject
          rdf_type MADS.TopicElement
          map_predicates do |map|   
            map.elementValue(:in=> MADS)
          end
        end
        class TemporalElement
          include ActiveFedora::RdfObject
          rdf_type MADS.TemporalElement
          map_predicates do |map|   
            map.elementValue(:in=> MADS)
          end
        end
      end
    end
  end
  after(:each) do
    Object.send(:remove_const, :DemoList)
    Object.send(:remove_const, :MADS)
  end

  describe "a new list" do
    let (:ds) { DemoList.new(double('inner object', :pid=>'foo', :new? =>true), 'descMetadata')}
    subject { ds.elementList.build}

    it "should insert at the end" do
      subject.should be_kind_of DemoList::List
      subject.size.should == 0
      subject[1] = DemoList::List::TopicElement.new(subject.graph)
      subject.size.should == 2
    end

    it "should insert at the head" do
      subject.should be_kind_of DemoList::List
      subject.size.should == 0
      subject[0] = DemoList::List::TopicElement.new(subject.graph)
      subject.size.should == 1
    end

    describe "that has 4 elements" do
      before do
        subject[3] = DemoList::List::TopicElement.new(subject.graph)
        subject.size.should == 4
      end
      it "should insert in the middle" do
        subject[1] = DemoList::List::TopicElement.new(subject.graph)
        subject.size.should == 4
      end
    end

    describe "return updated xml" do
      it "should be built" do
        subject[0] = RDF::URI.new "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
        subject[1] = DemoList::List::TopicElement.new(ds.graph)
        subject[1].elementValue = "Relations with Mexican Americans"
        subject[2] = RDF::URI.new "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
        subject[3] = DemoList::List::TemporalElement.new(ds.graph)
        subject[3].elementValue = "20th century"
        expected_xml =<<END
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:mads="http://www.loc.gov/mads/rdf/v1#">
      
        <rdf:Description rdf:about="info:fedora/foo">
          <mads:elementList rdf:parseType="Collection">
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"/>
            <mads:TopicElement>
              <mads:elementValue>Relations with Mexican Americans</mads:elementValue>
            </mads:TopicElement>
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"/>
            <mads:TemporalElement>
              <mads:elementValue>20th century</mads:elementValue>
            </mads:TemporalElement>
          </mads:elementList>
        </rdf:Description>
      </rdf:RDF>
END
        ds.content.should be_equivalent_to expected_xml
      end
    end


  end

  describe "an empty list" do
    subject { DemoList.new(double('inner object', :pid=>'foo', :new? =>true)).elementList.build } 
    it "should have to_ary" do
      subject.to_ary.should == []
    end
  end

  describe "a list that has a constructed element" do
    let(:ds) { DemoList.new(double('inner object', :pid=>'foo', :new? =>true)) }
    let(:list) { ds.elementList.build } 
    let!(:topic) { list.topicElement.build }
    
    it "should have to_ary" do
      list.to_ary.size.should == 1
      list.to_ary.first.class.should == DemoList::List::TopicElement
    end
  end

  describe "a list with content" do
    subject do
      subject = DemoList.new(double('inner object', :pid=>'foo', :new? =>true), 'descMetadata')
      subject.content =<<END
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:mads="http://www.loc.gov/mads/rdf/v1#">
      
        <mads:ComplexSubject rdf:about="info:fedora/foo">
          <mads:elementList rdf:parseType="Collection">
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"/>
            <mads:TopicElement>
              <mads:elementValue>Relations with Mexican Americans</mads:elementValue>
            </mads:TopicElement>
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"/>
            <mads:TemporalElement>
              <mads:elementValue>20th century</mads:elementValue>
            </mads:TemporalElement>
          </mads:elementList>
        </mads:ComplexSubject>
      </rdf:RDF>
END

      subject
    end
    it "should have a subject" do
      subject.rdf_subject.to_s.should == "info:fedora/foo"
    end

    let (:list) { subject.elementList.first }

    it "should have fields" do
      list.first.should == "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
      list[1].should be_kind_of DemoList::List::TopicElement
      list[1].elementValue.should == ["Relations with Mexican Americans"]
      list[2].should == "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
      list[3].should be_kind_of DemoList::List::TemporalElement
      list[3].elementValue.should == ["20th century"]
    end

    it "should have each" do
      foo = []
      list.each { |n| foo << n.class }
      foo.should == [RDF::URI, DemoList::List::TopicElement, RDF::URI, DemoList::List::TemporalElement]
    end

    it "should have to_ary" do
      ary = list.to_ary
      ary.size.should == 4
      ary[1].elementValue.should == ['Relations with Mexican Americans']
    end

    it "should have size" do
      list.size.should == 4
    end

    it "should update fields" do
      list[3].elementValue = ["1900s"]
      expected_xml =<<END
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:mads="http://www.loc.gov/mads/rdf/v1#">
      
        <mads:ComplexSubject rdf:about="info:fedora/foo">
          <mads:elementList rdf:parseType="Collection">
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"/>
            <mads:TopicElement>
              <mads:elementValue>Relations with Mexican Americans</mads:elementValue>
            </mads:TopicElement>
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"/>
            <mads:TemporalElement>
              <mads:elementValue>1900s</mads:elementValue>
            </mads:TemporalElement>
          </mads:elementList>
        </mads:ComplexSubject>
      </rdf:RDF>

END
      subject.content.should be_equivalent_to expected_xml
    end
  end
end

