require 'spec_helper'

describe ActiveFedora::RdfList do
  before :each do
    class MADS < RDF::Vocabulary('http://www.loc.gov/mads/rdf/v1#')
      property :complexSubject
      property :authoritativeLabel
      property :elementList
      property :elementValue
      property :TopicElement
      property :TemporalElement
    end
    class DemoList < ActiveFedora::RdfxmlRDFDatastream
      map_predicates do |map|
        map.elementList(:in => MADS, :to => 'elementList', :class_name => 'List')
      end
      class List
        include ActiveFedora::RdfList
        map_predicates do |map|
          map.topicElement(:in => MADS, :to => 'TopicElement', :class_name => 'TopicElement')
          map.temporalElement(:in => MADS, :to => 'TemporalElement', :class_name => 'TemporalElement')
        end

        class TopicElement
          include ActiveFedora::RdfObject
          rdf_type MADS.TopicElement
          map_predicates do |map|
            map.elementValue(:in => MADS)
          end
        end
        class TemporalElement
          include ActiveFedora::RdfObject
          rdf_type MADS.TemporalElement
          map_predicates do |map|
            map.elementValue(:in => MADS)
          end
        end
      end
    end
  end
  after(:each) do
    Object.send(:remove_const, :DemoList)
    Object.send(:remove_const, :MADS)
  end

  describe 'a new list' do
    let (:ds) { DemoList.new(double('inner object', :pid => 'foo', :new_record? => true), 'descMetadata')}
    subject { ds.elementList.build}

    it 'should insert at the end' do
      expect(subject).to be_kind_of DemoList::List
      expect(subject.size).to eq(0)
      subject[1] = DemoList::List::TopicElement.new(subject.graph)
      expect(subject.size).to eq(2)
    end

    it 'should insert at the head' do
      expect(subject).to be_kind_of DemoList::List
      expect(subject.size).to eq(0)
      subject[0] = DemoList::List::TopicElement.new(subject.graph)
      expect(subject.size).to eq(1)
    end

    describe 'that has 4 elements' do
      before do
        subject[3] = DemoList::List::TopicElement.new(subject.graph)
        expect(subject.size).to eq(4)
      end
      it 'should insert in the middle' do
        subject[1] = DemoList::List::TopicElement.new(subject.graph)
        expect(subject.size).to eq(4)
      end
    end

    describe 'return updated xml' do
      it 'should be built' do
        subject[0] = RDF::URI.new 'http://library.ucsd.edu/ark:/20775/bbXXXXXXX6'
        subject[1] = DemoList::List::TopicElement.new(ds.graph)
        subject[1].elementValue = 'Relations with Mexican Americans'
        subject[2] = RDF::URI.new 'http://library.ucsd.edu/ark:/20775/bbXXXXXXX4'
        subject[3] = DemoList::List::TemporalElement.new(ds.graph)
        subject[3].elementValue = '20th century'
        expected_xml = <<END
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
        expect(ds.content).to be_equivalent_to expected_xml
      end
    end


  end

  describe 'an empty list' do
    subject { DemoList.new(double('inner object', :pid => 'foo', :new_record? => true)).elementList.build }
    it 'should have to_ary' do
      expect(subject.to_ary).to eq([])
    end
  end

  describe 'a list that has a constructed element' do
    let(:ds) { DemoList.new(double('inner object', :pid => 'foo', :new_record? => true)) }
    let(:list) { ds.elementList.build }
    let!(:topic) { list.topicElement.build }

    it 'should have to_ary' do
      expect(list.to_ary.size).to eq(1)
      expect(list.to_ary.first.class).to eq(DemoList::List::TopicElement)
    end

    it 'should be able to be cleared' do
      list.topicElement.build
      list.topicElement.build
      list.topicElement.build
      expect(list.size).to eq(4)
      list.clear
      expect(list.size).to eq(0)
    end
  end

  describe 'a list with content' do
    subject do
      subject = DemoList.new(double('inner object', :pid => 'foo', :new_record? => true), 'descMetadata')
      subject.content = <<END
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
    it 'should have a subject' do
      expect(subject.rdf_subject.to_s).to eq('info:fedora/foo')
    end

    let (:list) { subject.elementList.first }

    it 'should have fields' do
      expect(list.first).to eq('http://library.ucsd.edu/ark:/20775/bbXXXXXXX6')
      expect(list[1]).to be_kind_of DemoList::List::TopicElement
      expect(list[1].elementValue).to eq(['Relations with Mexican Americans'])
      expect(list[2]).to eq('http://library.ucsd.edu/ark:/20775/bbXXXXXXX4')
      expect(list[3]).to be_kind_of DemoList::List::TemporalElement
      expect(list[3].elementValue).to eq(['20th century'])
    end

    it 'should have each' do
      foo = []
      list.each { |n| foo << n.class }
      expect(foo).to eq([RDF::URI, DemoList::List::TopicElement, RDF::URI, DemoList::List::TemporalElement])
    end

    it 'should have to_ary' do
      ary = list.to_ary
      expect(ary.size).to eq(4)
      expect(ary[1].elementValue).to eq(['Relations with Mexican Americans'])
    end

    it 'should have size' do
      expect(list.size).to eq(4)
    end

    it 'should update fields' do
      list[3].elementValue = ['1900s']
      expected_xml = <<END
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
      expect(subject.content).to be_equivalent_to expected_xml
    end
  end
end
