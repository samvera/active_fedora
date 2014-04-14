require 'spec_helper'

describe ActiveFedora::Datastream do
  
  let (:test_object) { ActiveFedora::Base.create }

  before(:each) do
    subject.content = "hi there"
  end

  subject { ActiveFedora::Datastream.new(test_object, 'abcd') }

  its(:metadata?) { should be_false }

  it "should escape dots in  to_param" do
    subject.stub(:dsid).and_return('foo.bar')
    subject.to_param.should == 'foo%2ebar'
  end
  
  it "should be inspectable" do
    subject.inspect.should match /#<ActiveFedora::Datastream @pid=\"\" @dsid=\"abcd\" changed=\"true\" @mimeType=\"\" >/
  end

  it "should have mimeType accessors" do
    subject.mimeType = "text/foo"
    subject.mimeType.should == "text/foo"
  end

  describe "#generate_dsid" do
    subject {ActiveFedora::Datastream.new(test_object) }
    let(:digital_object) { double(datastreams: {})}
    it "should create an autoincrementing dsid" do
      subject.send(:generate_dsid, digital_object, 'FOO').should == 'FOO1'
    end

    describe "when some datastreams exist" do
      let(:digital_object) { double(datastreams: {'FOO56' => double})}
      it "should start from the highest existing dsid" do
        subject.send(:generate_dsid, digital_object, 'FOO').should == 'FOO57'
      end
    end
  end

  describe ".size" do
    it "should lazily load the datastream size attribute from the fedora repository" do
      #TODO need to stub something out
      subject.size.should == 9999
    end

    it "should default to an empty string if ds has not been saved" do
      subject.size.should be_nil
    end
  end
end
