require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  before do
    class FileVocabulary < RDF::Vocabulary("http://downlode.org/Code/RDF/File_Properties/schema#")
      property :size
    end

    Deprecation.silence(ActiveFedora::RDFDatastream) do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, predicate: ::RDF::Vocab::DC.title do |index|
          index.as :stored_searchable, :facetable
        end
        property :date_uploaded, predicate: ::RDF::Vocab::DC.dateSubmitted do |index|
          index.type :date
          index.as :stored_searchable, :sortable
        end
        property :filesize, predicate: FileVocabulary.size do |index|
          index.type :integer
          index.as :stored_sortable
        end
        property :part, predicate: ::RDF::Vocab::DC.hasPart
        property :based_near, predicate: ::RDF::Vocab::FOAF.based_near
        property :related_url, predicate: ::RDF::RDFS.seeAlso
      end
    end

    class RdfTest < ActiveFedora::Base
      has_subresource 'rdf', class_name: 'MyDatastream'
    end
  end

  subject(:my_datastream) { MyDatastream.new(described_class.id_to_uri('test:1')) }

  after do
    Object.send(:remove_const, :RdfTest)
    Object.send(:remove_const, :MyDatastream)
    Object.send(:remove_const, :FileVocabulary)
  end

  let(:remote_content) do
    <<EOF
<#{ActiveFedora.fedora.host}/test/test:1> <http://purl.org/dc/terms/created> "2010-12-31"^^<http://www.w3.org/2001/XMLSchema#date> .
<#{ActiveFedora.fedora.host}/test/test:1> <http://purl.org/dc/terms/title> "Title of work" .
<#{ActiveFedora.fedora.host}/test/test:1> <http://purl.org/dc/terms/publisher> "Penn State" .
<#{ActiveFedora.fedora.host}/test/test:1> <http://xmlns.com/foaf/0.1/based_near> "New York, NY, US" .
<#{ActiveFedora.fedora.host}/test/test:1> <http://www.w3.org/2000/01/rdf-schema#seeAlso> <http://google.com/> .
<#{ActiveFedora.fedora.host}/test/test:1/content> <http://purl.org/dc/terms/title> "Title of datastream" .
EOF
  end

  it "delegates as_json to the fields" do
    my_datastream.title = "Title of work"
    expect(my_datastream.title.as_json).to eq ["Title of work"]
    expect(my_datastream.title.to_json).to eq "\[\"Title of work\"\]"
  end

  describe "serializing" do
    it "handles dates" do
      my_datastream.date_uploaded = [Date.parse('2012-11-02')]
      expect(my_datastream.date_uploaded.first).to be_kind_of Date
    end
    it "handles integers" do
      my_datastream.filesize = 12_345
      expect(my_datastream.filesize).to eq [12_345]
      expect(my_datastream.filesize.first).to be_kind_of Fixnum
    end
  end

  it "sets and recall values" do
    my_datastream.title = 'War and Peace'
    expect(my_datastream).to be_changed
    my_datastream.based_near = ["Moscow, Russia"]
    my_datastream.related_url = ["http://en.wikipedia.org/wiki/War_and_Peace"]
    my_datastream.part = ["this is a part"]
    my_datastream.save
    expect(my_datastream.title).to eq ['War and Peace']
    expect(my_datastream.based_near).to eq ["Moscow, Russia"]
    expect(my_datastream.related_url).to eq ["http://en.wikipedia.org/wiki/War_and_Peace"]
    expect(my_datastream.part).to eq ["this is a part"]
  end

  it "set, persist, and recall values" do
    my_datastream.title = 'War and Peace'
    my_datastream.based_near = ["Moscow, Russia"]
    my_datastream.related_url = ["http://en.wikipedia.org/wiki/War_and_Peace"]
    my_datastream.part = ["this is a part"]
    my_datastream.save

    loaded = MyDatastream.new(my_datastream.uri)
    expect(loaded.title).to eq ['War and Peace']
    expect(loaded.based_near).to eq ['Moscow, Russia']
    expect(loaded.related_url).to eq ['http://en.wikipedia.org/wiki/War_and_Peace']
    expect(loaded.part).to eq ['this is a part']
  end

  it "sets multiple values" do
    my_datastream.part = ["part 1", "part 2"]
    my_datastream.save

    loaded = MyDatastream.new(my_datastream.uri)
    expect(loaded.part).to contain_exactly 'part 1', 'part 2'
  end

  it "appends values" do
    my_datastream.part = ["thing 1"]
    my_datastream.save

    my_datastream.part << "thing 2"
    expect(my_datastream.part).to contain_exactly "thing 1", "thing 2"
  end

  it "is able to save a blank document" do
    my_datastream.title = ""
    my_datastream.save
  end

  it "loads n-triples into the graph" do
    ntrip = '<http://oregondigital.org/ns/62> <http://purl.org/dc/terms/type> "Image" .
