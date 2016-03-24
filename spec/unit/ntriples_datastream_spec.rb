require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do
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

  describe "an instance with content" do
    before do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        property :created, predicate: ::RDF::Vocab::DC.created
        property :title, predicate: ::RDF::Vocab::DC.title
        property :publisher, predicate: ::RDF::Vocab::DC.publisher
        property :creator, predicate: ::RDF::Vocab::DC.creator
        property :educationLevel, predicate: ::RDF::Vocab::DC.educationLevel
        property :based_near, predicate: ::RDF::Vocab::FOAF.based_near
        property :related_url, predicate: ::RDF::Vocab::RDFS.seeAlso
      end
      @subject = MyDatastream.new(ActiveFedora::Base.id_to_uri('/test:1/descMetadata'))
      @subject.content = remote_content
    end
    after do
      Object.send(:remove_const, :MyDatastream)
    end
    it "has a subject" do
      expect(@subject.rdf_subject).to eq "#{ActiveFedora.fedora.host}/test/test:1"
    end
    it "has mime_type" do
      expect(@subject.mime_type).to eq 'text/plain'
    end
    it "has fields" do
      expect(@subject.created).to eq [Date.parse('2010-12-31')]
      expect(@subject.title).to eq ["Title of work"]
      expect(@subject.publisher).to eq ["Penn State"]
      expect(@subject.based_near).to eq ["New York, NY, US"]
      expect(@subject.related_url.length).to eq 1
      expect(@subject.related_url.first.rdf_subject).to eq "http://google.com/"
    end

    it "is able to call enumerable methods on the fields" do
      expect(@subject.title.join(', ')).to eq "Title of work"
      expect(@subject.title.count).to eq 1
      expect(@subject.title.size).to eq 1
      expect(@subject.title[0]).to eq "Title of work"
      expect(@subject.title.to_a).to eq ["Title of work"]
      val = []
      @subject.title.each_with_index { |v, i| val << "#{i}. #{v}" }
      expect(val).to eq ["0. Title of work"]
    end

    it "has method missing" do
      expect(lambda { @subject.frank }).to raise_exception NoMethodError
    end

    it "sets fields" do
      @subject.publisher = "St. Martin's Press"
      expect(@subject.publisher).to eq ["St. Martin's Press"]
    end
    it "sets rdf literal fields" do
      @subject.creator = RDF.Literal("Geoff Ryman")
      expect(@subject.creator).to eq ["Geoff Ryman"]
    end
    it "appends fields" do
      @subject.publisher << "St. Martin's Press"
      expect(@subject.publisher).to contain_exactly "Penn State", "St. Martin's Press"
    end
    it "deletes fields" do
      @subject.related_url.delete(RDF::URI("http://google.com/"))
      expect(@subject.related_url).to eq []
    end
  end

  describe "some dummy instances" do
    before do
      @one = ActiveFedora::RDFDatastream.new
      @two = ActiveFedora::RDFDatastream.new
    end
    it "generates predictable prexies" do
      expect(@one.send(:apply_prefix, "baz", 'myFoobar')).to eq 'my_foobar__baz'
      expect(@two.send(:apply_prefix, "baz", 'myQuix')).to eq 'my_quix__baz'
    end
  end

  describe "an instance with a custom subject" do
    before do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        rdf_subject { |ds| "#{ActiveFedora.fedora.host}/test/#{ds.id}/content" }
        property :created, predicate: ::RDF::Vocab::DC.created
        property :title, predicate: ::RDF::Vocab::DC.title
        property :publisher, predicate: ::RDF::Vocab::DC.publisher
        property :based_near, predicate: ::RDF::Vocab::FOAF.based_near
        property :related_url, predicate: ::RDF::Vocab::RDFS.seeAlso
      end
      @subject = MyDatastream.new
      allow(@subject).to receive(:id).and_return 'test:1'
      allow(@subject).to receive(:new_record?).and_return false
      allow(@subject).to receive(:remote_content).and_return remote_content
    end

    after do
      Object.send(:remove_const, :MyDatastream)
    end

    it "has fields" do
      expect(@subject.title).to eq ["Title of datastream"]
    end

    it "has a custom subject" do
      expect(@subject.rdf_subject).to eq "#{ActiveFedora.fedora.host}/test/test:1/content"
    end
  end

  describe "a new instance" do
    before do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        property :publisher, predicate: ::RDF::Vocab::DC.publisher
      end
      @subject = MyDatastream.new
    end

    after do
      Object.send(:remove_const, :MyDatastream)
    end

    xit "supports to_s method" do
      expect(@subject.publisher.to_s).to eq [].to_s
      @subject.publisher = "Bob"
      expect(@subject.publisher.to_s).to eq ["Bob"].to_s
      @subject.publisher << "Jim"
      expect(@subject.publisher.to_s).to eq ["Bob", "Jim"].to_s
    end
  end

  describe "solr integration" do
    before(:all) do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
      end
    end

    after(:all) do
      Object.send(:remove_const, :MyDatastream)
    end

    before(:each) do
      @subject = MyDatastream.new
      @subject.content = File.new('spec/fixtures/solr_rdf_descMetadata.nt').read
      @subject.serialize
    end

    it "provides .to_solr and return a SolrDocument" do
      expect(@subject).to respond_to(:to_solr)
      expect(@subject.to_solr).to be_kind_of(Hash)
    end

    it "optionally allows you to provide the Solr::Document to add fields to and return that document when done" do
      doc = {}
      expect(@subject.to_solr(doc)).to eq doc
    end
  end
end
