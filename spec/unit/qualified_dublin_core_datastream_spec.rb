require 'spec_helper'

describe ActiveFedora::QualifiedDublinCoreDatastream do
  DC_ELEMENTS = [:contributor, :coverage, :creator, :date, :description, :identifier, :language, :publisher, :relation, :rights, :source]

  before(:all) do
    # Load Sample OralHistory Model
    require File.join( File.dirname(__FILE__), "..", "samples","oral_history_sample_model" )
    @dc_terms = []
  end
  
  before(:each) do
    @sample_xml =  "<dc xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:dcterms='http://purl.org/dc/terms/'>
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
     @test_ds = ActiveFedora::QualifiedDublinCoreDatastream.from_xml(@sample_xml )

  end
  it "from_xml should parse everything correctly" do
    @test_ds.ng_xml.should be_equivalent_to @sample_xml
  end

  it "should create the right number of fields" do
    ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS.size.should == 54
  end

  it "should have unmodifiable constants" do
    proc {ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS<<:foo}.should raise_error((TypeError if RUBY_VERSION < "1.9.0") || RuntimeError, /can't modify frozen array/i)

  end

  it "should default dc elements to :multiple=>true" do
    @test_ds.fields.values.each do |s|
      s.has_key?(:multiple).should == true
    end
  end
  
  after(:each) do
  end
  
  describe '#new' do
    it 'should provide #new' do
      ActiveFedora::QualifiedDublinCoreDatastream.should respond_to(:new)
    end
    
    
    describe "model methods" do 

      DC_ELEMENTS.each do |el|
        it "should respond to getters and setters for #{el} element" do
          pending if el == :type
          value = "Hey #{el}"
          @test_ds.send("#{el.to_s}=", value) 
          @test_ds.send(el).first.should == value  #Looking at first because creator has 2 nodes
        end
      end
    end
  end
  
  describe '.to_xml' do
    it 'should output the fields hash as Qualified Dublin Core XML' do
      #@test_ds.should_receive(:new?).and_return(true).twice
      sample_xml = "<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><dcterms:title>title1</dcterms:title><dcterms:publisher>publisher1</dcterms:publisher><dcterms:creator>creator1</dcterms:creator><dcterms:creator>creator2</dcterms:creator></dc>"
      @test_ds = ActiveFedora::QualifiedDublinCoreDatastream.new(nil, 'qdc' )

      @test_ds.field :publisher
      @test_ds.field :creator
      @test_ds.field :title
      
      @test_ds.publisher= ["publisher1"]
      @test_ds.creator= ["creator1", "creator2"]
      @test_ds.title= ["title1"]

      @test_ds.to_xml.should be_equivalent_to('
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
      @test_ds = ActiveFedora::QualifiedDublinCoreDatastream.new(nil, 'qdc' )
      @test_ds.title = "War and Peace"
      solr = @test_ds.to_solr
      solr[ActiveFedora::SolrService.solr_name('title', type: :string)].should == "War and Peace"
    end

  end

  describe 'custom fields' do
    it 'should grab the term' do
      sample_xml = "<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><dcterms:cust>custom</dcterms:cust></dc>"
      test_ds = ActiveFedora::QualifiedDublinCoreDatastream.from_xml(sample_xml )
      test_ds.field :cust
      test_ds.cust.should == ['custom']
    end
  end

  describe "#field should accept :path option" do
    it "should be able to map :dc_type to the path 'type'" do
      test_ds = ActiveFedora::QualifiedDublinCoreDatastream.from_xml(@sample_xml)
      test_ds.field :dc_type, :string, path: "type", multiple: true
      test_ds.dc_type.should == ['sound']
    end
  end

end
