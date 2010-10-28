require File.join( File.dirname(__FILE__), "../spec_helper" )
require "hydra"
describe ActiveFedora::NokogiriDatastream do
  
  before(:all) do
    @sample_fields = {:publisher => {:values => ["publisher1"], :type => :string}, 
                      :coverage => {:values => ["coverage1", "coverage2"], :type => :text}, 
                      :creation_date => {:values => "fake-date", :type => :date},
                      :mydate => {:values => "fake-date", :type => :date},
                      :empty_field => {:values => {}}
                      } 
    @sample_xml = XmlSimple.xml_in("<fields><coverage>coverage1</coverage><coverage>coverage2</coverage><creation_date>fake-date</creation_date><mydate>fake-date</mydate><publisher>publisher1</publisher></fields>")

    @solr_doc = {"id"=>"hydrange_article1","name_role_roleTerm_t"=>["creator","submitter","teacher"],"name_0_role_t"=>"\r\ncreator\r\nsubmitter\r\n","name_1_role_t"=>"\r\n teacher \r\n","name_0_role_0_roleTerm_t"=>"creator","name_0_role_1_roleTerm_t"=>"submitter","name_1_role_0_roleTerm_t"=>["teacher"]}
  end
  
  before(:each) do
    @test_ds = ActiveFedora::NokogiriDatastream.new(:blob=>"<test_xml/>")
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
      test_ds1 = ActiveFedora::NokogiriDatastream.new(:blob=>"<xml><foo/></xml>")
      test_ds1.ng_xml.to_xml.should == "<?xml version=\"1.0\"?>\n<xml>\n  <foo/>\n</xml>\n"
    end
    it "should initialize from #xml_template if no xml is provided" do
      ActiveFedora::NokogiriDatastream.expects(:xml_template).returns("fake template")
      ActiveFedora::NokogiriDatastream.new.ng_xml.should == "fake template"
    end
  end
  
  describe '#xml_template' do
    it "should return an empty xml document" do
      ActiveFedora::NokogiriDatastream.xml_template.to_xml.should == "<?xml version=\"1.0\"?>\n<xml/>\n"
    end
  end
  
  describe ".update_indexed_attributes" do
    
    before(:each) do
      @mods_ds = Hydra::SampleModsDatastream.new(:blob=>fixture(File.join("mods_articles","hydrangea_article1.xml")))
    end
    
    it "should apply submitted hash to corresponding datastream field values" do
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
      @mods_ds.update_indexed_attributes( { "fubar"=>"the role" } ).should == {}
      @mods_ds.to_xml.should == xml_before
    end
    it "should do nothing if there is no accessor corresponding to the given field key" do
      xml_before = @mods_ds.to_xml
      @mods_ds.update_indexed_attributes( { [{"fubar"=>"0"}]=>"the role" } ).should == {}
      @mods_ds.to_xml.should == xml_before
    end
    
    ### Examples copied over form metadata_datastream_spec
    
    # it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
    #   # In other words, { "fubar"=>"dork" } should have the same effect as { "fubar"=>{"0"=>"dork"} }
    #   pending "this should be working, but for some reason, the updates don't stick"
    #   result = @test_ds.update_indexed_attributes( { "fubar"=>"dork" } )
    #   result.should == {"fubar"=>{"0"=>"dork"}}
    #   @test_ds.fubar_values.should == ["dork"]
    # end
    # 
    it "should work for text fields" do 
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
      @mods_ds.get_values([{:title_info=>0},:main_title]).should == ["ARTICLE TITLE HYDRANGEA ARTICLE 1", "TITLE OF HOST JOURNAL"]
      result = @mods_ds.update_indexed_attributes [{"title_info"=>"0"},"main_title"]=>{"-1"=>"mork"}
      result.should == {"title_info_0_main_title"=>{"2"=>"mork"}}
    end
    # 
    # it "should return accurate response when multiple values have been added in a single run" do
    #   pending
    #   att= {"swank"=>{"-1"=>"mork", "0"=>"york"}}
    #   @test_ds.update_indexed_attributes(att).should == {"swank"=>{"0"=>"york", "1"=>"mork"}}
    # end
    
    # it "should deal gracefully with adding new values at explicitly declared indexes" do
    #   @mods_ds.update_indexed_attributes([:journal, :title]=>["all", "for", "the"]
    #   att = {"fubar"=>{"3"=>'glory'}}
    #   result = @test_ds.update_indexed_attributes(att)
    #   result.should == {"fubar"=>{"3"=>"glory"}}
    #   @test_ds.fubar_values.should == ["all", "for", "the", "glory"]
    #   
    #   @test_ds.fubar_values = []
    #   result = @test_ds.update_indexed_attributes(att)
    #   result.should == {"fubar"=>{"0"=>"glory"}}
    #   @test_ds.fubar_values.should == ["glory"]
    # end
    # 
    # it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
    #   att= {[{"person"=>"0"},"description"]=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}} 
    #   @mods_ds.update_indexed_attributes(att)
    #   @mods_ds.fubar_values.should == ['mork', 'york', 'mangle']
    #   rexml = REXML::Document.new(@test_ds.to_xml)
    #   #puts rexml.root.elements.each {|el| el.to_s}
    #   #puts rexml.root.elements.to_a.inspect
    #   rexml.root.elements.to_a.length.should == 3
    #   @mods_ds.update_indexed_attributes({[{"person"=>"0"},"description"]=>{"1"=>""}})
    #   @mods_ds.fubar_values.should == ['mork', 'mangle']
    #   rexml = REXML::Document.new(@test_ds.to_xml)
    #   rexml.root.elements.to_a.length.should == 2
    #   @mods_ds.update_indexed_attributes({[{"person"=>"0"},"description"]=>{"0"=>:delete}})
    #   @mods_ds.fubar_values.should == ['mangle']
    #   rexml = REXML::Document.new(@test_ds.to_xml)
    #   rexml.root.elements.to_a.length.should == 1
    # end
    it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
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
      @mods_ds.get_values([{:title_info=>0},:main_title]).should == ["ARTICLE TITLE HYDRANGEA ARTICLE 1", "TITLE OF HOST JOURNAL"]
      @mods_ds.update_indexed_attributes [{"title_info"=>"0"},"main_title"]=>{"-1"=>"mork"}
      @mods_ds.dirty?.should be_true
    end
  end
  
  describe ".get_values" do
    
    before(:each) do
      @mods_ds = Hydra::SampleModsDatastream.new(:blob=>fixture(File.join("mods_articles","hydrangea_article1.xml")))
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
    it "should assume field_names that are symbols or arrays are pointers to accessors declared in this datastreams model" do
      pending "This shouldn't be necessary -- OX::XML::PropertyValueOpertators.property_values deals with it internally..."
      ActiveFedora::NokogiriDatastream.expects(:accessor_xpath).with(:abstract).returns("--abstract xpath--")
      ActiveFedora::NokogiriDatastream.expects(:accessor_xpath).with(*[{:person=>1}]).returns("--person xpath--")
      ActiveFedora::NokogiriDatastream.expects(:accessor_xpath).with(*[{:person=>1},{:role=>1},:text]).returns("--person role text xpath--")     
      
      @mods_ds.expects(:property_values).with("--abstract xpath--").returns(["abstract1", "abstract2"])
      @mods_ds.expects(:property_values).with("--person xpath--").returns(["person1", "person2"])
      @mods_ds.expects(:property_values).with("--person role text xpath--").returns(["text1"])
      
      @mods_ds.get_values(:abstract).should == ["abstract1", "abstract2"]
      @mods_ds.get_values([{:person=>1}]).should == ["person1", "person2"]
      @mods_ds.get_values([{:person=>1},{:role=>1},:text]).should == ["text1"]
    end
  end
  
  describe '#from_xml' do
    it "should work when a template datastream is passed in" do
      mods_xml = Nokogiri::XML::Document.parse( fixture(File.join("mods_articles", "hydrangea_article1.xml")) )
      tmpl = Hydra::SampleModsDatastream.new
      Hydra::SampleModsDatastream.from_xml(mods_xml,tmpl).ng_xml.root.to_xml.should == mods_xml.root.to_xml
    end
    it "should work when foxml datastream xml is passed in" do
      pending "at least for now, just updated Base.deserialize to feed in the xml content rather than the foxml datstream xml.  Possibly we can update MetadataDatstream to assume the same and leave it at that? -MZ 23-06-2010"
      hydrangea_article_foxml = Nokogiri::XML::Document.parse( fixture("hydrangea_fixture_mods_article1.foxml.xml") )
      ds_xml = hydrangea_article_foxml.at_xpath("//foxml:datastream[@ID='descMetadata']")
      Hydra::SampleModsDatastream.from_xml(ds_xml).ng_xml.to_xml.should == hydrangea_article_foxml.at_xpath("//foxml:datastream[@ID='descMetadata']/foxml:datastreamVersion[last()]/foxml:xmlContent").first_element_child.to_xml
    end
    it "should set @dirty to false" do
      hydrangea_article_foxml = Nokogiri::XML::Document.parse( fixture("hydrangea_fixture_mods_article1.foxml.xml") )
      ds_xml = hydrangea_article_foxml.at_xpath("//foxml:datastream[@ID='descMetadata']")
      Hydra::SampleModsDatastream.from_xml(ds_xml).dirty?.should be_false
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

  describe '.from_solr' do
    it "should set the internal_solr_doc attribute to the solr document passed in" do 
      @test_ds.from_solr(@solr_doc)
      @test_ds.internal_solr_doc.should == @solr_doc
    end
  end

  describe '.get_values_from_solr' do
    before(:each) do
      @mods_ds = ActiveFedora::NokogiriDatastream.new(:blob=>fixture(File.join("mods_articles","hydrangea_article1.xml")))
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
      @mods_ds = ActiveFedora::NokogiriDatastream.new(:blob=>fixture(File.join("mods_articles","hydrangea_article1.xml")))
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
  end

  describe '.term_values' do

    before(:each) do
      @mods_ds = ActiveFedora::NokogiriDatastream.new(:blob=>fixture(File.join("mods_articles","hydrangea_article1.xml")))
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
