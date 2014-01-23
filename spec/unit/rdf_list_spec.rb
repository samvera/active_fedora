require 'spec_helper'

describe ActiveFedora::Rdf::List do
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
      property :elementList, :predicate => MADS.elementList, :class_name => 'DemoList::List'
      class List < ActiveFedora::Rdf::List
        property :topicElement, :predicate => MADS.TopicElement, :class_name => 'DemoList::List::TopicElement'
        property :temporalElement, :predicate => MADS.TemporalElement, :class_name => 'DemoList::List::TemporalElement'

        class TopicElement < ActiveFedora::Rdf::Resource
          configure :type => MADS.TopicElement
          property :elementValue, :predicate => MADS.elementValue
        end
        class TemporalElement < ActiveFedora::Rdf::Resource
          configure :type => MADS.TemporalElement
          property :elementValue, :predicate => MADS.elementValue
        end
      end
    end
  end
  after(:each) do
    Object.send(:remove_const, :DemoList)
    Object.send(:remove_const, :MADS)
  end

  describe "a new list" do
    let (:ds) { DemoList.new(double('inner object', :pid=>'foo', :new_record? =>true), 'descMetadata')}
    subject { ds.elementList.build}

    it "should insert at the end" do
      subject.should be_kind_of DemoList::List
      subject.size.should == 0
      subject[1] = DemoList::List::TopicElement.new
      subject.size.should == 2
    end

    it "should insert at the head" do
      subject.should be_kind_of DemoList::List
      subject.size.should == 0
      subject[0] = DemoList::List::TopicElement.new
      subject.size.should == 1
    end

    describe "that has 4 elements" do
      before do
        subject[3] = DemoList::List::TopicElement.new
        subject.size.should == 4
      end
      it "should insert in the middle" do
        subject[1] = DemoList::List::TopicElement.new
        subject.size.should == 4
      end
    end

    describe "return updated xml" do
      it "should be built" do
        subject[0] = RDF::URI.new "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
        subject[1] = DemoList::List::TopicElement.new
        subject[1].elementValue = "Relations with Mexican Americans"
        subject[2] = RDF::URI.new "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
        subject[3] = DemoList::List::TemporalElement.new
        subject[3].elementValue = "20th century"
        ds.elementList = subject
        doc = Nokogiri::XML(ds.content)
        ns = {rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#", mads: "http://www.loc.gov/mads/rdf/v1#"}
        expect(doc.xpath('/rdf:RDF/rdf:Description/@rdf:about', ns).map(&:value)).to eq ["info:fedora/foo"]
        expect(doc.xpath('//rdf:Description/mads:elementList/@rdf:parseType', ns).map(&:value)).to eq ["Collection"]
        expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 1]/@rdf:about', ns).map(&:value)).to eq ["http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"]
        expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 2]/mads:elementValue', ns).map(&:text)).to eq ["Relations with Mexican Americans"]
        expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 3]/@rdf:about', ns).map(&:value)).to eq ["http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"]
        expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 4]/mads:elementValue', ns).map(&:text)).to eq ["20th century"]
      end
    end
  end

  describe "an empty list" do
    subject { DemoList.new(double('inner object', :pid=>'foo', :new_record? =>true), 'descMd').elementList.build } 
    it "should have to_ary" do
      subject.to_ary.should == []
    end
  end

  describe "a list that has a constructed element" do
    let(:ds) { DemoList.new(double('inner object', :pid=>'foo', :new_record? =>true), 'descMd') }
    let(:list) { ds.elementList.build } 
    let!(:topic) { list.topicElement.build }

    it "should have to_ary" do
      list.to_ary.size.should == 1
      list.to_ary.first.class.should == DemoList::List::TopicElement
    end

    it "should be able to be cleared" do
      list.topicElement.build
      list.topicElement.build
      list.topicElement.build
      list.size.should == 4
      list.clear
      list.size.should == 0
    end
  end

  describe "a list with content" do
    subject do
      subject = DemoList.new(double('inner object', :pid=>'foo', :new_record? =>true), 'descMetadata')
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
      list.first.rdf_subject.should == "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
      list[1].should be_kind_of DemoList::List::TopicElement
      list[1].elementValue.should == ["Relations with Mexican Americans"]
      list[2].rdf_subject.should == "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
      list[3].should be_kind_of DemoList::List::TemporalElement
      list[3].elementValue.should == ["20th century"]
    end

    it "should have each" do
      foo = []
      list.each { |n| foo << n.class }
      foo.should == [ActiveFedora::Rdf::Resource, DemoList::List::TopicElement, ActiveFedora::Rdf::Resource, DemoList::List::TemporalElement]
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
      doc = Nokogiri::XML(subject.content)
      ns = {rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#", mads: "http://www.loc.gov/mads/rdf/v1#"}
      expect(doc.xpath('/rdf:RDF/mads:ComplexSubject/@rdf:about', ns).map(&:value)).to eq ["info:fedora/foo"]
      expect(doc.xpath('//mads:ComplexSubject/mads:elementList/@rdf:parseType', ns).map(&:value)).to eq ["Collection"]
      expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 1]/@rdf:about', ns).map(&:value)).to eq ["http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"]
      expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 2]/mads:elementValue', ns).map(&:text)).to eq ["Relations with Mexican Americans"]
      expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 3]/@rdf:about', ns).map(&:value)).to eq ["http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"]
      expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 4]/mads:elementValue', ns).map(&:text)).to eq ["1900s"]
    end
  end
end

