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
    
    it "should iterate through the class accessors, calling .solrize_accessor on each and passing in the solr doc" do
      mock_accessors = {:accessor1=>:accessor1_info, :accessor2=>:accessor2_info}
      ActiveFedora::NokogiriDatastream.stubs(:accessors).returns(mock_accessors)
      doc = Solr::Document.new
      mock_accessors.each_pair do |k,v|
        @test_ds.expects(:solrize_accessor).with(k, v, :solr_doc=>doc)
      end
      @test_ds.to_solr(doc)
    end
    
    it "should provide .to_solr and return a SolrDocument" do
      @test_ds.should respond_to(:to_solr)
      @test_ds.to_solr.should be_kind_of(Solr::Document)
    end
    
    it "should optionally allow you to provide the Solr::Document to add fields to and return that document when done" do
      doc = Solr::Document.new
      @test_ds.to_solr(doc).should equal(doc)
    end
    
  end
  
  describe ".solrize_accessor" do
    before(:all) do
      class AccessorizedDs < ActiveFedora::NokogiriDatastream
        
        root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          
        
        accessor :title_info, :relative_xpath=>'oxns:titleInfo', :children=>[
          {:main_title=>{:relative_xpath=>'oxns:title'}},         
          {:language =>{:relative_xpath=>{:attribute=>"lang"} }}
          ] 
        accessor :abstract
        accessor :topic_tag, :relative_xpath=>'oxns:subject/oxns:topic'
        accessor :person, :relative_xpath=>'oxns:name[@type="personal"]',  :children=>[
          {:last_name=>{:relative_xpath=>'oxns:namePart[@type="family"]'}}, 
          {:first_name=>{:relative_xpath=>'oxns:namePart[@type="given"]'}}, 
          {:institution=>{:relative_xpath=>'oxns:affiliation'}}, 
          {:role=>{:children=>[
            {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
            {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
          ]}}
        ]
      end
    end
    
    before(:each) do
      file = fixture(File.join("mods_articles", "hydrangea_article1.xml"))
      @accessorized_ds = AccessorizedDs.new(:blob=>file)
    end
    
    it "should perform a lookup and iterate over nodes in the result set calling solrize_node then calling solrize_accessor on any of the children, adding accessor_name & node index to parents array" do
      mock_title_info_set = ["TI1", "TI2"]
      mock_main_title_set = ["main title"]
      mock_language_set = ["language"]
      
      solr_doc = Solr::Document.new
      
      AccessorizedDs.expects(:accessor_xpath).with( :title_info ).returns("title_info_xpath")
      @accessorized_ds.expects(:lookup).with( "title_info_xpath" ).returns(mock_title_info_set)
      
      mock_title_info_set.each do |tin| 
        node_index = mock_title_info_set.index(tin)
        @accessorized_ds.expects(:solrize_node).with(tin, [:title_info], solr_doc) 
        
        # Couldn't mock the recursive calls to solrize_accessor without preventing the initial one, so was forced to mock out the whole recursive stack.
        # @accessorized_ds.expects(:solrize_accessor).with(:main_title, AccessorizedDs.accessors[:title_info][:children][:main_title], :parents=>[{:title_info=>node_index}])      
        # @accessorized_ds.expects(:solrize_accessor).with(:language, AccessorizedDs.accessors[:title_info][:children][:language], :parents=>[{:title_info=>node_index}])
          AccessorizedDs.expects(:accessor_xpath).with( {:title_info=>node_index}, :main_title ).returns("title_info_main_title_xpath")
          AccessorizedDs.expects(:accessor_xpath).with( {:title_info=>node_index}, :language ).returns("title_info_language_xpath")
          @accessorized_ds.expects(:lookup).with( "title_info_main_title_xpath" ).returns(mock_main_title_set)
          @accessorized_ds.expects(:lookup).with( "title_info_language_xpath" ).returns(mock_language_set)
          @accessorized_ds.expects(:solrize_node).with("main title", [{:title_info=>node_index}, :main_title], solr_doc) 
          @accessorized_ds.expects(:solrize_node).with("language", [{:title_info=>node_index}, :language], solr_doc) 
      end
      
      @accessorized_ds.solrize_accessor(:title_info, AccessorizedDs.accessors[:title_info], :solr_doc=>solr_doc)
      
    end
    
    it "should not call solrize_accessor once it reaches an accessor with no children accessors set" do
      pending "not sure how to test for this"
      @accessorized_ds.solrize_accessor(:text, AccessorizedDs.accessor_info( [{:person=>1}, :last_name] ), :parents=>[{:person=>1}])
    end
    
    it "should use values form parents array when requesting accessor_xpath and when generating solr field names" do
      parents_array = [{:person=>0}, {:role=>1}]
      AccessorizedDs.accessors[:person][:children][:role][:children][:text]
      
      # This should catch the "submitter" roleTerm from the second role node within the first person node and put it into a solr field called "person_0_role_2_text_0_t" and a solr field called "person_role_text_t"
      @accessorized_ds.solrize_accessor(:text, AccessorizedDs.accessor_info( *parents_array + [:text] ), :parents=>parents_array)
    end
    
    it "should use Solr mappings to generate field names" do

      solr_doc =  @accessorized_ds.to_solr
      #should have these
            
      solr_doc[:abstract_t].should == "ABSTRACT"
      solr_doc[:title_info_1_language_t].should == "finnish"
      solr_doc[:person_1_role_0_text_t].should == "teacher"
      # solr_doc[:mydate_date].should == "fake-date"
      # 
      # solr_doc[:publisher_t].should be_nil
      # solr_doc[:coverage_t].should be_nil
      # solr_doc[:creation_date_dt].should be_nil
      # solr_doc.should == ""
      
    end
  end
  
  describe ".solrize_node" do
    it "should create a solr field containing node.text"
    it "should create hierarchical field entries if parents is not empty"
    it "should only create one node if parents is empty"
  end
  
end
