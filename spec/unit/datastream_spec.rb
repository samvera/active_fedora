require 'spec_helper'

describe ActiveFedora::Datastream do
  let(:parent) { double('inner object', uri: '/fedora/rest/test/1234', id: '1234', new_record?: true) }

  subject { ActiveFedora::Datastream.new(parent, 'abcd') }

  context "has content" do

    before do
      subject.content = "hi there"
    end

    its(:metadata?) { should be_false }

    it "should escape dots in  to_param" do
      subject.stub(:dsid).and_return('foo.bar')
      subject.to_param.should == 'foo%2ebar'
    end

    it "should have content" do
      expect(subject.has_content?).to be_true
    end

    it "should be inspectable" do
      subject.inspect.should eq "#<ActiveFedora::Datastream uri=\"/fedora/rest/test/1234/abcd\" changed=\"true\" >"
    end

    describe "#generate_dsid" do
      let(:parent) { double('inner object', uri: '/fedora/rest/test/1234', id: '1234',
                            new_record?: true, datastreams: datastreams) }

      subject { ActiveFedora::Datastream.new(parent, nil, prefix: 'FOO') }

      let(:datastreams) { { } }

      its(:dsid) {should eq 'FOO1'}
      its(:uri) {should eq '/fedora/rest/test/1234/FOO1'}

      context "when some datastreams exist" do
        let(:datastreams) { {'FOO56' => double} }

        it "should start from the highest existing dsid" do
          expect(subject.dsid).to eq 'FOO57'
        end
      end
    end

    describe ".size" do
      context "when the graph has a size" do
        before do
          subject.orm.graph.insert([RDF::URI.new(subject.content_path), RDF::URI.new("http://www.loc.gov/premis/rdf/v1#hasSize"), RDF::Literal.new(9999) ])
        end
        it "should load the datastream size attribute from the fedora repository" do
          subject.size.should == 9999
        end
      end
    end
  end

  context "does not have local content" do
    it "should have content" do
      expect(subject.has_content?).to be_false
    end
    describe ".has_content?" do
      context "when the graph has content" do
        before do
          subject.has_content = RDF::URI.new(subject.content_path)
        end
        it "should load the hasContent attribute from the fedora repository" do

          expect(subject.has_content?).to be_true
        end
      end
    end
  end
end
