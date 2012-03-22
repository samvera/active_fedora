require 'spec_helper'

describe ActiveFedora::RdfxmlRDFDatastream do
    describe "a new instance" do
    before(:each) do
      class MyRdfxmlDatastream < ActiveFedora::RdfxmlRDFDatastream
        register_vocabularies RDF::DC
        map_predicates do |map|
          map.publisher(:in => RDF::DC)
        end
      end
      @subject = MyRdfxmlDatastream.new(@inner_object, 'mixed_rdf')
      @subject.stubs(:pid => 'test:1')
    end
    after(:each) do
      Object.send(:remove_const, :MyRdfxmlDatastream)
    end
    it "should save and reload" do
      @subject.publisher = ["St. Martin's Press"]
      @subject.serialize.should =~ /<rdf:RDF/
    end
 end
end
