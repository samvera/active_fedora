require 'spec_helper'

describe "Objects should be serialized to JSON" do
  it "should have json results" do
    ActiveFedora::Base.new.to_json.should == "{\"id\":null}"
  end

  describe "with a more interesting model" do
    before do
      class Foo < ActiveFedora::Base
        has_metadata 'descMetadata', type: ActiveFedora::SimpleDatastream do |m|
          m.field "foo", :text
          m.field "bar", :text
        end
        has_attributes :foo, datastream: 'descMetadata', multiple: true
        has_attributes :bar, datastream: 'descMetadata', multiple: false
      end
    end
    after do
      Object.send(:remove_const, :Foo)
    end
    subject { Foo.new(foo: "baz", bar: 'quix') }
    before { subject.stub(pid: 'test:123') }
    it "should have to_json" do
      json = JSON.parse(subject.to_json)
      expect(json['id']).to eq "test:123"
      expect(json['foo']).to eq ["baz"]
      expect(json['bar']).to eq "quix"
    end
  end
end
