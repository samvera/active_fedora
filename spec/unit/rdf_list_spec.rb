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

  subject do
    subject = DemoList.new(stub('inner object', :pid=>'foo', :new? =>true), 'descMetadata')
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
  it "should have fields" do
    list = subject.elementList.first
    list.first.should == "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
    list[1].should be_kind_of DemoList::List::TopicElement
    list[1].elementValue.should == ["Relations with Mexican Americans"]
    list[2].should == "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
    list[3].should be_kind_of DemoList::List::TemporalElement
    list[3].elementValue.should == ["20th century"]
  end

  it "should have size" do
    list = subject.elementList.first
    list.size.should == 4
  end

  it "should update fields" do
    list = subject.elementList.first
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

