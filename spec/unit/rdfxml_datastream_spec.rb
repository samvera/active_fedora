require 'spec_helper'

describe ActiveFedora::RDFXMLDatastream do
  describe "a new instance" do
    before(:each) do
      class MyRdfxmlDatastream < ActiveFedora::RDFXMLDatastream
        property :publisher, predicate: ::RDF::DC.publisher
      end
      @subject = MyRdfxmlDatastream.new
      allow(@subject).to receive(:id).and_return('test:1')
    end

    after(:each) do
      Object.send(:remove_const, :MyRdfxmlDatastream)
    end

    it "should save and reload" do
      @subject.publisher = ["St. Martin's Press"]
      expect(@subject.serialize).to match /<rdf:RDF/
    end
  end

  describe "a complex data model" do
    before do
      class DAMS < RDF::Vocabulary("http://library.ucsd.edu/ontology/dams#")
        property :title
        property :relatedTitle
        property :type
        property :date
        property :beginDate
        property :endDate
        property :language
        property :typeOfResource
        property :otherResource
        property :RelatedResource
        property :description
        property :uri
        property :relationship
        property :Relationship
        property :role
        property :name
        property :assembledCollection
        property :Object
        property :value
      end

      module RDF
        # This enables RDF to respond_to? :value
        def self.value
          self[:value]
        end
      end

      class MyDatastream < ActiveFedora::RDFXMLDatastream
        property :resource_type, predicate: DAMS.typeOfResource
        property :title, predicate: DAMS.title, :class_name => 'Description'

        rdf_subject { |ds| RDF::URI.new(ds.about) }

        attr_accessor :about

        def initialize(options={})
          @about = options.delete(:about)
          super
        end

        class Description < ActiveTriples::Resource
          configure :type => DAMS.Description
          property :value, predicate: ::RDF.value do |index|
              index.as :searchable
          end
        end
      end
    end

    after do
      Object.send(:remove_const, :MyDatastream)
      Object.send(:remove_const, :DAMS)
    end

    describe "a new instance" do
      subject { MyDatastream.new(about: "http://library.ucsd.edu/ark:/20775/") }
      it "should have a subject" do
        expect(subject.rdf_subject.to_s).to eq "http://library.ucsd.edu/ark:/20775/"
      end

    end

    describe "an instance with content" do
      subject do
        subject = MyDatastream.new(about: "http://library.ucsd.edu/ark:/20775/")
        subject.content = File.new('spec/fixtures/damsObjectModel.xml').read
        subject
      end
      it "should have a subject" do
        expect(subject.rdf_subject.to_s).to eq "http://library.ucsd.edu/ark:/20775/"
      end
      it "should have mimeType" do
        expect(subject.mime_type).to eq 'text/xml'
      end
      it "should have fields" do
        expect(subject.resource_type).to eq ["image"]
        expect(subject.title.first.value).to eq ["example title"]
      end
    end
  end
end
