require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'active_fedora/metadata_datastream'

# include ActiveFedora::Datastream

describe ActiveFedora::MetadataDatastream do

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
    @test_ds = ActiveFedora::MetadataDatastream.new
  end
  
  after(:each) do
  end
  
  describe '#new' do
    it 'should provide #new' do
      ActiveFedora::MetadataDatastream.should respond_to(:new)
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
  
  describe ".update_indexed_attributes" do
    
    before(:each) do
      @test_ds.field "fubar", :string
      @test_ds.field "swank", :text
    end
    
    it "should apply submitted hash to corresponding datastream field values and mark the object dirty" do
      @test_ds.should_not be_dirty
      
      att= {"fubar"=>{"-1"=>"mork", "0"=>"york"}}
      @test_ds.update_indexed_attributes(att)
      @test_ds.fubar_values.should == ['mork', 'york']
      @test_ds.fubar_values.should == ['mork', 'york']

      att= {"fubar"=>{"0"=>"zork", "1"=>"tork", "2"=>'mangle'}}
      @test_ds.update_indexed_attributes(att)
      @test_ds.fubar_values.should == ['zork', 'tork', 'mangle']

      att= {"fubar"=>{"0"=>"hork", "1"=>"tork", '-1'=>'dang'}}
      result = @test_ds.update_indexed_attributes(att)
      result.should == {"fubar"=>{"0"=>"hork", "1"=>"tork", '3'=>'dang'}}
      @test_ds.fubar_values.should == ['hork', 'tork', 'mangle', 'dang']
      
      @test_ds.should be_dirty
    end
    
    it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
      # In other words, { "fubar"=>"dork" } should have the same effect as { "fubar"=>{"0"=>"dork"} }
      pending "this should be working, but for some reason, the updates don't stick"
      result = @test_ds.update_indexed_attributes( { "fubar"=>"dork" } )
      result.should == {"fubar"=>{"0"=>"dork"}}
      @test_ds.fubar_values.should == ["dork"]
    end
    
    it "should work for text fields" do 
      att= {"swank"=>{"-1"=>"mork", "1"=>"york"}}
      result = @test_ds.update_indexed_attributes(att)
      result.should == {"swank"=>{"1"=>"york", "0"=>"mork"}}
      @test_ds.swank_values.should == ['mork', 'york']
      att= {"swank"=>{"-1"=>"dork"}}
      result2 = @test_ds.update_indexed_attributes(att)
      result2.should == {"swank"=>{"2"=>"dork"}}
      @test_ds.swank_values.should == ['mork', 'york', 'dork']
    end
    
    it "should do nothing if there is no accessor corresponding to the given field key" do
      xml_before = @test_ds.to_xml
      @test_ds.update_indexed_attributes( { "style"=>"the style" } ).should == {}
      @test_ds.to_xml.should == xml_before
    end
    
    it "should return the new index of any added values" do
      @test_ds.swank_values = ["my_val1","my_val2"]
      result = @test_ds.update_indexed_attributes "swank"=>{"-1"=>"mork"}
      result.should == {"swank"=>{"2"=>"mork"}}
    end
    
    it "should return accurate response when multiple values have been added in a single run" do
      pending
      att= {"swank"=>{"-1"=>"mork", "0"=>"york"}}
      @test_ds.update_indexed_attributes(att).should == {"swank"=>{"0"=>"york", "1"=>"mork"}}
    end
    
    it "should deal gracefully with adding new values at explicitly declared indexes" do
      @test_ds.fubar_values = ["all", "for", "the"]
      att = {"fubar"=>{"3"=>'glory'}}
      result = @test_ds.update_indexed_attributes(att)
      result.should == {"fubar"=>{"3"=>"glory"}}
      @test_ds.fubar_values.should == ["all", "for", "the", "glory"]
      
      @test_ds.fubar_values = []
      result = @test_ds.update_indexed_attributes(att)
      result.should == {"fubar"=>{"0"=>"glory"}}
      @test_ds.fubar_values.should == ["glory"]
    end
    
    it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
      att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
      @test_ds.update_indexed_attributes(att)
      @test_ds.fubar_values.should == ['mork', 'york', 'mangle']
      rexml = REXML::Document.new(@test_ds.to_xml)
      #puts rexml.root.elements.each {|el| el.to_s}
      #puts rexml.root.elements.to_a.inspect
      rexml.root.elements.to_a.length.should == 3
      @test_ds.update_indexed_attributes({"fubar"=>{"1"=>""}})
      @test_ds.fubar_values.should == ['mork', 'mangle']
      rexml = REXML::Document.new(@test_ds.to_xml)
      rexml.root.elements.to_a.length.should == 2
      @test_ds.update_indexed_attributes({"fubar"=>{"0"=>:delete}})
      @test_ds.fubar_values.should == ['mangle']
      rexml = REXML::Document.new(@test_ds.to_xml)
      rexml.root.elements.to_a.length.should == 1
      
      @test_ds.fubar_values = ["val1", nil, "val2"]
      @test_ds.update_indexed_attributes({"fubar"=>{"1"=>""}})
      @test_ds.fubar_values.should == ["val1", "val2"]
    end
    
    it "should not get tripped up by field names wrapped in arrays" do
      att = {[:fubar]=>{"0"=>"eco3bv"}}
      @test_ds.update_indexed_attributes(att)
      @test_ds.fubar_values.should == ['eco3bv']
    end
    
  end
  
  describe ".get_values" do
    it "should call the _values method corresponding to the field_name" do
      @test_ds.expects(:abstract_values).returns(["val1", "val2"])
      @test_ds.get_values(:abstract).should == ["val1", "val2"]
    end
    it "should return a default value if one is supplied" do
      @test_ds.stubs(:abstract_values).returns([])
      @test_ds.get_values(:abstract, "default value").should == "default value"
      @test_ds.get_values(:abstract, nil).should == nil
    end
  end
  
  describe '.to_xml' do
    it "should provide .to_xml" do
      @test_ds.should respond_to(:to_xml)
    end
    it 'should output the fields hash as XML' do
      @test_ds.expects(:fields).returns(@sample_fields)
      returned_xml = XmlSimple.xml_in(@test_ds.to_xml)
      returned_xml.should == @sample_xml
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (mocked test)' do
      doc = Nokogiri::XML::Document.parse("<test_rexml/>")
      Nokogiri::XML::Builder.expects(:with).with(doc.root).returns(doc.root)      
      result = @test_ds.to_xml(doc)
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (functional test)' do
      @test_ds.expects(:fields).returns(@sample_fields)
      doc = Nokogiri::XML::Document.parse("<test_rexml/>")
      result = @test_ds.to_xml(doc)
      XmlSimple.xml_in(doc.to_s).should == @sample_xml
      XmlSimple.xml_in(result).should == @sample_xml
    end
    
    it 'should add to root of Nokogiri::XML::Documents, but add directly to the elements if a REXML::Element is passed in' do
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      el = Nokogiri::XML::Node.new("test_element", Nokogiri::XML::Document.new)
      Nokogiri::XML::Builder.expects(:with).with(doc.root).returns(doc.root)
      Nokogiri::XML::Builder.expects(:with).with(el).returns(el)
      @test_ds.to_xml(doc)
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
  
  describe '#field' do
    
    before(:each) do
      class SpecDatastream < ActiveFedora::MetadataDatastream
        def initialize
        super
        field :publisher, :string
        field :coverage, :text
        field :creation_date, :date
        field :mydate, :date
        field :mycomplicated_field, :string, :multiple=>false, :encoding=>'LCSH', :element_attrs=>{:foo=>:bar, :baz=>:bat}
        end
      end
    end
    
    after(:each) do
      Object.send(:remove_const, :SpecDatastream)
    end
    
    it 'should add corresponding field to the @fields hash and set the field :type ' do
      sds = SpecDatastream.new
      sds.fields.should_not have_key(:bio)
      sds.field :bio, :text
      sds.fields.should have_key(:bio)
      sds.fields[:bio].should have_key(:type)
      sds.fields[:bio][:type].should == :text
      sds.fields[:mycomplicated_field][:element_attrs].should == {:foo=>:bar, :baz=>:bat}
    end
    
    it "should insert custom element attrs into the xml stream" do
      sds = SpecDatastream.new
      sds.mycomplicated_field_values='foo'
      sds.fields[:mycomplicated_field][:element_attrs].should == {:foo=>:bar, :baz=>:bat}
      expected_xml = '<fields><mycomplicated_field baz=\'bat\' foo=\'bar\'>foo</mycomplicated_field></fields>'
      XmlSimple.xml_in(sds.to_xml).should == XmlSimple.xml_in(expected_xml)
    end
    
    it "should add getters and setters and appenders with field name" do
      local_test_ds = SpecDatastream.new
      local_test_ds.should respond_to(:publisher_values)
      local_test_ds.should respond_to(:publisher_append)
      local_test_ds.should respond_to(:publisher_values=)
      local_test_ds.publisher_values.class.should == Array
      local_test_ds.should respond_to(:coverage_values)
      local_test_ds.should respond_to(:coverage_values=)
      local_test_ds.should respond_to(:coverage_append)
      local_test_ds.should respond_to(:creation_date_values)
      local_test_ds.should respond_to(:creation_date_append)
      local_test_ds.should respond_to(:creation_date_values=)
      local_test_ds.should respond_to(:mydate_values)
      local_test_ds.should respond_to(:mydate_append)
      local_test_ds.should respond_to(:mydate_values=)
    end
    
    it "should track field values at instance level, not at class level" do
      local_test_ds1 = SpecDatastream.new
      local_test_ds2 = SpecDatastream.new
      local_test_ds1.publisher_values = ["publisher1", "publisher2"]
      local_test_ds2.publisher_values = ["publisherA", "publisherB"]
      
      local_test_ds2.publisher_values.should == ["publisherA", "publisherB"]      
      local_test_ds1.publisher_values.should == ["publisher1", "publisher2"]
    end
    
    it "should allow you to add field values using <<" do
      local_test_ds1 = SpecDatastream.new
      local_test_ds1.publisher_values << "publisher1"
      local_test_ds1.publisher_values.should == ["publisher1"] 
    end
    
    it "should create setter that always turns non-arrays into arrays" do
      local_test_ds = SpecDatastream.new
      local_test_ds.publisher_values = "Foo"
      local_test_ds.publisher_values.should == ["Foo"]
    end
    
    it "should create setter that sets datastream.dirty? to true" do
      local_test_ds = SpecDatastream.new
      local_test_ds.should_not be_dirty
      local_test_ds.publisher_values = "Foo"
      local_test_ds.should be_dirty
      
      # Note: If you use << to append values, the datastream will not be marked as dirty!
      #local_test_ds.dirty = false
      
      #local_test_ds.should_not be_dirty
      #local_test_ds.publisher_values << "Foo"
      #local_test_ds.should be_dirty      
    end
    
    it "should add any extra opts to the field hash" do
      local_test_ds = SpecDatastream.new
      local_test_ds.field "myfield", :string, :foo => "foo", :bar => "bar"      
      local_test_ds.fields[:myfield].should have_key(:foo)
      local_test_ds.fields[:myfield][:foo].should == "foo"
      local_test_ds.fields[:myfield].should have_key(:bar)
      local_test_ds.fields[:myfield][:bar].should == "bar"      
    end
    
  end
  
  describe ".to_solr" do
    
    after(:all) do
      # Revert to default mappings after running tests
      ActiveFedora::SolrService.load_mappings
    end
    
    it "should provide .to_solr and return a SolrDocument" do
      @test_ds.should respond_to(:to_solr)
      @test_ds.to_solr.should be_kind_of(Hash)
    end
    
    it "should optionally allow you to provide the Solr::Document to add fields to and return that document when done" do
      doc = Hash.new
      @test_ds.to_solr(doc).should equal(doc)
    end
    
    it "should iterate through @fields hash" do
      @test_ds.expects(:fields).returns(@sample_fields)
      solr_doc =  @test_ds.to_solr
      
      solr_doc["publisher_t"].should == ["publisher1"]
      solr_doc["coverage_t"].sort.should == ["coverage1", "coverage2"]
      solr_doc["creation_date_dt"].should == ["fake-date"]
      solr_doc["mydate_dt"].should == ["fake-date"]
      
      solr_doc["empty_field_t"].should be_nil
    end
    
    it "should allow multiple values for a single field"
    
    it 'should append create keys in format field_name + _ + field_type' do
      @test_ds.stubs(:fields).returns(@sample_fields)
      
      #should have these
            
      @test_ds.to_solr["publisher_t"].should_not be_nil
      @test_ds.to_solr["coverage_t"].should_not be_nil
      @test_ds.to_solr["creation_date_dt"].should_not be_nil
      
      #should NOT have these
      @test_ds.to_solr["narrator"].should be_nil
      @test_ds.to_solr["title"].should be_nil
      @test_ds.to_solr["empty_field"].should be_nil
      
    end
    
    it "should use Solr mappings to generate field names" do
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      @test_ds.stubs(:fields).returns(@sample_fields)
      solr_doc =  @test_ds.to_solr
      
      #should have these
            
      solr_doc["publisher_field"].should == ["publisher1"]
      solr_doc["coverage_field"].sort.should == ["coverage1", "coverage2"]
      solr_doc["creation_date_date"].should == ["fake-date"]
      solr_doc["mydate_date"].should == ["fake-date"]
      
      solr_doc["publisher_t"].should be_nil
      solr_doc["coverage_t"].should be_nil
      solr_doc["creation_date_dt"].should be_nil
      
      # Reload default mappings
      ActiveFedora::SolrService.load_mappings
    end
    
    it 'should append _dt to dates' do
      ActiveFedora::SolrService.load_mappings
      @test_ds.expects(:fields).returns(@sample_fields).at_least_once
      
      @test_ds.to_solr["creation_date_dt"].should_not be_nil
      @test_ds.to_solr["mydate_dt"].should_not be_nil
      
      #should NOT have these
      
      @test_ds.to_solr["mydate"].should be_nil
      @test_ds.to_solr["creation_date_date"].should be_nil
    end
    
  end
  
  describe '.fields' do
    it "should return a Hash" do
      @test_ds.fields.should be_instance_of(Hash)
    end
  end
  
end
