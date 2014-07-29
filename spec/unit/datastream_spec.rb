require 'spec_helper'

describe ActiveFedora::Datastream do
  let(:parent) { double('inner object', uri: '/fedora/rest/test/1234', id: '1234', new_record?: true) }
  let(:datastream) { ActiveFedora::Datastream.new(parent, 'abcd') }

  subject { datastream }

  it { should_not be_metadata }

  describe "to_param" do
    before { allow(subject).to receive(:dsid).and_return('foo.bar') }
    it "should escape dots" do
      expect(subject.to_param).to eq 'foo%2ebar'
    end
  end

  describe "#generate_dsid" do
    let(:parent) { double('inner object', uri: '/fedora/rest/test/1234', id: '1234',
                          new_record?: true, datastreams: datastreams) }

    subject { ActiveFedora::Datastream.new(parent, nil, prefix: 'FOO') }

    let(:datastreams) { { } }

    it "should set the dsid" do
      expect(subject.dsid).to eq 'FOO1'
    end

    it "should set the uri" do
      expect(subject.uri).to eq '/fedora/rest/test/1234/FOO1'
    end

    context "when some datastreams exist" do
      let(:datastreams) { {'FOO56' => double} }

      it "should start from the highest existing dsid" do
        expect(subject.dsid).to eq 'FOO57'
      end
    end
  end

  describe ".size" do
    before do
      subject.orm.graph.insert([RDF::URI.new(subject.content_path), RDF::URI.new("http://www.loc.gov/premis/rdf/v1#hasSize"), RDF::Literal.new(9999) ])
    end
    it "should load the datastream size attribute from the fedora repository" do
      expect(subject.size).to eq 9999
    end
  end

  context "has content" do

    before do
      datastream.content = "hi there"
    end

    it "should have content" do
      expect(subject).to have_content
    end

    describe "#inspect" do
      subject { datastream.inspect }
      it { should eq "#<ActiveFedora::Datastream uri=\"/fedora/rest/test/1234/abcd\" changed=\"true\" >" }
    end
  end

  context "does not have local content" do
    it { should_not have_content }

    describe "#has_content?" do
      context "when the graph has content" do
        before do
          subject.has_content = RDF::URI.new(subject.content_path)
        end
        it { should have_content }
      end
    end
  end

  context "original_name" do
    subject { datastream.original_name }

    context "on a new datastream" do
      before { datastream.original_name = "my_image.png" }
      it { should eq "my_image.png" }
    end

    context "when it's saved" do
      let(:parent) { ActiveFedora::Base.create }
      before do
        parent.add_file_datastream('one1two2threfour', dsid: 'abcd', mime_type: 'video/webm', original_name: "my_image.png")
        parent.save!
      end

      it "should have original_name" do
        expect(parent.reload.abcd.original_name).to eq 'my_image.png'
      end
    end
  end
end
