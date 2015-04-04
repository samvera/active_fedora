require 'spec_helper'

describe ActiveFedora::QualifiedDublinCoreDatastream do
  DC_ELEMENTS = [:contributor, :coverage, :creator, :date, :description, :identifier, :language, :publisher, :relation, :rights, :source]

  let(:sample_xml) do "<dc xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:dcterms='http://purl.org/dc/terms/'>
          <dcterms:type xsi:type='DCMITYPE'>sound</dcterms:type>
          <dcterms:medium>medium</dcterms:medium>
          <dcterms:rights>rights</dcterms:rights>
          <dcterms:language>English</dcterms:language>
          <dcterms:temporal>tmp</dcterms:temporal>
          <dcterms:subject>kw1</dcterms:subject>
          <dcterms:subject>kw2</dcterms:subject>
          <dcterms:creator>creator</dcterms:creator>
          <dcterms:creator>creator</dcterms:creator>
          <dcterms:contributor>contributor</dcterms:contributor>
          <dcterms:coverage>coverage</dcterms:coverage>
          <dcterms:identifier>identifier</dcterms:identifier>
          <dcterms:relation>relation</dcterms:relation>
          <dcterms:source>source</dcterms:source>
          <dcterms:title>title</dcterms:title>
          <dcterms:extent>extent</dcterms:extent>
          <dcterms:format>audio/x-wav</dcterms:format>
          <dcterms:subject xsi:type='LCSH'>sh1</dcterms:subject>
          <dcterms:subject xsi:type='LCSH'>sh2</dcterms:subject>
          <dcterms:spatial>sp1</dcterms:spatial>
          <dcterms:spatial>sp2</dcterms:spatial>
          <dcterms:publisher>jwa</dcterms:publisher>
          <dcterms:alternative>alt</dcterms:alternative>
          <dcterms:description>desc</dcterms:description>
          <dcterms:date>datestr</dcterms:date>
        </dc>"
  end
  before do
     @test_ds = ActiveFedora::QualifiedDublinCoreDatastream.new
     @test_ds.content = sample_xml
  end

  it "should create the right number of fields" do
    expect(ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS.size).to eq 54
  end

  it "should have unmodifiable constants" do
    expect { ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS<<:foo }.to raise_error(RuntimeError, /can't modify frozen array/i)
  end

  it "should default dc elements to :multiple=>true" do
    @test_ds.fields.values.each do |s|
      expect(s.has_key?(:multiple)).to be true
    end
  end

  describe '#new' do
    it 'should provide #new' do
      expect(ActiveFedora::QualifiedDublinCoreDatastream).to respond_to(:new)
    end


    describe "model methods" do

      DC_ELEMENTS.each do |el|
        it "should respond to getters and setters for #{el} element" do
          pending if el == :type
          value = "Hey #{el}"
          @test_ds.send("#{el.to_s}=", value)
          expect(@test_ds.send(el).first).to eq value  #Looking at first because creator has 2 nodes
        end
      end
    end
  end

  describe '.to_xml' do
    it 'should output the fields hash as Qualified Dublin Core XML' do
      sample_xml = "<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><dcterms:title>title1</dcterms:title><dcterms:publisher>publisher1</dcterms:publisher><dcterms:creator>creator1</dcterms:creator><dcterms:creator>creator2</dcterms:creator></dc>"
      @test_ds = ActiveFedora::QualifiedDublinCoreDatastream.new

      @test_ds.field :publisher
      @test_ds.field :creator
      @test_ds.field :title

      @test_ds.publisher= ["publisher1"]
      @test_ds.creator= ["creator1", "creator2"]
      @test_ds.title= ["title1"]

      expect(@test_ds.to_xml).to be_equivalent_to('
        <dc xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                 <dcterms:publisher>publisher1</dcterms:publisher>
                 <dcterms:creator>creator1</dcterms:creator>
                 <dcterms:creator>creator2</dcterms:creator>
                 <dcterms:title>title1</dcterms:title>
              </dc>')
    end
  end

  describe "#to_solr" do
    it "should have title" do
      @test_ds = ActiveFedora::QualifiedDublinCoreDatastream.new
      @test_ds.title = "War and Peace"
      solr = @test_ds.to_solr
      expect(solr[ActiveFedora::SolrQueryBuilder.solr_name('title', type: :string)]).to eq "War and Peace"
    end

  end

  describe 'custom fields' do
    subject { ActiveFedora::QualifiedDublinCoreDatastream.new }
    it 'should grab the term' do
      sample_xml = "<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><dcterms:cust>custom</dcterms:cust></dc>"
      subject.content = sample_xml
      subject.field :cust
      expect(subject.cust).to eq ['custom']
    end
  end

  describe "#field should accept :path option" do
    subject { ActiveFedora::QualifiedDublinCoreDatastream.new }
    it "should be able to map :dc_type to the path 'type'" do
      subject.content = sample_xml
      subject.field :dc_type, :string, path: "type", multiple: true
      expect(subject.dc_type).to eq ['sound']
    end
  end

end
