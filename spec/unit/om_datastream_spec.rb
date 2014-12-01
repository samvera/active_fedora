require 'spec_helper'

describe ActiveFedora::OmDatastream do

  subject { ActiveFedora::OmDatastream.new }
  it { should be_metadata }

  it "should include the Solrizer::XML::TerminologyBasedSolrizer for .to_solr support" do
    expect(ActiveFedora::OmDatastream.included_modules).to include(OM::XML::TerminologyBasedSolrizer)
  end

  describe '#new' do
    it 'should load xml from blob if provided' do
      test_ds1 = ActiveFedora::OmDatastream.new
      test_ds1.content="<xml><foo/></xml>"
      expect(test_ds1.ng_xml.to_xml).to be_equivalent_to("<?xml version=\"1.0\"?>\n<xml>\n  <foo/>\n</xml>\n")
    end

    it "should initialize from #xml_template if no xml is provided" do
      expect(ActiveFedora::OmDatastream).to receive(:xml_template).and_return("<fake template/>")
      n = ActiveFedora::OmDatastream.new
      expect(n.ng_xml).to be_equivalent_to("<fake template/>")
    end
  end

  describe "#prefix" do
    subject { ActiveFedora::OmDatastream.new }
    it "should reflect the dsid" do
      expect(subject.send(:prefix, 'descMetadata')).to eq "desc_metadata__"
    end
  end

  describe '#xml_template' do
    subject { ActiveFedora::OmDatastream.xml_template.to_xml }
    it "should return an empty xml document" do
      expect(subject).to be_equivalent_to("<?xml version=\"1.0\"?>\n<xml/>\n")
    end
  end

  describe "to_solr" do
    describe "with a dsid" do
      subject { ActiveFedora::OmDatastream.new.to_solr }
      it { should be_empty }
    end

    describe "when prefix is set" do
      before do 
        class MyDatastream < ActiveFedora::OmDatastream
          set_terminology do |t|
            t.root(:path=>"mods")
            t.title(:index_as=>[:stored_searchable])
          end

          def prefix(_)
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
      @mods_ds = Hydra::ModsArticleDatastream.new
      @mods_ds.content=fixture(File.join("mods_articles","mods_article1.xml")).read
    end
    
    it "should apply submitted hash to corresponding datastream field values" do
      result = @mods_ds.update_indexed_attributes( {[{":person"=>"0"}, "role"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} })
      expect(result).to eq("person_0_role"=>["role1", "role2", "role3"])
      expect(@mods_ds.property_values('//oxns:name[@type="personal"][1]/oxns:role')).to eq ["role1","role2","role3"]
    end
    it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
      # In other words, { "fubar"=>"dork" } should have the same effect as { "fubar"=>{"0"=>"dork"} }
      result = @mods_ds.update_indexed_attributes( { [{":person"=>"0"}, "role"]=>"the role" } )
      expect(result).to eq("person_0_role"=>["the role"])
      expect(@mods_ds.term_values('//oxns:name[@type="personal"][1]/oxns:role').first).to eq "the role"
    end
    it "should do nothing if field key is a string (must be an array or symbol).  Will not accept xpath queries!" do
      xml_before = @mods_ds.to_xml
      expect(ActiveFedora::Base.logger).to receive(:warn).with "WARNING: Hydra::ModsArticleDatastream ignoring {\"fubar\" => \"the role\"} because \"fubar\" is a String (only valid OM Term Pointers will be used).  Make sure your html has the correct field_selector tags in it."
      expect(@mods_ds.update_indexed_attributes( { "fubar"=>"the role" } )).to eq({})
      expect(@mods_ds.to_xml).to eq xml_before
    end
    it "should do nothing if there is no accessor corresponding to the given field key" do
      xml_before = @mods_ds.to_xml
      expect(@mods_ds.update_indexed_attributes( { [{"fubar"=>"0"}]=>"the role" } )).to eq({})
      expect(@mods_ds.to_xml).to eq xml_before
    end
    
    ### Examples copied over form metadata_datastream_spec
    
    it "should work for text fields" do 
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"mork", "1"=>"york"}}
      result = @mods_ds.update_indexed_attributes(att)
      expect(result).to eq("person_0_description"=>["mork","york"])
      expect(@mods_ds.get_values([{:person=>0},:description])).to eq ['mork', 'york']
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"dork"}}
      result2 = @mods_ds.update_indexed_attributes(att)
      expect(result2).to eq("person_0_description"=>["dork"])
      expect(@mods_ds.get_values([{:person=>0},:description])).to eq ['dork']
    end
    
    it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
      att= {[{"person"=>"0"},"description"]=>{"0"=>"york", "1"=>"mangle","2"=>"mork"}}
      @mods_ds.update_indexed_attributes(att)
      expect(@mods_ds.get_values([{"person"=>"0"},"description"])).to eq ['york', 'mangle', 'mork']
      
      @mods_ds.update_indexed_attributes({[{"person"=>"0"},{"description" => '1'} ]=> nil})
      expect(@mods_ds.get_values([{"person"=>"0"},"description"])).to eq ['york', 'mork']
      
      @mods_ds.update_indexed_attributes({[{"person"=>"0"},{"description" => '0'}]=>:delete})
      expect(@mods_ds.get_values([{"person"=>"0"},"description"])).to eq ['mork']
    end
    
    it "should set changed to true" do
      expect(@mods_ds.get_values([{:title_info=>0},:main_title])).to eq ["ARTICLE TITLE", "TITLE OF HOST JOURNAL"]
      @mods_ds.update_indexed_attributes [{"title_info"=>"0"},"main_title"]=>{"-1"=>"mork"}
      expect(@mods_ds).to be_changed
    end
  end
  
  describe ".get_values" do
    
    before(:each) do
      @mods_ds = Hydra::ModsArticleDatastream.new
      @mods_ds.content=fixture(File.join("mods_articles","mods_article1.xml")).read
    end
    
    it "should call lookup with field_name and return the text values from each resulting node" do
      expect(@mods_ds).to receive(:term_values).with("--my xpath--").and_return(["value1", "value2"])
      expect(@mods_ds.get_values("--my xpath--")).to eq ["value1", "value2"]
    end
    it "should assume that field_names that are strings are xpath queries" do
      expect(ActiveFedora::OmDatastream).to receive(:accessor_xpath).never
      expect(@mods_ds).to receive(:term_values).with("--my xpath--").and_return(["abstract1", "abstract2"])
      expect(@mods_ds.get_values("--my xpath--")).to eq ["abstract1", "abstract2"]
    end
  end

  describe '.save' do
    let(:base_path) { '/foo' }

    let(:ldp_source) { Ldp::Resource.new(mock_client, nil, nil, base_path) }

    let(:conn_stubs) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(base_path) { [200, {'Last-Modified' => 'Tue, 22 Jul 2014 02:23:32 GMT' }] }
      end
    end

    let(:mock_conn) do
      test = Faraday.new do |builder|
        builder.adapter :test, conn_stubs do |stub|
        end
      end
    end

    let :mock_client do
      Ldp::Client.new mock_conn
    end

    before do
      allow(subject).to receive(:ldp_source).and_return(ldp_source)
    end

    it "should persist the product of .to_xml in fedora" do
      subject.serialize!
      subject.save
      expect(subject.mime_type).to eq 'text/xml'
    end
  end

  describe 'setting content' do
    subject { ActiveFedora::OmDatastream.new }
    before { subject.content = "<a />" }

    it "should update the content" do
      expect(subject.content).to eq "<?xml version=\"1.0\"?>\n<a/>"
    end

    it "should mark the object as changed" do
      expect(subject).to be_changed
    end

    it "update ngxml and mark the xml as loaded" do
      expect(subject.ng_xml.to_xml).to match /<a\/>/
      expect(subject.xml_loaded).to be true
    end
  end

  describe 'ng_xml=' do
    let(:sample_raw_xml) { "<foo><xmlelement/></foo>" }

    subject { ActiveFedora::OmDatastream.new }

    it "should parse raw xml for you" do
      subject.ng_xml = sample_raw_xml
      expect(subject.ng_xml).to be_kind_of Nokogiri::XML::Document
      expect(subject.ng_xml.to_xml).to be_equivalent_to(sample_raw_xml)
    end

    it "Should always set a document when an Element is passed" do
      subject.ng_xml = Nokogiri::XML(sample_raw_xml).xpath('//xmlelement').first
      expect(subject.ng_xml).to be_kind_of Nokogiri::XML::Document
      expect(subject.ng_xml.to_xml).to be_equivalent_to("<xmlelement/>")
    end

    it "should mark the datastream as changed" do
      expect {
        subject.ng_xml = sample_raw_xml
      }.to change { subject.changed? }.from(false).to(true)
    end
  end

  describe '.to_xml' do
    let(:doc) { Nokogiri::XML::Document.parse("<text_document/>") }

    it "should ng_xml.to_xml" do
      allow(subject).to receive(:ng_xml).and_return(doc)
      expect(subject.to_xml).to eq "<?xml version=\"1.0\"?>\n<text_document/>"
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (mocked test)' do
      expect(doc.root).to receive(:add_child)#.with(test_ds.ng_xml.root)
      subject.to_xml(doc)
    end
    
    context "with some existing content" do
      before do
        subject.content="<test_xml/>"
      end
      it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (functional test)' do
        expected_result = "<test_document><foo/><test_xml/></test_document>"
        doc = Nokogiri::XML::Document.parse("<test_document><foo/></test_document>")
        result = subject.to_xml(doc)
        expect(doc).to be_equivalent_to expected_result
        expect(result).to be_equivalent_to expected_result
      end

      it 'should add to root of Nokogiri::XML::Documents, but add directly to the elements if a Nokogiri::XML::Node is passed in' do
        doc = Nokogiri::XML::Document.parse("<test_document/>")
        el = Nokogiri::XML::Node.new("test_element", Nokogiri::XML::Document.new)
        expect(subject.to_xml(doc)).to be_equivalent_to "<test_document><test_xml/></test_document>"
        expect(subject.to_xml(el)).to be_equivalent_to "<test_element/>"
      end
    end
    
  end
  

  describe '.has_solr_name?' do
    let(:name0_role0) { ActiveFedora::SolrQueryBuilder.solr_name("desc_metadata__name_0_role_0_roleTerm", type: :string) }
    let(:name1_role1) { ActiveFedora::SolrQueryBuilder.solr_name("desc_metadata__name_1_role_1_roleTerm", type: :string) }
    let(:solr_doc) do
      {"id"=>"mods_article1",
      ActiveFedora::SolrQueryBuilder.solr_name("desc_metadata__name_role_roleTerm", type: :string) =>["creator","submitter","teacher"],
      ActiveFedora::SolrQueryBuilder.solr_name("desc_metadata__name_0_role", type: :string)=>"\r\ncreator\r\nsubmitter\r\n",
      ActiveFedora::SolrQueryBuilder.solr_name("desc_metadata__name_1_role", type: :string)=>"\r\n teacher \r\n",
      name0_role0 =>"creator",
      ActiveFedora::SolrQueryBuilder.solr_name("desc_metadata__name_0_role_1_roleTerm", type: :string)=>"submitter",
      ActiveFedora::SolrQueryBuilder.solr_name("desc_metadata__name_1_role_0_roleTerm", type: :string)=>["teacher"]}
    end

    it "should return true if the given key exists in the solr document passed in" do
      expect(subject).to have_solr_name(name0_role0, solr_doc)
      expect(subject).to have_solr_name(name0_role0.to_sym, solr_doc)
      expect(subject).to_not have_solr_name(name1_role1, solr_doc)
      #if not doc passed in should be new empty solr doc and always return false
      expect(subject).to_not have_solr_name(name0_role0)
    end
  end

  describe '.is_hierarchical_term_pointer?' do
    it "should return true only if the pointer passed in is an array that contains a hash" do
      expect(subject.is_hierarchical_term_pointer?(*[:image,{:tag1=>1},:tag2])).to be true
      expect(subject.is_hierarchical_term_pointer?(*[:image,:tag1,{:tag2=>1}])).to be true
      expect(subject.is_hierarchical_term_pointer?(*[:image,:tag1,:tag2])).to be false
      expect(subject.is_hierarchical_term_pointer?(nil)).to be false      
    end
  end

  describe '.update_values' do

    subject { ActiveFedora::OmDatastream.new }

    before { subject.content= fixture(File.join("mods_articles","mods_article1.xml")).read }

    it "should update a value internally call OM::XML::TermValueOperators::update_values if internal_solr_doc is not set" do
      expect(subject).to receive(:om_update_values)
      subject.update_values([{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"})
    end

    it "should set changed to true" do
      subject.update_values([{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"})
      expect(subject).to be_changed
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
      expect(@obj).to_not receive(:content)
      expect(subject).to_not be_content_changed
    end
  end
end