<http://oregondigital.org/ns/62> <http://purl.org/dc/terms/spatial> "Benton County (Ore.)" .
'
    my_datastream.content = ntrip
    expect(my_datastream.graph.statements.to_a).to contain_exactly(*RDF::NTriples::Reader.new(ntrip).statements.to_a)
  end

  describe "using rdf_subject" do
    before do
      # reopening existing class
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        rdf_subject { |ds| RDF::URI.new("http://oregondigital.org/ns/#{parent_uri(ds).split('/')[-1].split(':')[1]}") }
        property :dctype, predicate: ::RDF::Vocab::DC.type
      end
      rdf_test.rdf.dctype = "Frog"
      rdf_test.save!
    end

    after do
      rdf_test.destroy
    end

    subject(:rdf_test) { RdfTest.new('/test:99') }

    it "writes rdf with proper subjects" do
      rdf_test.reload
      expect(rdf_test.rdf.graph.dump(:ntriples)).to eq "<http://oregondigital.org/ns/99> <http://purl.org/dc/terms/type> \"Frog\" .\n"
      rdf_test.rdf.dctype == ['Frog']
    end
  end

  it "deletes values" do
    my_datastream.title = "Hamlet"
    my_datastream.related_url = ["http://psu.edu/"]
    my_datastream.related_url << "http://projecthydra.org/"

    expect(my_datastream.title).to eq ["Hamlet"]
    expect(my_datastream.related_url).to include("http://psu.edu/")
    expect(my_datastream.related_url).to include("http://projecthydra.org/")

    my_datastream.title = "" # empty string can be meaningful, don't assume delete.
    expect(my_datastream.title).to eq ['']

    my_datastream.title = nil
    my_datastream.related_url.delete("http://projecthydra.org/")

    expect(my_datastream.title).to eq []
    expect(my_datastream.related_url).to eq ["http://psu.edu/"]
  end

  it "deletes multiple values at once" do
    my_datastream.part = ["MacBeth"]
    my_datastream.part << "Hamlet"
    my_datastream.part << "Romeo & Juliet"
    expect(my_datastream.part).to include "MacBeth"
    my_datastream.part.subtract(["MacBeth", "Romeo & Juliet"])
    expect(my_datastream.part).to eq ["Hamlet"]
    expect(my_datastream.part.first).to eq "Hamlet"
  end
  it "ignores values to be deleted that do not exist" do
    my_datastream.part = ["title1", "title2", "title3"]
    my_datastream.part.subtract(["title2", "title4", "title6"])
    expect(my_datastream.part).to contain_exactly "title1", "title3"
  end

  describe "term proxy methods" do
    before(:each) do
      class TitleDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end
    subject(:title_datastream) { TitleDatastream.new }
    before { title_datastream.title = ["title1", "title2", "title3"] }

    after(:each) do
      Object.send(:remove_const, :TitleDatastream)
    end

    it "supports the count method to determine # of values" do
      expect(title_datastream.title.count).to eq 3
    end
    it "iterates over multiple values" do
      expect(title_datastream.title).to respond_to(:each)
    end
    it "evaluates equality predictably" do
      expect(title_datastream.title).to contain_exactly "title1", "title2", "title3"
    end
    it "supports the empty? method" do
      expect(title_datastream.title).to_not be_empty
      title_datastream.title.subtract(["title1", "title2", "title3"])
      expect(title_datastream.title).to be_empty
    end
    it "supports the each method" do
      expect(title_datastream.title.respond_to?(:each)).to eq true
    end
  end
end
