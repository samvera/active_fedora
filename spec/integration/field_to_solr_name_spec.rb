require 'spec_helper'

describe "An object with RDF backed attributes" do

  before do
    class TestOne < ActiveFedora::Base
      class MyMetadata < ActiveFedora::NtriplesRDFDatastream
        Deprecation.silence(ActiveFedora::RDFDatastream) do
          property :title, predicate: ::RDF::DC.title do |index|
            index.as :stored_searchable
          end
          property :date_uploaded, predicate: ::RDF::DC.dateSubmitted do |index|
            index.type :date
            index.as :stored_searchable, :sortable
          end
        end
      end
      has_metadata 'descMetadata', type: MyMetadata
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :title, :date_uploaded, datastream: 'descMetadata'
      end
    end
  end

  after do
    Object.send(:remove_const, :TestOne)
  end

  it "should be able to grab the solr name" do
    expect(TestOne.delegated_attributes[:title].primary_solr_name).to eq 'desc_metadata__title_tesim'
  end

  it "should be able to grab the solr name for a date" do
    expect(TestOne.delegated_attributes[:date_uploaded].primary_solr_name).to eq 'desc_metadata__date_uploaded_dtsim'
  end
end
