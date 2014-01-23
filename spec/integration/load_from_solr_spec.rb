require 'spec_helper'

describe "Loading from solr" do
  before do
    class MyRdfDatastream < ActiveFedora::NtriplesRDFDatastream
      property :title, predicate: RDF::DC.title do |index|
        index.as :stored_searchable, :facetable
      end
      property :date_uploaded, predicate: RDF::DC.dateSubmitted do |index|
        index.type :date
        index.as :stored_searchable, :sortable
      end
      property :identifier, predicate: RDF::DC.identifier do |index|
        index.type :integer
        index.as :stored_searchable, :sortable
      end
      property :part, predicate: RDF::DC.hasPart
      property :based_near, predicate: RDF::FOAF.based_near
      property :related_url, predicate: RDF::RDFS.seeAlso
    end
    class MyOmDatastream < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path: "animals")
        t.duck(index_as: :stored_searchable)
      end
    end
    class RdfTest < ActiveFedora::Base 
      has_metadata 'rdf', type: MyRdfDatastream
      has_metadata 'om', type: MyOmDatastream
      has_attributes :based_near, :related_url, :part, :date_uploaded, datastream: 'rdf', multiple: true
      has_attributes :title, :identifier, datastream: 'rdf', multiple: false
      has_attributes :duck, datastream: 'om', multiple: false
    end
  end

  let!(:original) { RdfTest.create!(title: "PLAN 9 FROM OUTER SPACE",
                                    date_uploaded: Date.parse('1959-01-01'),
                                    duck: "quack",
                                   identifier: 12345) }

  after do
    original.destroy
    Object.send(:remove_const, :RdfTest)
    Object.send(:remove_const, :MyRdfDatastream)
    Object.send(:remove_const, :MyOmDatastream)
  end

  it "should be able to get indexed properties without loading from fedora" do
    RdfTest.connection_for_pid('1').should_not_receive(:datastream_dissemination)
    obj = RdfTest.load_instance_from_solr original.pid
    expect(obj.title).to eq "PLAN 9 FROM OUTER SPACE"
    expect(obj.date_uploaded).to eq [Date.parse('1959-01-01')]
    expect(obj.identifier).to eq 12345
    expect{obj.part}.to raise_error KeyError, "Tried to fetch `part' from solr, but it isn't indexed."
    ActiveFedora::DatastreamAttribute.logger.should_receive(:info).with "Couldn't get duck out of solr, because the datastream 'MyOmDatastream' doesn't respond to 'primary_solr_name'. Trying another way."
    expect(obj.duck).to eq 'quack'
  end

end
