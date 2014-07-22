require 'spec_helper'

require 'active_fedora'
require "rexml/document"

describe ActiveFedora::Datastream do

  context "when autocreate is true" do
    before(:all) do
      class MockAFBase < ActiveFedora::Base
        has_metadata "descMetadata", type: ActiveFedora::QualifiedDublinCoreDatastream, autocreate: true
      end
    end
  
    let(:test_object) { MockAFBase.create }
    
    after do
      test_object.destroy
    end

    let(:descMetadata) {  test_object.datastreams["descMetadata"] }

    describe "the datastream" do
      subject { descMetadata }
      it { should be_a_kind_of(ActiveFedora::Datastream) }
    end

    describe "dsid" do
      subject { descMetadata.dsid }
      it { should eql("descMetadata") }
    end

    describe "#content" do
      subject { descMetadata.content }
      it { should_not be_nil }
    end
    

    context "an XML datastream" do
      let(:xml_content) { Nokogiri::XML::Document.parse(descMetadata.content) }
      let(:title) { Nokogiri::XML::Element.new "title", xml_content }
      before do 
        title.content = "Test Title"
        xml_content.root.add_child title
        
        allow(descMetadata).to receive(:before_save)
        descMetadata.content = xml_content.to_s
        descMetadata.save
      end

      let(:found) { Nokogiri::XML::Document.parse(test_object.reload.descMetadata.content) }

      subject { found.xpath('//dc/title/text()').first.inner_text }
      it { should eq title.content }
    end
    
    context "an Blob datastream" do
      let(:dsid) { "ds#{Time.now.to_i}" }
      let(:content) { fixture('dino.jpg') }
      # let(:content) { StringIO.new("ONETWOTHREE") }
      let(:datastream) { ActiveFedora::Datastream.new(test_object, dsid).tap { |ds| ds.content = content } }

      it "should be able to update Blob Datastream content and save to Fedora" do    
        expect(test_object.add_datastream(datastream)).to eq dsid
        test_object.save
        expect(test_object.datastreams[dsid]).to_not be_changed
        expect(test_object.reload).to_not be_nil 
        expect(test_object.datastreams[dsid]).to_not be_nil
        content.rewind
        expect(test_object.datastreams[dsid].content).to eq content.read
      end
    end
    
  end
end
