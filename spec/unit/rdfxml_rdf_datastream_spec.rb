require 'spec_helper'

describe ActiveFedora::RdfxmlRDFDatastream do
  describe "a new instance" do
    before(:each) do
      class MyRdfxmlDatastream < ActiveFedora::RdfxmlRDFDatastream
        property :publisher, :predicate => RDF::DC.publisher
      end
      @subject = MyRdfxmlDatastream.new(@inner_object, 'mixed_rdf')
      @subject.stub(:pid => 'test:1')
    end
    after(:each) do
      Object.send(:remove_const, :MyRdfxmlDatastream)
    end
    it "should save and reload" do
      @subject.publisher = ["St. Martin's Press"]
      @subject.serialize.should =~ /<rdf:RDF/
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

      class MyDatastream < ActiveFedora::RdfxmlRDFDatastream
        property :resource_type, :predicate => DAMS.typeOfResource
        property :title, :predicate => DAMS.title, :class_name => 'Description'

        rdf_subject { |ds| RDF::URI.new(ds.about) }

        attr_reader :about

        def initialize(digital_object=nil, dsid=nil, options={})
          @about = options.delete(:about)
          super
        end

        class Description < ActiveFedora::Rdf::Resource
          configure :type => DAMS.Description
          property :value, :predicate => RDF.value do |index|
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
      subject { MyDatastream.new(double('inner object', :pid=>'test:1', :new_record? =>true), 'descMetadata', about:"http://library.ucsd.edu/ark:/20775/") }
      it "should have a subject" do
        subject.rdf_subject.to_s.should == "http://library.ucsd.edu/ark:/20775/"
      end

    end

    describe "an instance with content" do
      subject do
        subject = MyDatastream.new(double('inner object', :pid=>'test:1', :new_record? =>true), 'descMetadata', about:"http://library.ucsd.edu/ark:/20775/")
        subject.content = File.new('spec/fixtures/damsObjectModel.xml').read
        subject
      end
      it "should have a subject" do
        subject.rdf_subject.to_s.should == "http://library.ucsd.edu/ark:/20775/"
      end
      it "should have controlGroup" do
        subject.controlGroup.should == 'M'
      end
      it "should have mimeType" do
        subject.mimeType.should == 'text/xml'
      end
      it "should have dsid" do
        subject.dsid.should == 'descMetadata'
      end
      it "should have fields" do
        subject.resource_type.should == ["image"]
        subject.title.first.value.should == ["example title"]
      end
    end
  end
end
