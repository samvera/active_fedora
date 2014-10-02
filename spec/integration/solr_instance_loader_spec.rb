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
      property :title, predicate: RDF::DC.title
    end
  end

  let!(:obj) { Foo.create!(pid: 'test-123', foo: ["baz"], bar: 'quix', title: ['My Title']) }

  after do
    # obj.destroy
    Object.send(:remove_const, :Foo)
  end


  context "without a solr doc" do
    subject { loader.object }

    context "with context" do
      let(:loader) { ActiveFedora::SolrInstanceLoader.new(Foo, obj.pid) }

      it "should find the document in solr" do
        expect(subject).to be_instance_of Foo
        expect(subject.title).to eq ['My Title']
      end
    end

    context "without context" do
      let(:loader) { ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, obj.pid) }

      it "should find the document in solr" do
        expect_any_instance_of(ActiveFedora::Datastream).to_not receive(:retrieve_content)
        expect_any_instance_of(Ldp::Client).to_not receive(:get)
        object = loader.object
        expect(object).to be_instance_of Foo
        expect(object.title).to eq ['My Title'] # object assertion
        expect(object.foo).to eq ['baz'] # datastream assertion

        # and it's frozen
        expect { object.title = ['changed'] }.to raise_error RuntimeError, "can't modify frozen Hash"
        expect(object.title).to eq ['My Title']

        expect { object.foo = ['changed'] }.to raise_error RuntimeError, "can't modify frozen Hash"
        expect(object.foo).to eq ['baz']
      end
    end
  end

  context "with a solr doc" do
    let(:profile) { { "foo"=>["baz"], "bar"=>"quix", "title"=>["My Title"]}.to_json }
    let(:doc) { { 'id' => 'test-123', 'has_model_ssim'=>['Foo'], 'object_profile_ssm' => profile } }
    let(:loader) { ActiveFedora::SolrInstanceLoader.new(Foo, obj.pid, doc) }

    subject { loader.object }

    it "should find the document in solr" do
      expect(subject).to be_instance_of Foo
      expect(subject.title).to eq ['My Title']
    end
  end
end
