require 'spec_helper'

require 'active_fedora'
require 'xmlsimple'
require 'nokogiri'

describe ActiveFedora::QualifiedDublinCoreDatastream do

  before(:all) do
    # Load Sample OralHistory Model
    require File.join( File.dirname(__FILE__), "..", "samples","oral_history_sample_model" )
    @dc_elements = [:contributor, :coverage, :creator, :date, :description, :format, :identifier, :language, :publisher, :relation, :rights, :source]
    @dc_terms = []
  end
  
  before(:each) do
    stub_get("_nextid_", ['RELS-EXT', 'sensitive_passages', 'significant_passages', 'dublin_core', 'properties'])
    Rubydora::Repository.any_instance.stubs(:client).returns(@mock_client)
    ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns("_nextid_")
    @test_ds = ActiveFedora::QualifiedDublinCoreDatastream.new(nil, nil)
    @test_ds.stubs(:content).returns('')

  end
  it "from_xml should parse everything correctly" do
    #originally just tested that lcsh encoding and stuff worked, but the other stuff is worth testing
    stub_get("meh:leh", ['RELS-EXT', 'sensitive_passages', 'significant_passages', 'dublin_core', 'properties'])
    stub_get_content("meh:leh", ['dublin_core'])
    ActiveFedora::RubydoraConnection.instance.expects(:nextid).returns("meh:leh")
    tmpl = OralHistorySampleModel.new.datastreams['dublin_core']

    tmpl.expects(:subject_append).with('sh1')
    tmpl.expects(:subject_append).with('sh2')
    tmpl.expects(:subject_append).with('kw2')
    tmpl.expects(:subject_append).with('kw1')
    tmpl.expects(:spatial_append).with('sp1')
    tmpl.expects(:spatial_append).with('sp2')
    tmpl.expects(:language_append).with('English')
    tmpl.expects(:alternative_append).with('alt')
    tmpl.expects(:title_append).with('title')
    tmpl.expects(:temporal_append).with('tmp')
    tmpl.expects(:extent_append).with('extent')
    tmpl.expects(:medium_append).with('medium')
    tmpl.expects(:format_append).with('audio/x-wav')
    tmpl.expects(:subject_heading_append).with('sh1')
    tmpl.expects(:subject_heading_append).with('sh2')
    tmpl.expects(:creator_append).with('creator')
    tmpl.expects(:type_append).with('sound')
    tmpl.expects(:rights_append).with('rights')
    tmpl.expects(:publisher_append).with('jwa')
    tmpl.expects(:description_append).with('desc')

    sample_xml = fixture('oh_qdc.xml')
    sample_ds_xml = Nokogiri::XML::Document.parse(sample_xml).xpath('//foxml:datastream/foxml:datastreamVersion/foxml:xmlContent/dc').first
    
    z = ActiveFedora::QualifiedDublinCoreDatastream.from_xml(sample_ds_xml.to_s, tmpl)
    z.should === tmpl
  end

  it "should create the right number of fields" do
    ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS.size.should == 65
  end

  it "should have unmodifiable constants" do
    proc {ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS<<:foo}.should raise_error(TypeError, 'can\'t modify frozen array')

  end

  it "should have identity in and out" do
    sample = fixture('oh_qdc.xml')
    tmpl = OralHistorySampleModel.new.datastreams['dublin_core']
    tmpl.expects(:content).returns('')
    x1 = Nokogiri::XML::Document.parse(sample).xpath('/wrapper/foxml:datastream/foxml:datastreamVersion/foxml:xmlContent/dc').first.to_xml
    z = ActiveFedora::QualifiedDublinCoreDatastream.from_xml(x1, tmpl)
    y = ActiveFedora::QualifiedDublinCoreDatastream.from_xml(z.to_dc_xml, tmpl)
    y.to_dc_xml.should == z.to_dc_xml
  end

  it "should handle arbitrary attribs" do
    tmpl = OralHistorySampleModel.new.datastreams['dublin_core']
    tmpl.expects(:content).returns('')
    tmpl.field :mycomplicated, :string, :xml_node=>'alt', :element_attrs=>{:foo=>'bar'}
    tmpl.mycomplicated_values='fubar'
    tmpl.to_dc_xml.should == '<dc xmlns:xsi=\'http://www.w3.org/2001/XMLSchema-instance\' xmlns:dcterms=\'http://purl.org/dc/terms/\'><dcterms:alt foo=\'bar\'>fubar</dcterms:alt></dc>'

  end



  it "should parse dcterms and dcelements from xml" do
    doc = Nokogiri::XML::Document.parse(File.open( File.dirname(__FILE__)+'/../fixtures/changeme155.xml') )
    stream = doc.xpath('//foxml:datastream[@ID=\'dublin_core\']/foxml:datastreamVersion/foxml:xmlContent/dc')
    ds = ActiveFedora::QualifiedDublinCoreDatastream.new(nil, nil)
    ds.expects(:content).returns('')
    n = ActiveFedora::QualifiedDublinCoreDatastream.from_xml(stream.to_xml, ds)
    n.spatial_values.should == ["Boston [7013445]", "Dorchester [7013575]", "Roxbury [7015002]"] 
    n.title_values.should ==  ["Oral history with Frances Addelson, 1997 November 14"]
    n.dirty?.should == false

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
    
    it 'should initialize an object with fields for all DC elements' do
      @dc_elements.each do |el|
        @test_ds.fields.should_not be_nil
        @test_ds.fields.should have_key("#{el.to_s}".to_sym)
      end
    end
    
    it 'should respond to getters and setters for all DC elements' do
      @dc_elements.each do |el|
        @test_ds.should respond_to("#{el.to_s}_values")
        @test_ds.should respond_to("#{el.to_s}_values=") 
        eval("@test_ds.#{el.to_s}_values").class.should == Array  
        eval("@test_ds.#{el.to_s}_values = ['test_value']").should == ['test_value']
      end
    end
    
  end
  
  describe 'serialize!' do
    it "should call .content= with to_dc_xml" do
      result = @test_ds.to_dc_xml
      @test_ds.expects(:content=).with(result)
      @test_ds.serialize!
    end
  end
  
  describe '.to_dc_xml' do
    
    it 'should respond to .to_dc_xml' do
      @test_ds.should respond_to(:to_dc_xml)
    end


    #
    # I think the fields should just be tracked as a Nokogiri::XML::Document internally.  Too much BS otherwise.
    #


    it 'should output the fields hash as Qualified Dublin Core XML' do
      sample_xml = "<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><dcterms:title>title1</dcterms:title><dcterms:publisher>publisher1</dcterms:publisher><dcterms:creator>creator1</dcterms:creator><dcterms:creator>creator2</dcterms:creator></dc>"
      #@test_ds.expects(:fields).returns({:publisher => ["publisher1"], :creator => ["creator1", "creator2"], :title => ["title1"]})
      @test_ds.publisher_values = ["publisher1"]
      @test_ds.creator_values = ["creator1", "creator2"]
      @test_ds.title_values = ["title1"]

      dc_xml = XmlSimple.xml_in(@test_ds.to_dc_xml)
      dc_xml.should == XmlSimple.xml_in(sample_xml)
    end

    it 'should not include :type information' do
      @test_ds.publisher_values = ["publisher1"]
      dc_xml = XmlSimple.xml_in(@test_ds.to_dc_xml)
      @test_ds.fields[:publisher].should have_key(:type)
      dc_xml["publisher"].should_not include("type")
    end

    it "should use specified :xml_node if it is available in the field Hash" do
      @test_ds.stubs(:fields).returns({:myfieldname => {:values => ["sample spatial coverage"], :xml_node => "nodename" }})
      Nokogiri::XML::Document.parse(@test_ds.to_dc_xml).xpath('./dc/dcterms:nodename').text.should ==  'sample spatial coverage'
    end

    it "should use specified :xml_node if it was specified when .field was called" do
      sample_xml = "<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><dcterms:nodename>sample spatial coverage</dcterms:nodename></dc>"
      @test_ds.field :myfieldname, :string, :xml_node => "nodename"
      @test_ds.myfieldname_values = "sample spatial coverage"
      dc_xml = XmlSimple.xml_in(@test_ds.to_dc_xml)
      dc_xml.should == XmlSimple.xml_in(sample_xml)
    end

    it "should only apply encoding info and other qualifiers to the nodes that explicitly declare it" do
    end
  end


end
