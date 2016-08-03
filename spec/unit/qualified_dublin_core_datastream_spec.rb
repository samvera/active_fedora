require 'spec_helper'

describe ActiveFedora::QualifiedDublinCoreDatastream do
  DC_ELEMENTS = [:contributor, :coverage, :creator, :date, :description, :identifier, :language, :publisher, :relation, :rights, :source].freeze

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
    @test_ds = described_class.new
    @test_ds.content = sample_xml
  end

  it "creates the right number of fields" do
    expect(ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS.size).to eq 54
  end

  it "has unmodifiable constants" do
    expect { ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS << :foo }.to raise_error(RuntimeError, /can't modify frozen array/i)
  end

  it "defaults dc elements to :multiple=>true" do
    @test_ds.fields.values.each do |s|
      expect(s.key?(:multiple)).to be true
    end
  end

  describe '#new' do
    it 'provides #new' do
      expect(described_class).to respond_to(:new)
    end

    describe "model methods" do
      DC_ELEMENTS.each do |el|
        it "should respond to getters and setters for #{el} element" do
          pending if el == :type
          value = "Hey #{el}"
          @test_ds.send("#{el}=", value)
          expect(@test_ds.send(el).first).to eq value # Looking at first because creator has 2 nodes
        end
      end
    end
  end

  describe '.to_xml' do
    it 'outputs the fields hash as Qualified Dublin Core XML' do
      @test_ds = described_class.new

      @test_ds.field :publisher
      @test_ds.field :creator
      @test_ds.field :title

      @test_ds.publisher = ["publisher1"]
      @test_ds.creator = ["creator1", "creator2"]
      @test_ds.title = ["title1"]

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
    it "has title" do
      @test_ds = described_class.new
      @test_ds.title = "War and Peace"
      solr = @test_ds.to_solr
      expect(solr[ActiveFedora.index_field_mapper.solr_name('title', type: :string)]).to eq "War and Peace"
    end
  end

  describe 'custom fields' do
    subject(:datastream) { described_class.new }
    it 'grabs the term' do
      sample_xml = "<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><dcterms:cust>custom</dcterms:cust></dc>"
      datastream.content = sample_xml
      datastream.field :cust
      expect(datastream.cust).to eq ['custom']
    end
  end

  describe "#field should accept :path option" do
    subject(:datastream) { described_class.new }
    it "is able to map :dc_type to the path 'type'" do
      datastream.content = sample_xml
      datastream.field :dc_type, :string, path: "type", multiple: true
      expect(datastream.dc_type).to eq ['sound']
    end
  end
end
