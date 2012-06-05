require 'spec_helper'
describe ActiveFedora::NokogiriDatastream do
  
  before(:all) do
    @sample_fields = {:publisher => {:values => ["publisher1"], :type => :string}, 
                      :coverage => {:values => ["coverage1", "coverage2"], :type => :text}, 
                      :creation_date => {:values => "fake-date", :type => :date},
                      :mydate => {:values => "fake-date", :type => :date},
                      :empty_field => {:values => {}}
                      } 
    @sample_raw_xml = "<foo><xmlelement/></foo>"
    @solr_doc = {"id"=>"hydrange_article1","name_role_roleTerm_t"=>["creator","submitter","teacher"],"name_0_role_t"=>"\r\ncreator\r\nsubmitter\r\n","name_1_role_t"=>"\r\n teacher \r\n","name_0_role_0_roleTerm_t"=>"creator","name_0_role_1_roleTerm_t"=>"submitter","name_1_role_0_roleTerm_t"=>["teacher"]}
  end
  
  before(:each) do
    @mock_inner = mock('inner object')
    @mock_repo = mock('repository')
    @mock_repo.stubs(:datastream_dissemination=>'My Content', :config=>{})
    @mock_inner.stubs(:repository).returns(@mock_repo)
    @mock_inner.stubs(:pid)
    @test_ds = ActiveFedora::NokogiriDatastream.new(@mock_inner, "descMetadata")
    @test_ds.content="<test_xml/>"
  end
  
  after(:each) do
  end

  it "should include the Solrizer::XML::TerminologyBasedSolrizer for .to_solr support" do
    ActiveFedora::NokogiriDatastream.included_modules.should include(Solrizer::XML::TerminologyBasedSolrizer)
  end
  
  describe '#new' do
    it 'should provide #new' do
      ActiveFedora::NokogiriDatastream.should respond_to(:new)
      @test_ds.ng_xml.should be_instance_of(Nokogiri::XML::Document)
    end
    it 'should load xml from blob if provided' do
      test_ds1 = ActiveFedora::NokogiriDatastream.new(nil, 'ds1')
      test_ds1.content="<xml><foo/></xml>"
      test_ds1.ng_xml.to_xml.should == "<?xml version=\"1.0\"?>\n<xml>\n  <foo/>\n</xml>\n"
    end
    it "should initialize from #xml_template if no xml is provided" do
      ActiveFedora::NokogiriDatastream.expects(:xml_template).returns("<fake template/>")
      n = ActiveFedora::NokogiriDatastream.new(nil, nil)
      n.ensure_xml_loaded
      n.ng_xml.should be_equivalent_to("<fake template/>")
    end
  end
  
  describe '#xml_template' do
    it "should return an empty xml document" do
      ActiveFedora::NokogiriDatastream.xml_template.to_xml.should == "<?xml version=\"1.0\"?>\n<xml/>\n"
    end
  end

  describe "an instance" do
    subject { ActiveFedora::NokogiriDatastream.new(nil, nil) }
    it{ should.respond_to? :to_solr }
    its(:to_solr) {should == { }}
  end
  
  describe ".update_indexed_attributes" do
    
    before(:each) do
      @mods_ds = Hydra::ModsArticleDatastream.new(nil, 'descMetadata')
      @mods_ds.content=fixture(File.join("mods_articles","hydrangea_article1.xml")).read
    end
    
    it "should apply submitted hash to corresponding datastream field values" do
      pending if ENV['HUDSON_BUILD'] == 'true'  # This test fails en suite in hudson
      result = @mods_ds.update_indexed_attributes( {[{":person"=>"0"}, "role"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} })
      result.should == {"person_0_role"=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}}
      # xpath = ds.class.accessor_xpath(*field_key)
      # result = ds.property_values(xpath)
      
      @mods_ds.property_values('//oxns:name[@type="personal"][1]/oxns:role').should == ["role1","role2","role3"]
    end
    it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
      # In other words, { "fubar"=>"dork" } should have the same effect as { "fubar"=>{"0"=>"dork"} }
      result = @mods_ds.update_indexed_attributes( { [{":person"=>"0"}, "role"]=>"the role" } )
      result.should == {"person_0_role"=>{"0"=>"the role"}}
      @mods_ds.term_values('//oxns:name[@type="personal"][1]/oxns:role').first.should == "the role"
    end
    it "should do nothing if field key is a string (must be an array or symbol).  Will not accept xpath queries!" do
      xml_before = @mods_ds.to_xml
      logger.expects(:warn).with "WARNING: descMetadata ignoring {\"fubar\" => \"the role\"} because \"fubar\" is a String (only valid OM Term Pointers will be used).  Make sure your html has the correct field_selector tags in it."
      @mods_ds.update_indexed_attributes( { "fubar"=>"the role" } ).should == {}
      @mods_ds.to_xml.should == xml_before
    end
    it "should do nothing if there is no accessor corresponding to the given field key" do
      xml_before = @mods_ds.to_xml
      @mods_ds.update_indexed_attributes( { [{"fubar"=>"0"}]=>"the role" } ).should == {}
      @mods_ds.to_xml.should == xml_before
    end
    
    ### Examples copied over form metadata_datastream_spec
    
    it "should work for text fields" do 
      pending if ENV['HUDSON_BUILD'] == 'true'  # This test fails en suite in hudson
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"mork", "1"=>"york"}}
      result = @mods_ds.update_indexed_attributes(att)
      result.should == {"person_0_description"=>{"0"=>"mork","1"=>"york"}}
      @mods_ds.get_values([{:person=>0},:description]).should == ['mork', 'york']
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"dork"}}
      result2 = @mods_ds.update_indexed_attributes(att)
      result2.should == {"person_0_description"=>{"2"=>"dork"}}
      @mods_ds.get_values([{:person=>0},:description]).should == ['mork', 'york', 'dork']
    end
    
    it "should return the new index of any added values" do
      @mods_ds.get_values([{:title_info=>0},:main_title]).should == ["ARTICLE TITLE", "TITLE OF HOST JOURNAL"]
      result = @mods_ds.update_indexed_attributes [{"title_info"=>"0"},"main_title"]=>{"-1"=>"mork"}
      result.should == {"title_info_0_main_title"=>{"2"=>"mork"}}
    end

    it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
      pending if ENV['HUDSON_BUILD'] == 'true'  # This test fails en suite in hudson
      att= {[{"person"=>"0"},"description"]=>{"0"=>"york", "1"=>"mangle","2"=>"mork"}}
      @mods_ds.update_indexed_attributes(att)
      @mods_ds.get_values([{"person"=>"0"},"description"]).should == ['york', 'mangle', 'mork']
      
      @mods_ds.update_indexed_attributes({[{"person"=>"0"},"description"]=>{"1"=>""}})
      @mods_ds.get_values([{"person"=>"0"},"description"]).should == ['york', 'mork']
      
      @mods_ds.update_indexed_attributes({[{"person"=>"0"},"description"]=>{"0"=>:delete}})
      @mods_ds.get_values([{"person"=>"0"},"description"]).should == ['mork']
    end
    # it "should delete values so that to_xml does not return emtpy nodes" do
    #   @test_ds.fubar_values = ["val1", nil, "val2"]
    #   @test_ds.update_indexed_attributes({{[{"person"=>"0"},"description"]=>{"1"=>""}})
    #   @test_ds.fubar_values.should == ["val1", "val2"]
    # end
    
    it "should set @dirty to true" do
      @mods_ds.get_values([{:title_info=>0},:main_title]).should == ["ARTICLE TITLE", "TITLE OF HOST JOURNAL"]
      @mods_ds.update_indexed_attributes [{"title_info"=>"0"},"main_title"]=>{"-1"=>"mork"}
      @mods_ds.dirty?.should be_true
    end
  end
  
  describe ".get_values" do
    
    before(:each) do
      @mods_ds = Hydra::ModsArticleDatastream.new(nil, 'modsDs')
      @mods_ds.content=fixture(File.join("mods_articles","hydrangea_article1.xml")).read
    end
    
    it "should call lookup with field_name and return the text values from each resulting node" do
      @mods_ds.expects(:term_values).with("--my xpath--").returns(["value1", "value2"])
      @mods_ds.get_values("--my xpath--").should == ["value1", "value2"]
    end
    it "should assume that field_names that are strings are xpath queries" do
      ActiveFedora::NokogiriDatastream.expects(:accessor_xpath).never
      @mods_ds.expects(:term_values).with("--my xpath--").returns(["abstract1", "abstract2"])
      @mods_ds.get_values("--my xpath--").should == ["abstract1", "abstract2"]
    end
  end
  
  describe '#from_xml' do
    it "should work when a template datastream is passed in" do
      mods_xml = Nokogiri::XML::Document.parse( fixture(File.join("mods_articles", "hydrangea_article1.xml")) )
      tmpl = Hydra::ModsArticleDatastream.new(nil, nil)
      Hydra::ModsArticleDatastream.from_xml(mods_xml,tmpl).ng_xml.root.to_xml.should == mods_xml.root.to_xml
      tmpl.dirty?.should be_false
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
      @test_ds.expects(:new?).returns(true).twice
      @mock_repo.expects(:datastream).with(:pid => nil, :dsid => 'descMetadata').returns('')
      @mock_repo.expects(:add_datastream).with(:pid => nil, :dsid => 'descMetadata', :versionable => true, :content => 'fake xml', :controlGroup => 'M', :dsState => 'A', :mimeType=>'text/xml')
      @test_ds.expects(:to_xml).returns("fake xml")
      @test_ds.serialize!
      @test_ds.save
      @test_ds.mimeType.should == 'text/xml'
    end
  end
  
  describe '.content=' do
    it "should update the content and ng_xml, marking the datastream as dirty" do
      @test_ds.dirty = false  # pretend it isn't dirty to show that content= does it
      @test_ds.content.should_not be_equivalent_to(@sample_raw_xml)
      @test_ds.ng_xml.to_xml.should_not be_equivalent_to(@sample_raw_xml)
      @test_ds.content = @sample_raw_xml
      @test_ds.should be_dirty
      @test_ds.content.should be_equivalent_to(@sample_raw_xml)
      @test_ds.ng_xml.to_xml.should be_equivalent_to(@sample_raw_xml)
    end
  end
  
  describe 'ng_xml=' do
    before do
      @test_ds2 = ActiveFedora::NokogiriDatastream.new(@mock_inner, "descMetadata")
    end
    it "should parse raw xml for you" do
      @test_ds2.ng_xml = @sample_raw_xml
      @test_ds2.ng_xml.class.should == Nokogiri::XML::Document
      @test_ds2.ng_xml.to_xml.should be_equivalent_to(@sample_raw_xml)
    end

    it "Should always set a document when an Element is passed" do
      @test_ds2.ng_xml = Nokogiri::XML(@sample_raw_xml).xpath('//xmlelement').first
      @test_ds2.ng_xml.should be_kind_of Nokogiri::XML::Document
      @test_ds2.ng_xml.to_xml.should be_equivalent_to("<xmlelement/>")
    end
    it "should mark the datastream as dirty" do
      @test_ds2.dirty.should be_false 
      @test_ds2.ng_xml = @sample_raw_xml
      @test_ds2.ng_xml_changed?.should be_true
      @test_ds2.should be_dirty
    end
  end
  
  describe '.to_xml' do
    it "should provide .to_xml" do
      @test_ds.should respond_to(:to_xml)
    end
    
    it "should ng_xml.to_xml" do
      @test_ds.expects(:ng_xml).returns(Nokogiri::XML::Document.parse("<text_document/>")).twice
      @test_ds.to_xml.should == "<text_document/>\n"       
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (mocked test)' do
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      doc.root.expects(:add_child)#.with(@test_ds.ng_xml.root)
      @test_ds.to_xml(doc)
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (functional test)' do
      expected_result = "<test_document><foo/><test_xml/></test_document>"
      doc = Nokogiri::XML::Document.parse("<test_document><foo/></test_document>")
      result = @test_ds.to_xml(doc)
      doc.should be_equivalent_to expected_result
      result.should be_equivalent_to expected_result
    end
    
    it 'should add to root of Nokogiri::XML::Documents, but add directly to the elements if a Nokogiri::XML::Node is passed in' do
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      el = Nokogiri::XML::Node.new("test_element", Nokogiri::XML::Document.new)
      @test_ds.to_xml(doc).should be_equivalent_to "<test_document><test_xml/></test_document>"
      @test_ds.to_xml(el).should be_equivalent_to "<test_element/>"
    end
    
  end
  
  describe '.from_solr' do
    it "should set the internal_solr_doc attribute to the solr document passed in" do 
      @test_ds.from_solr(@solr_doc)
      @test_ds.internal_solr_doc.should == @solr_doc
    end
  end

  describe '.get_values_from_solr' do
    before(:each) do
      @mods_ds = ActiveFedora::NokogiriDatastream.new(nil, nil)
      @mods_ds.content=fixture(File.join("mods_articles","hydrangea_article1.xml")).read
    end

    it "should return empty array if internal_solr_doc not set" do
      @mods_ds.get_values_from_solr(:name,:role,:roleTerm)
    end
 
    it "should return correct values from solr_doc given different term pointers" do
      mock_term = mock("OM::XML::Term")
      mock_term.stubs(:data_type).returns(:text)
      mock_terminology = mock("OM::XML::Terminology")
      mock_terminology.stubs(:retrieve_term).returns(mock_term)
      ActiveFedora::NokogiriDatastream.stubs(:terminology).returns(mock_terminology)
      @mods_ds.from_solr(@solr_doc)
      term_pointer = [:name,:role,:roleTerm]
      @mods_ds.get_values_from_solr(:name,:role,:roleTerm).should == ["creator","submitter","teacher"]
      ar = @mods_ds.get_values_from_solr({:name=>0},:role,:roleTerm)
      ar.length.should == 2
      ar.include?("creator").should == true
      ar.include?("submitter").should == true
      @mods_ds.get_values_from_solr({:name=>1},:role,:roleTerm).should == ["teacher"]
      @mods_ds.get_values_from_solr({:name=>0},{:role=>0},:roleTerm).should == ["creator"]
      @mods_ds.get_values_from_solr({:name=>0},{:role=>1},:roleTerm).should == ["submitter"]
      @mods_ds.get_values_from_solr({:name=>0},{:role=>2},:roleTerm).should == []
      @mods_ds.get_values_from_solr({:name=>1},{:role=>0},:roleTerm).should == ["teacher"]
      @mods_ds.get_values_from_solr({:name=>1},{:role=>1},:roleTerm).should == []
      ar = @mods_ds.get_values_from_solr(:name,{:role=>0},:roleTerm)
      ar.length.should == 2
      ar.include?("creator").should == true
      ar.include?("teacher").should == true
      @mods_ds.get_values_from_solr(:name,{:role=>1},:roleTerm).should == ["submitter"]
    end
  end

  describe '.has_solr_name?' do
    it "should return true if the given key exists in the solr document passed in" do
      @test_ds.has_solr_name?("name_0_role_0_roleTerm_t",@solr_doc).should == true
      @test_ds.has_solr_name?(:name_0_role_0_roleTerm_t,@solr_doc).should == true
      @test_ds.has_solr_name?("name_1_role_1_roleTerm_t",@solr_doc).should == false
      #if not doc passed in should be new empty solr doc and always return false
      @test_ds.has_solr_name?("name_0_role_0_roleTerm_t").should == false
    end
  end

  describe '.is_hierarchical_term_pointer?' do
    it "should return true only if the pointer passed in is an array that contains a hash" do
      @test_ds.is_hierarchical_term_pointer?(*[:image,{:tag1=>1},:tag2]).should == true
      @test_ds.is_hierarchical_term_pointer?(*[:image,:tag1,{:tag2=>1}]).should == true
      @test_ds.is_hierarchical_term_pointer?(*[:image,:tag1,:tag2]).should == false
      @test_ds.is_hierarchical_term_pointer?(nil).should == false      
    end
  end

  describe '.update_values' do
    before(:each) do
      @mods_ds = ActiveFedora::NokogiriDatastream.new(nil, nil)
      @mods_ds.content= fixture(File.join("mods_articles","hydrangea_article1.xml")).read
    end

    it "should throw an exception if we have initialized the internal_solr_doc." do
      @mods_ds.from_solr(@solr_doc)
      found_exception = false
      begin
        @mods_ds.update_values([{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"})
      rescue
        found_exception = true
      end
      found_exception.should == true
    end

    it "should update a value internally call OM::XML::TermValueOperators::update_values if internal_solr_doc is not set" do
      @mods_ds.stubs(:om_update_values).once()
      term_pointer = [:name,:role,:roleTerm]
      @mods_ds.update_values([{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"})
    end

    it "should set @dirty to true" do
      mods_ds = Hydra::ModsArticleDatastream.new(nil, nil)
      mods_ds.content=fixture(File.join("mods_articles","hydrangea_article1.xml")).read
      mods_ds.update_values([{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"})
      mods_ds.dirty?.should be_true
    end
  end

  describe '.term_values' do

    before(:each) do
      @mods_ds = ActiveFedora::NokogiriDatastream.new(nil, nil)
      @mods_ds.content=fixture(File.join("mods_articles","hydrangea_article1.xml")).read
    end

    it "should call OM::XML::term_values if internal_solr_doc is not set and return values from xml" do
      @mods_ds.stubs(:om_term_values).once()
      term_pointer = [:name,:role,:roleTerm]
      @mods_ds.term_values(*term_pointer)
    end

    # we will know this is working because solr_doc and xml are not synced so that wrong return mechanism can be detected
    it "should call get_values_from_solr if internal_solr_doc is set" do
      @mods_ds.from_solr(@solr_doc)
      term_pointer = [:name,:role,:roleTerm]
      @mods_ds.stubs(:get_values_from_solr).once()
      @mods_ds.term_values(*term_pointer)
    end
  end
end
