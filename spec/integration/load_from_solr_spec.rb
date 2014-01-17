require 'spec_helper'

describe "Loading from solr" do
  before do
    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      map_predicates do |map|
        map.title(in: RDF::DC) do |index|
          index.as :stored_searchable, :facetable
        end
        map.date_uploaded(to: "dateSubmitted", in: RDF::DC) do |index|
          index.type :date
          index.as :stored_searchable, :sortable
        end
        map.identifier(in: RDF::DC) do |index|
          index.type :integer
          index.as :stored_searchable, :sortable
        end
        map.part(to: "hasPart", in: RDF::DC)
        map.based_near(in: RDF::FOAF)
        map.related_url(to: "seeAlso", in: RDF::RDFS)
      end
    end
    class RdfTest < ActiveFedora::Base 
      has_metadata :name=>'rdf', :type=>MyDatastream
      has_attributes :based_near, :related_url, :part, :date_uploaded, datastream: 'rdf', multiple: true
      has_attributes :title, :identifier, datastream: 'rdf', multiple: false
    end
  end

  let!(:original) { RdfTest.create!(title: "PLAN 9 FROM OUTER SPACE",
                                    date_uploaded: Date.parse('1959-01-01'),
                                   identifier: 12345) }

  after do
    original.destroy
    Object.send(:remove_const, :RdfTest)
    Object.send(:remove_const, :MyDatastream)
  end

  it "should be able to get indexed properties without loading from fedora" do
    expect(RdfTest.connection_for_pid('1')).to receive(:datastream_dissemination).never
    obj = RdfTest.load_instance_from_solr original.pid
    expect(obj.title).to eq "PLAN 9 FROM OUTER SPACE"
    expect(obj.date_uploaded).to eq [Date.parse('1959-01-01')]
    expect(obj.identifier).to eq 12345
    expect{obj.part}.to raise_error KeyError, "Tried to fetch `part' from solr, but it isn't indexed."
  end
end
