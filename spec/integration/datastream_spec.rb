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

    after(:all) do
      Object.send(:remove_const, :MockAFBase)
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
    
    context "a blob datastream" do
      let(:dsid) { "ds#{Time.now.to_i}" }
      let(:content) { fixture('dino.jpg') }
      let(:datastream) { ActiveFedora::Datastream.new(test_object, dsid).tap { |ds| ds.content = content } }

      before do
        test_object.add_datastream(datastream)
        test_object.save
      end

      it "should not be changed" do
        expect(test_object.datastreams[dsid]).to_not be_changed
      end

      it "should be able to read the content from fedora" do    
        content.rewind
        expect(test_object.datastreams[dsid].content).to eq content.read
      end

      describe "streaming the response" do
        let(:stream_reader) { double }
        it "should stream the response" do
          expect(stream_reader).to receive(:read).at_least(:once)
          test_object.datastreams[dsid].stream { |buff| stream_reader.read(buff) }
        end

        context "with a range request" do
          before do
            test_object.add_file_datastream('one1two2threfour', dsid: 'webm', mime_type: 'video/webm')
            test_object.save!
          end
          subject { str = ''; test_object.webm.stream(range) {|chunk| str << chunk }; str }
          context "whole thing" do
            let(:range) { 'bytes=0-15' }
            it { should eq 'one1two2threfour'}
          end
          context "open ended" do
            let(:range) { 'bytes=0-' }
            it "should get a response" do
              expect(subject).to eq 'one1two2threfour'
            end
          end
          context "not starting at the beginning" do
            let(:range) { 'bytes=3-15' }
            it { should eq '1two2threfour'}
          end
          context "not ending at the end" do
            let(:range) { 'bytes=4-11' }
            it { should eq 'two2thre'}
          end
        end
      end
    end
  end
end
