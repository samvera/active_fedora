require 'spec_helper'

describe ActiveFedora::Datastream do
  
  let(:parent) { double('inner object', uri: '/fedora/rest/1234', id: '1234', new_record?: true) }

  before(:each) do
    subject.content = "hi there"
  end

  subject { ActiveFedora::Datastream.new(parent, 'abcd') }

  its(:metadata?) { should be_false }

  it "should escape dots in  to_param" do
    subject.stub(:dsid).and_return('foo.bar')
    subject.to_param.should == 'foo%2ebar'
  end
  
  it "should be inspectable" do
    subject.inspect.should eq "#<ActiveFedora::Datastream uri=\"/fedora/rest/1234/abcd\" changed=\"true\" >"
  end

  describe "#generate_dsid" do
    let(:parent) { double('inner object', uri: '/fedora/rest/1234', id: '1234',
                          new_record?: true, datastreams: datastreams) }

    subject {ActiveFedora::Datastream.new(parent, nil, prefix: 'FOO') }

    let(:datastreams) { { } }
    it "should create an autoincrementing dsid" do
      expect(subject.dsid).to eq 'FOO1'
    end

    context "when some datastreams exist" do
      let(:datastreams) { {'FOO56' => double} }

      it "should start from the highest existing dsid" do
        expect(subject.dsid).to eq 'FOO57'
      end
    end
  end

  describe ".size" do
    it "should lazily load the datastream size attribute from the fedora repository" do
      subject.size.should == 9999
    end

    it "should default to nil if ds has not been saved" do
      subject.size.should be_nil
    end
  end
end
