require File.join( File.dirname(__FILE__), "../spec_helper" )


describe ActiveFedora::NokogiriDatastream do
  
  before(:all) do
    @sample_fields = {:publisher => {:values => ["publisher1"], :type => :string}, 
                      :coverage => {:values => ["coverage1", "coverage2"], :type => :text}, 
                      :creation_date => {:values => "fake-date", :type => :date},
                      :mydate => {:values => "fake-date", :type => :date},
                      :empty_field => {:values => {}}
                      } 
    @sample_xml = XmlSimple.xml_in("<fields><coverage>coverage1</coverage><coverage>coverage2</coverage><creation_date>fake-date</creation_date><mydate>fake-date</mydate><publisher>publisher1</publisher></fields>")
    
  end
  
  before(:each) do
    @test_ds = ActiveFedora::NokogiriDatastream.new(:blob=>"<test_xml/>")
  end
  
  after(:each) do
  end
  
  describe '#new' do
    it 'should provide #new' do
      ActiveFedora::NokogiriDatastream.should respond_to(:new)
      @test_ds.ng_xml.should be_instance_of(Nokogiri::XML::Document)
    end
    it 'should load xml from blob if provided' do
      test_ds1 = ActiveFedora::NokogiriDatastream.new(:blob=>"<xml><foo/></xml>")
      test_ds1.ng_xml.to_xml.should == "<?xml version=\"1.0\"?>\n<xml>\n  <foo/>\n</xml>\n"
    end
  end
  

  it 'should provide .fields' do
    @test_ds.should respond_to(:fields)
  end
  
  describe '.save' do
    it "should provide .save" do
      @test_ds.should respond_to(:save)
    end
    it "should persist the product of .to_xml in fedora" do
      Fedora::Repository.instance.expects(:save)
      @test_ds.expects(:to_xml).returns("fake xml")
      @test_ds.expects(:blob=).with("fake xml")
      @test_ds.save
    end
  end
  
  describe '.to_xml' do
    it "should provide .to_xml" do
      @test_ds.should respond_to(:to_xml)
    end
    
    it "should ng_xml.to_xml" do
      @test_ds.ng_xml.expects(:to_xml).returns("xml")
      @test_ds.to_xml.should == "xml"       
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (mocked test)' do
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      doc.root.expects(:add_child).with(@test_ds.ng_xml.root)
      @test_ds.to_xml(doc)
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (functional test)' do
      expected_result = XmlSimple.xml_in("<test_document><foo/><test_xml/></test_document>")
      doc = Nokogiri::XML::Document.parse("<test_document><foo/></test_document>")
      result = @test_ds.to_xml(doc)
      XmlSimple.xml_in(doc.to_s).should == expected_result
      XmlSimple.xml_in(result).should == expected_result
    end
    
    it 'should add to root of Nokogiri::XML::Documents, but add directly to the elements if a Nokogiri::XML::Node is passed in' do
      mock_new_node = mock("new node")
      mock_new_node.stubs(:to_xml).returns("foo")
      
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      el = Nokogiri::XML::Node.new("test_element", Nokogiri::XML::Document.new)
      doc.root.expects(:add_child).with(@test_ds.ng_xml.root).returns(mock_new_node)
      el.expects(:add_child).with(@test_ds.ng_xml.root).returns(mock_new_node)
      @test_ds.to_xml(doc).should 
      @test_ds.to_xml(el)
    end
    
  end
  
  describe '.set_blob_for_save' do
    it "should provide .set_blob_for_save" do
      @test_ds.should respond_to(:set_blob_for_save)
    end
    
    it "should set the blob to to_xml" do
      @test_ds.expects(:blob=).with(@test_ds.to_xml)
      @test_ds.set_blob_for_save
    end
  end
  
  
  describe ".to_solr" do
    
    after(:all) do
      # Revert to default mappings after running tests
      ActiveFedora::SolrService.load_mappings
    end
    
    it "should iterate through the class fields, calling .values on each and appending the values to the solr doc"
    
    it "should provide .to_solr and return a SolrDocument" do
      @test_ds.should respond_to(:to_solr)
      @test_ds.to_solr.should be_kind_of(Solr::Document)
    end
    
    it "should optionally allow you to provide the Solr::Document to add fields to and return that document when done" do
      doc = Solr::Document.new
      @test_ds.to_solr(doc).should equal(doc)
    end
    
    it "should iterate through @fields hash" do
      @test_ds.expects(:fields).returns(@sample_fields)
      solr_doc =  @test_ds.to_solr
      
      solr_doc[:publisher_t].should == "publisher1"
      solr_doc[:coverage_t].should == "coverage1"
      solr_doc[:creation_date_dt].should == "fake-date"
      solr_doc[:mydate_dt].should == "fake-date"
      
      solr_doc[:empty_field_t].should be_nil
    end
    
    it "should allow multiple values for a single field"
    
    it 'should append create keys in format field_name + _ + field_type' do
      @test_ds.stubs(:fields).returns(@sample_fields)
      
      #should have these
            
      @test_ds.to_solr[:publisher_t].should_not be_nil
      @test_ds.to_solr[:coverage_t].should_not be_nil
      @test_ds.to_solr[:creation_date_dt].should_not be_nil
      
      #should NOT have these
      @test_ds.to_solr[:narrator].should be_nil
      @test_ds.to_solr[:title].should be_nil
      @test_ds.to_solr[:empty_field].should be_nil
      
    end
    
    it "should use Solr mappings to generate field names" do
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      @test_ds.stubs(:fields).returns(@sample_fields)
      solr_doc =  @test_ds.to_solr
      
      #should have these
            
      solr_doc[:publisher_field].should == "publisher1"
      solr_doc[:coverage_field].should == "coverage1"
      solr_doc[:creation_date_date].should == "fake-date"
      solr_doc[:mydate_date].should == "fake-date"
      
      solr_doc[:publisher_t].should be_nil
      solr_doc[:coverage_t].should be_nil
      solr_doc[:creation_date_dt].should be_nil
      
      # Reload default mappings
      ActiveFedora::SolrService.load_mappings
    end
    
    it 'should append _dt to dates' do
      @test_ds.expects(:fields).returns(@sample_fields).at_least_once
      
      #should have these
      
      @test_ds.to_solr[:creation_date_dt].should_not be_nil
      @test_ds.to_solr[:mydate_dt].should_not be_nil
      
      #should NOT have these
      
      @test_ds.to_solr[:mydate].should be_nil
      @test_ds.to_solr[:creation_date_date].should be_nil
    end
    
  end
  
  describe '.fields' do
    it "should return a Hash" do
      @test_ds.fields.should be_instance_of(Hash)
    end
  end
  
end
