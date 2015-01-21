require 'spec_helper'

describe ActiveFedora::SolrInstanceLoader do
  before do
    class Foo < ActiveFedora::Base
      has_metadata 'descMetadata', type: ActiveFedora::SimpleDatastream do |m|
        m.field "foo", :text
        m.field "bar", :text
      end
      has_attributes :foo, datastream: 'descMetadata', multiple: true
      has_attributes :bar, datastream: 'descMetadata', multiple: false
      property :title, predicate: ::RDF::DC.title, multiple: false
      property :description, predicate: ::RDF::DC.description
      belongs_to :another, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'Foo'
    end
  end

  let(:another) { Foo.create }

  let!(:obj) { Foo.create!(id: 'test-123', foo: ["baz"], bar: 'quix', title: 'My Title',
                           description: ['first desc', 'second desc'], another_id: another.id) }

  after do
    Object.send(:remove_const, :Foo)
  end

  context "without a solr doc" do
    subject { loader.object }

    context "with context" do
      let(:loader) { ActiveFedora::SolrInstanceLoader.new(Foo, obj.id) }

      it "should find the document in solr" do
        expect(subject).to be_instance_of Foo
        expect(subject.title).to eq 'My Title'
        expect(subject.description).to match_array ['first desc', 'second desc']
        expect(subject.another_id).to eq another.id
        expect(subject.bar).to eq 'quix'
      end

      it "should not be mutable" do
        expect { subject.title = 'Foo' }.to raise_error ActiveFedora::ReadOnlyRecord
      end
    end

    context "without context" do
      let(:loader) { ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, obj.id) }

      it "should find the document in solr" do
        expect_any_instance_of(ActiveFedora::Datastream).to_not receive(:retrieve_content)
        expect_any_instance_of(Ldp::Client).to_not receive(:get)
        object = loader.object
        expect(object).to be_instance_of Foo
        expect(object.title).to eq 'My Title' # object assertion
        expect(object.foo).to eq ['baz'] # datastream assertion

        # and it's frozen
        expect { object.title = 'changed' }.to raise_error ActiveFedora::ReadOnlyRecord
        expect(object.title).to eq 'My Title'

        expect { object.foo = ['changed'] }.to raise_error ActiveFedora::ReadOnlyRecord
        expect(object.foo).to eq ['baz']
      end
    end

    context "with children" do
      let(:loader) { ActiveFedora::SolrInstanceLoader.new(Foo, obj.id) }

      it "should have stub implementation of the children" do
        expect(subject.descMetadata).to be_kind_of ActiveFedora::LoadableFromJson::SolrBackedMetadataFile
      end
    end
  end

  context "with a solr doc" do
    let(:profile) { { "foo"=>["baz"], "bar"=>"quix", "title"=>"My Title"}.to_json }
    let(:doc) { { 'id' => 'test-123', 'has_model_ssim'=>['Foo'], 'object_profile_ssm' => profile } }
    let(:loader) { ActiveFedora::SolrInstanceLoader.new(Foo, obj.id, doc) }

    subject { loader.object }

    it "should find the document in solr" do
      expect(subject).to be_instance_of Foo
      expect(subject.title).to eq 'My Title'
    end
  end

  context "when the model has extra values in its json" do
    let(:profile) { { "foo"=>["baz"], "bar"=>"quix", "title"=>"My Title", "extra_value"=>"Bonus values!"}.to_json }
    let(:doc) { { 'id' => 'test-123', 'has_model_ssim'=>['Foo'], 'object_profile_ssm' => profile } }
    let(:loader) { ActiveFedora::SolrInstanceLoader.new(Foo, obj.id, doc) }
    it "should load the object without trouble" do
      expect(loader.object).to be_instance_of Foo
    end
  end
end
