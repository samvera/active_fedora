require 'spec_helper'

describe "Nesting attribute behavior of RDF resources" do
  before do
    class DummyMADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
      property :Topic
    end

    class ComplexResource < ActiveFedora::Base
      property :topic, predicate: DummyMADS.Topic, class_name: "ComplexResource::Topic"

      class Topic < ActiveTriples::Resource
        property :subject, predicate: ::RDF::DC.subject
      end
    end
  end

  after do
    Object.send(:remove_const, :ComplexResource)
    Object.send(:remove_const, :DummyMADS)
  end

  subject { ComplexResource.new }

  let(:params) { [{ subject: 'Foo' }, { subject: 'Bar' }] }

  before do
    ComplexResource.accepts_nested_attributes_for *args
    subject.topic_attributes = params
  end

  context "when no options are set" do
    let(:args) { [:topic] }

    it "should set the attributes" do
      expect(subject.topic.size).to eq 2
      expect(subject.topic.map(&:subject)).to eq [['Foo'], ['Bar']]
    end

    it "should mark the attributes as changed" do
      expect(subject.changed_attributes).to eq('topic' => [])
    end
  end

  context "when reject_if is set" do
    let(:args) { [:topic, reject_if: reject_proc] }
    let(:reject_proc) { lambda { |attributes| attributes[:subject] == 'Bar' } }
    let(:params) { [{ subject: 'Foo' }, { subject: 'Bar' }] }

    it "should not add terms for which the proc is true" do
      expect(subject.topic.map(&:subject)).to eq [['Foo']]
    end
  end

end
