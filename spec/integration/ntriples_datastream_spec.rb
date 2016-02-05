require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
  before do
    class FileVocabulary < RDF::Vocabulary("http://downlode.org/Code/RDF/File_Properties/schema#")
      property :size
    end

    class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      property :title, predicate: ::RDF::Vocab::DC.title
      property :date_uploaded, predicate: ::RDF::Vocab::DC.dateSubmitted
      property :filesize, predicate: FileVocabulary.size
      property :part, predicate: ::RDF::Vocab::DC.hasPart
      property :based_near, predicate: ::RDF::FOAF.based_near
      property :related_url, predicate: ::RDF::RDFS.seeAlso
    end

    class RdfTest < ActiveFedora::Base
      has_subresource 'rdf', class_name: 'MyDatastream'
    end
  end

  subject { MyDatastream.new(described_class.id_to_uri('test:1')) }

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
    subject.title = "Title of work"
    expect(subject.title.as_json).to eq ["Title of work"]
    expect(subject.title.to_json).to eq "\[\"Title of work\"\]"
  end

  describe "serializing" do
    it "handles dates" do
      subject.date_uploaded = [Date.parse('2012-11-02')]
      expect(subject.date_uploaded.first).to be_kind_of Date
    end
    it "handles integers" do
      subject.filesize = 12_345
      expect(subject.filesize).to be_kind_of Array
      expect(subject.filesize.first).to be_kind_of Fixnum
    end
  end

  it "sets and recall values" do
    subject.title = 'War and Peace'
    expect(subject).to be_changed
    subject.based_near = ["Moscow, Russia"]
    subject.related_url = ["http://en.wikipedia.org/wiki/War_and_Peace"]
    subject.part = ["this is a part"]
    subject.save
    expect(subject.title).to eq ['War and Peace']
    expect(subject.based_near).to eq ["Moscow, Russia"]
    expect(subject.related_url).to eq ["http://en.wikipedia.org/wiki/War_and_Peace"]
    expect(subject.part).to eq ["this is a part"]
  end

  it "set, persist, and recall values" do
    subject.title = 'War and Peace'
    subject.based_near = ["Moscow, Russia"]
    subject.related_url = ["http://en.wikipedia.org/wiki/War_and_Peace"]
    subject.part = ["this is a part"]
    subject.save

    loaded = MyDatastream.new(subject.uri)
    expect(loaded.title).to eq ['War and Peace']
    expect(loaded.based_near).to eq ['Moscow, Russia']
    expect(loaded.related_url).to eq ['http://en.wikipedia.org/wiki/War_and_Peace']
    expect(loaded.part).to eq ['this is a part']
  end

  it "sets multiple values" do
    subject.part = ["part 1", "part 2"]
    subject.save

    loaded = MyDatastream.new(subject.uri)
    expect(loaded.part).to eq ['part 1', 'part 2']
  end

  it "appends values" do
    subject.part = ["thing 1"]
    subject.save

    subject.part << "thing 2"
    expect(subject.part).to eq ["thing 1", "thing 2"]
  end

  it "loads n-triples into the graph" do
    ntrip = '<http://oregondigital.org/ns/62> <http://purl.org/dc/terms/type> "Image" .
<http://oregondigital.org/ns/62> <http://purl.org/dc/terms/spatial> "Benton County (Ore.)" .
'
    subject.content = ntrip
    expect(subject.graph.dump(:ntriples)).to eq ntrip
  end

  describe "using rdf_subject" do
    before do
      # reopening existing class
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        rdf_subject { |ds| RDF::URI.new("http://oregondigital.org/ns/#{parent_uri(ds).split('/')[-1].split(':')[1]}") }
        property :dctype, predicate: ::RDF::Vocab::DC.type
      end
      subject.rdf.dctype = "Frog"
      subject.save!
    end

    after do
      subject.destroy
    end

    subject { RdfTest.new('/test:99') }

    it "writes rdf with proper subjects" do
      subject.reload
      expect(subject.rdf.graph.dump(:ntriples)).to eq "<http://oregondigital.org/ns/99> <http://purl.org/dc/terms/type> \"Frog\" .\n"
      subject.rdf.dctype == ['Frog']
    end
  end

  it "deletes values" do
    subject.title = "Hamlet"
    subject.related_url = ["http://psu.edu/"]
    subject.related_url << "http://projecthydra.org/"

    expect(subject.title).to eq ["Hamlet"]
    expect(subject.related_url).to include("http://psu.edu/")
    expect(subject.related_url).to include("http://projecthydra.org/")

    subject.title = "" # empty string can be meaningful, don't assume delete.
    expect(subject.title).to eq ['']

    subject.title = nil
    subject.related_url.delete("http://projecthydra.org/")

    expect(subject.title).to eq []
    expect(subject.related_url).to eq ["http://psu.edu/"]
  end

  it "deletes multiple values at once" do
    subject.part = ["MacBeth"]
    subject.part << "Hamlet"
    subject.part << "Romeo & Juliet"
    expect(subject.part.first).to eq "MacBeth"
    subject.part.delete("MacBeth", "Romeo & Juliet")
    expect(subject.part).to eq ["Hamlet"]
    expect(subject.part.first).to eq "Hamlet"
  end
  it "ignores values to be deleted that do not exist" do
    subject.part = ["title1", "title2", "title3"]
    subject.part.delete("title2", "title4", "title6")
    expect(subject.part).to eq ["title1", "title3"]
  end

  describe "term proxy methods" do
    before(:each) do
      class TitleDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end
    subject { TitleDatastream.new }
    before { subject.title = ["title1", "title2", "title3"] }

    after(:each) do
      Object.send(:remove_const, :TitleDatastream)
    end

    it "supports the count method to determine # of values" do
      expect(subject.title.count).to eq 3
    end
    it "iterates over multiple values" do
      expect(subject.title).to respond_to(:each)
    end
    it "gets the first value" do
      expect(subject.title.first).to eq "title1"
    end
    it "evaluates equality predictably" do
      expect(subject.title).to eq ["title1", "title2", "title3"]
    end
    it "supports the empty? method" do
      expect(subject.title).to_not be_empty
      subject.title.delete("title1", "title2", "title3")
      expect(subject.title).to be_empty
    end
    it "supports the each method" do
      expect(@subject.title.respond_to?(:each)).to eq true
    end
  end
end
