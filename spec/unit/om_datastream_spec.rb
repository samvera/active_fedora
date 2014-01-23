require 'spec_helper'
describe ActiveFedora::OmDatastream do
  
  before(:all) do
    @sample_fields = {:publisher => {:values => ["publisher1"], :type => :string}, 
                      :coverage => {:values => ["coverage1", "coverage2"], :type => :text}, 
                      :creation_date => {:values => "fake-date", :type => :date},
                      :mydate => {:values => "fake-date", :type => :date},
                      :empty_field => {:values => {}}
                      } 
    @sample_raw_xml = "<foo><xmlelement/></foo>"
    @solr_doc = {"id"=>"mods_article1",
      ActiveFedora::SolrService.solr_name("name_role_roleTerm", type: :string) =>["creator","submitter","teacher"],
      ActiveFedora::SolrService.solr_name("name_0_role", type: :string)=>"\r\ncreator\r\nsubmitter\r\n",
      ActiveFedora::SolrService.solr_name("name_1_role", type: :string)=>"\r\n teacher \r\n",
      ActiveFedora::SolrService.solr_name("name_0_role_0_roleTerm", type: :string)=>"creator",
      ActiveFedora::SolrService.solr_name("name_0_role_1_roleTerm", type: :string)=>"submitter",
      ActiveFedora::SolrService.solr_name("name_1_role_0_roleTerm", type: :string)=>["teacher"]}
  end
  
  before(:each) do
    @mock_inner = double('inner object')
    @mock_repo = double('repository')
    @mock_repo.stub(:datastream_dissemination=>'My Content', :config=>{}, :datastream_profile=>{})
    @mock_inner.stub(:repository).and_return(@mock_repo)
    @mock_inner.stub(:pid)
    @mock_inner.stub(:new_record? => false)
    @test_ds = ActiveFedora::OmDatastream.new(@mock_inner, "descMetadata")
    @test_ds.stub(:new? => false, :profile => {}, :datastream_content => '<test_xml/>')
    @test_ds.content="<test_xml/>"
    @test_ds.stub(:new? => false)
  end
  
  its(:metadata?) { should be_true}

  its(:controlGroup) { should == "M"}

  it "should include the Solrizer::XML::TerminologyBasedSolrizer for .to_solr support" do
    ActiveFedora::OmDatastream.included_modules.should include(OM::XML::TerminologyBasedSolrizer)
  end
  
  describe '#new' do
    it 'should provide #new' do
      ActiveFedora::OmDatastream.should respond_to(:new)
      @test_ds.ng_xml.should be_instance_of(Nokogiri::XML::Document)
    end
    it 'should load xml from blob if provided' do
      test_ds1 = ActiveFedora::OmDatastream.new(nil, 'ds1')
      test_ds1.content="<xml><foo/></xml>"
      test_ds1.ng_xml.to_xml.should == "<?xml version=\"1.0\"?>\n<xml>\n  <foo/>\n</xml>\n"
    end
    it "should initialize from #xml_template if no xml is provided" do
      ActiveFedora::OmDatastream.should_receive(:xml_template).and_return("<fake template/>")
      n = ActiveFedora::OmDatastream.new
      n.ng_xml.should be_equivalent_to("<fake template/>")
    end
  end

  describe "#prefix" do
    subject { ActiveFedora::OmDatastream.new(nil, 'descMetadata') }
    it "should be an empty string (until active-fedora 8. Then it should be \"\#{dsid.underscore}__\"" do
      subject.send(:prefix).should == ""
    end
  end
  
  describe '#xml_template' do
    it "should return an empty xml document" do
      ActiveFedora::OmDatastream.xml_template.to_xml.should == "<?xml version=\"1.0\"?>\n<xml/>\n"
    end
  end

  describe "to_solr" do
    describe "with a dsid" do
      subject { ActiveFedora::OmDatastream.new(@mock_inner, "descMetadata") }
      its(:to_solr) {should == { }}
    end
    describe "without a dsid" do
      subject { ActiveFedora::OmDatastream.new }
      it "should raise an error" do
        expect{subject.to_solr}.to raise_error RuntimeError, "to_solr requires the dsid to be set"
      end
    end

    describe "when prefix is set" do
      before do 
        class MyDatastream < ActiveFedora::OmDatastream
          set_terminology do |t|
            t.root(:path=>"mods")
            t.title(:index_as=>[:stored_searchable])
          end
          def prefix
            "foo__"
          end
        end
        subject.title = 'Science'
      end
      after do
        Object.send(:remove_const, :MyDatastream)
      end
      subject { MyDatastream.new }
      it "should use the prefix" do
        expect(subject.to_solr).to have_key('foo__title_tesim')
      end
      it "should not prefix fields that aren't defined by this datastream" do
        expect(subject.to_solr('id' => 'test:123')).to have_key('id')
      end
    end
  end
  
  describe ".update_indexed_attributes" do
    
    before(:each) do
      @mods_ds = Hydra::ModsArticleDatastream.new(nil, 'descMetadata')
      @mods_ds.content=fixture(File.join("mods_articles","mods_article1.xml")).read
    end
    
    it "should apply submitted hash to corresponding datastream field values" do
      result = @mods_ds.update_indexed_attributes( {[{":person"=>"0"}, "role"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} })
      result.should == {"person_0_role"=>["role1", "role2", "role3"]}
      @mods_ds.property_values('//oxns:name[@type="personal"][1]/oxns:role').should == ["role1","role2","role3"]
    end
    it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
      # In other words, { "fubar"=>"dork" } should have the same effect as { "fubar"=>{"0"=>"dork"} }
      result = @mods_ds.update_indexed_attributes( { [{":person"=>"0"}, "role"]=>"the role" } )
      result.should == {"person_0_role"=>["the role"]}
      @mods_ds.term_values('//oxns:name[@type="personal"][1]/oxns:role').first.should == "the role"
    end
    it "should do nothing if field key is a string (must be an array or symbol).  Will not accept xpath queries!" do
      xml_before = @mods_ds.to_xml
      logger.should_receive(:warn).with "WARNING: descMetadata ignoring {\"fubar\" => \"the role\"} because \"fubar\" is a String (only valid OM Term Pointers will be used).  Make sure your html has the correct field_selector tags in it."
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
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"mork", "1"=>"york"}}
      result = @mods_ds.update_indexed_attributes(att)
      result.should == {"person_0_description"=>["mork","york"]}
      @mods_ds.get_values([{:person=>0},:description]).should == ['mork', 'york']
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"dork"}}
      result2 = @mods_ds.update_indexed_attributes(att)
      result2.should == {"person_0_description"=>["dork"]}
      @mods_ds.get_values([{:person=>0},:description]).should == ['dork']
    end
    
    it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
      att= {[{"person"=>"0"},"description"]=>{"0"=>"york", "1"=>"mangle","2"=>"mork"}}
      @mods_ds.update_indexed_attributes(att)
      @mods_ds.get_values([{"person"=>"0"},"description"]).should == ['york', 'mangle', 'mork']
      
      @mods_ds.update_indexed_attributes({[{"person"=>"0"},{"description" => '1'} ]=> nil})
      @mods_ds.get_values([{"person"=>"0"},"description"]).should == ['york', 'mork']
      
      @mods_ds.update_indexed_attributes({[{"person"=>"0"},{"description" => '0'}]=>:delete})
      @mods_ds.get_values([{"person"=>"0"},"description"]).should == ['mork']
    end
    
    it "should set changed to true" do
      @mods_ds.get_values([{:title_info=>0},:main_title]).should == ["ARTICLE TITLE", "TITLE OF HOST JOURNAL"]
      @mods_ds.update_indexed_attributes [{"title_info"=>"0"},"main_title"]=>{"-1"=>"mork"}
      @mods_ds.should be_changed
    end
  end
  
  describe ".get_values" do
    
    before(:each) do
      @mods_ds = Hydra::ModsArticleDatastream.new(nil, 'modsDs')
      @mods_ds.content=fixture(File.join("mods_articles","mods_article1.xml")).read
    end
    
    it "should call lookup with field_name and return the text values from each resulting node" do
      @mods_ds.should_receive(:term_values).with("--my xpath--").and_return(["value1", "value2"])
      @mods_ds.get_values("--my xpath--").should == ["value1", "value2"]
    end
    it "should assume that field_names that are strings are xpath queries" do
      ActiveFedora::OmDatastream.should_receive(:accessor_xpath).never
      @mods_ds.should_receive(:term_values).with("--my xpath--").and_return(["abstract1", "abstract2"])
      @mods_ds.get_values("--my xpath--").should == ["abstract1", "abstract2"]
    end
  end

  describe '.save' do
    it "should provide .save" do
      @test_ds.should respond_to(:save)
    end
    it "should persist the product of .to_xml in fedora" do
      @mock_repo.stub(:datastream).and_return('')
      @test_ds.stub(:new? => true)
      @test_ds.stub(:ng_xml_changed? => true)
      @test_ds.stub(:to_xml => "fake xml")
      @mock_repo.should_receive(:add_datastream).with(:pid => nil, :dsid => 'descMetadata', :versionable => true, :content => 'fake xml', :controlGroup => 'M', :dsState => 'A', :mimeType=>'text/xml')

      @test_ds.serialize!
      @test_ds.save
      @test_ds.mimeType.should == 'text/xml'
    end
  end
  
  describe 'setting content' do
    subject { ActiveFedora::OmDatastream.new(@mock_inner, "descMetadata") }
    it "should update the content" do
      subject.stub(:new? => false )
      subject.content = "<a />"
      subject.content.should == '<a/>'
    end

    it "should mark the object as changed" do
      subject.stub(:new? => false, :controlGroup => 'M')
      subject.content = "<a />"
      subject.should be_changed
    end

    it "update ngxml and mark the xml as loaded" do
      subject.stub(:new? => false )
      subject.content = "<a />"
      subject.ng_xml.to_xml.should =~ /<a\/>/
      subject.xml_loaded.should be_true
    end
  end
  
  describe 'ng_xml=' do
    before do
      @mock_inner.stub(:new_record? => true)
      @test_ds2 = ActiveFedora::OmDatastream.new(@mock_inner, "descMetadata")
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
    it "should mark the datastream as changed" do
      @test_ds2.stub(:new? => false, :controlGroup => 'M')
      @test_ds2.should_not be_changed 
      @test_ds2.ng_xml = @sample_raw_xml
      @test_ds2.should be_changed
    end
  end
  
  describe '.to_xml' do
    it "should provide .to_xml" do
      @test_ds.should respond_to(:to_xml)
    end
    
    it "should ng_xml.to_xml" do
      @test_ds.stub(:ng_xml => Nokogiri::XML::Document.parse("<text_document/>"))
      @test_ds.to_xml.should == "<text_document/>"       
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (mocked test)' do
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      doc.root.should_receive(:add_child)#.with(@test_ds.ng_xml.root)
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
      @mods_ds = ActiveFedora::OmDatastream.new
      @mods_ds.content=fixture(File.join("mods_articles","mods_article1.xml")).read
    end

    it "should return empty array if internal_solr_doc not set" do
      @mods_ds.get_values_from_solr(:name,:role,:roleTerm)
    end
 
    it "should return correct values from solr_doc given different term pointers" do
      mock_term = double("OM::XML::Term")
      mock_term.stub(:type).and_return(:text)
      mock_terminology = double("OM::XML::Terminology")
      mock_terminology.stub(:retrieve_term).and_return(mock_term)
      ActiveFedora::OmDatastream.stub(:terminology).and_return(mock_terminology)
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
      @test_ds.has_solr_name?(ActiveFedora::SolrService.solr_name("name_0_role_0_roleTerm", type: :string),@solr_doc).should == true
      @test_ds.has_solr_name?(ActiveFedora::SolrService.solr_name("name_0_role_0_roleTerm", type: :string).to_sym,@solr_doc).should == true
      @test_ds.has_solr_name?(ActiveFedora::SolrService.solr_name("name_1_role_1_roleTerm", type: :string),@solr_doc).should == false
      #if not doc passed in should be new empty solr doc and always return false
      @test_ds.has_solr_name?(ActiveFedora::SolrService.solr_name("name_0_role_0_roleTerm", type: :string)).should == false
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
      @mods_ds = ActiveFedora::OmDatastream.new
      @mods_ds.content= fixture(File.join("mods_articles","mods_article1.xml")).read
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
      @mods_ds.stub(:om_update_values).once()
      term_pointer = [:name,:role,:roleTerm]
      @mods_ds.update_values([{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"})
    end

    it "should set changed to true" do
      mods_ds = Hydra::ModsArticleDatastream.new
      mods_ds.content=fixture(File.join("mods_articles","mods_article1.xml")).read
      mods_ds.update_values([{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"})
      mods_ds.should be_changed
    end
  end

  describe '.term_values' do

    before(:each) do
      @mods_ds = ActiveFedora::OmDatastream.new
      @mods_ds.content=fixture(File.join("mods_articles","mods_article1.xml")).read
    end

    it "should call OM::XML::term_values if internal_solr_doc is not set and return values from xml" do
      @mods_ds.stub(:om_term_values).once()
      term_pointer = [:name,:role,:roleTerm]
      @mods_ds.term_values(*term_pointer)
    end

    # we will know this is working because solr_doc and xml are not synced so that wrong return mechanism can be detected
    it "should call get_values_from_solr if internal_solr_doc is set" do
      @mods_ds.from_solr(@solr_doc)
      term_pointer = [:name,:role,:roleTerm]
      @mods_ds.stub(:get_values_from_solr).once()
      @mods_ds.term_values(*term_pointer)
    end
  end

  describe "an instance that exists in the datastore, but hasn't been loaded" do
    before do 
      class MyObj < ActiveFedora::Base
        has_metadata 'descMetadata', type: Hydra::ModsArticleDatastream
      end
      @obj = MyObj.new
      @obj.descMetadata.title = 'Foobar'
      @obj.save
    end
    after do
      @obj.destroy
      Object.send(:remove_const, :MyObj)
    end
    subject { @obj.reload.descMetadata } 
    it "should not load the descMetadata datastream when calling content_changed?" do
      @obj.inner_object.repository.should_not_receive(:datastream_dissemination).with(hash_including(:dsid=>'descMetadata'))
      subject.should_not be_content_changed
    end
  end
end
