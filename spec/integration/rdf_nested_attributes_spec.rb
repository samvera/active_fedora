require 'spec_helper'

describe "Nesting attribute behavior of RDF resources" do
  before do
    class DummyMADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
      property :Topic
      property :Name
      property :Source
    end

    class CustomName < ActiveFedora::Base
      property :pref_label, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple: false
    end

    class CustomSource < ActiveFedora::Base
    end

    class ComplexResource < ActiveFedora::Base
      property :topic, predicate: DummyMADS.Topic, class_name: "ComplexResource::Topic"
      property :name, predicate: DummyMADS.Name, class_name: "CustomName" do |index|
        index.as :stored_searchable, using: :pref_label
      end
      property :source, predicate: DummyMADS.Source, class_name: "CustomSource" do |index|
        index.as :stored_searchable
      end

      class Topic < ActiveTriples::Resource
        property :subject, predicate: ::RDF::Vocab::DC.subject
      end
    end
  end

  after do
    Object.send(:remove_const, :ComplexResource)
    Object.send(:remove_const, :DummyMADS)
    Object.send(:remove_const, :CustomName)
    Object.send(:remove_const, :CustomSource)
  end

  context "with an AT resource as a property" do
    subject(:complex_resource) { ComplexResource.new }

    let(:params) { [{ subject: 'Foo' }, { subject: 'Bar' }] }

    before do
      ComplexResource.accepts_nested_attributes_for(*args)
      complex_resource.topic_attributes = params
    end

    context "when no options are set" do
      let(:args) { [:topic] }

      it "sets the attributes" do
        expect(complex_resource.topic.size).to eq 2
        expect(complex_resource.topic.map(&:subject)).to contain_exactly ['Foo'], ['Bar']
      end

      it "marks the attributes as changed" do
        expect(complex_resource.changed_attributes.keys).to eq ["topic"]
      end
    end

    context "when reject_if is set" do
      let(:args) { [:topic, reject_if: reject_proc] }
      let(:reject_proc) { lambda { |attributes| attributes[:subject] == 'Bar' } }
      let(:params) { [{ subject: 'Foo' }, { subject: 'Bar' }] }

      it "does not add terms for which the proc is true" do
        expect(complex_resource.topic.map(&:subject)).to eq [['Foo']]
      end
    end
  end

  context "with an AF::Base object as a property" do
    describe "#to_solr" do
      let(:name) { CustomName.create(pref_label: "Joe Schmo") }
      let(:source) { CustomSource.create }
      let(:solr_doc) { ComplexResource.new(name: [name], source: [source]).to_solr }
      it "indexes the value of the properties accordingly" do
        expect(solr_doc).to include("name_tesim" => ["Joe Schmo"])
        expect(solr_doc).to include("source_tesim" => [source.uri])
      end
    end
  end
end
