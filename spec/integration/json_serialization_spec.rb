require 'spec_helper'

describe "Objects should be serialized to JSON" do
  it "has json results" do
    expect(ActiveFedora::Base.new.to_json).to eq "{\"id\":null}"
  end

  context "with properties" do
    before do
      class Foo < ActiveFedora::Base
        property :title, predicate: ::RDF::Vocab::DC.title
        property :description, predicate: ::RDF::Vocab::DC.description, multiple: false
      end
    end

    after do
      Object.send(:remove_const, :Foo)
    end

    let(:obj) { Foo.new(title: ['My Title'], description: 'Wonderful stuff') }

    before { allow(obj).to receive(:id).and_return('test-123') }

    let(:json) { JSON.parse(obj.to_json) }

    it "has to_json" do
      expect(json['id']).to eq "test-123"
      expect(json['title']).to eq ["My Title"]
      expect(json['description']).to eq "Wonderful stuff"
    end
  end
end
