require File.join( File.dirname(__FILE__), "../spec_helper" )

describe ActiveFedora::Base do
  
  before(:each) do
    Fedora::Repository.instance.expects(:nextid).returns("__nextid__")
    @test_object = ActiveFedora::Base.new
    #Fedora::Repository.instance.delete(@test_object.inner_object)
  end
  
  describe '.generate_dsid' do
    it "should return a dsid that is not currently in use" do
      dsids = Hash["DS1"=>1, "DS2"=>1]
      @test_object.expects(:datastreams).returns(dsids)
      generated_id = @test_object.generate_dsid
      generated_id.should_not be_nil
      generated_id.should == "DS3"
    end
    it "should accept a prefix argument, default to using DS as prefix" do
      @test_object.generate_dsid("FOO").should == "FOO1"  
    end
  end
  describe '.add_datastream' do
    it "should not call Datastream.save" do
      ds = ActiveFedora::Datastream.new(:dsid => 'ds_to_add')
      ds.expects(:save).never
      @test_object.add_datastream(ds)
    end
    it "should add the datastream to the datastreams_in_memory array" do
      ds = ActiveFedora::Datastream.new(:dsID => 'ds_to_add')
      @test_object.datastreams.should_not have_key(ds.dsid)
      @test_object.add_datastream(ds)
      @test_object.datastreams_in_memory.should have_key(ds.dsid)
    end
    it "should auto-assign dsids using auto-incremented integers if dsid is nil or an empty string" do 
      ds = ActiveFedora::Datastream.new()
      ds.dsid.should == nil
      ds_emptystringid = ActiveFedora::Datastream.new()
      ds_emptystringid.dsid = ""
      @test_object.expects(:generate_dsid).returns("foo").times(2)
      ds.expects(:dsid=).with("foo")
      @test_object.add_datastream(ds)
      @test_object.add_datastream(ds_emptystringid)
    end
    it "should accept a prefix option and apply it to automatically assigned dsids" do
      ds = ActiveFedora::Datastream.new()
      ds.dsid.should == nil
      @test_object.expects(:generate_dsid).with("FOO")
      @test_object.add_datastream(ds, :prefix => "FOO")
    end
  end

  describe '.datastreams' do
    it "if the object is not new should call .datastreams_in_fedora and put the result into @datastreams" do
      @test_object.instance_variable_set(:@new_object, false)
      ivar_before = @test_object.instance_variable_get(:@datastreams).dup
      @test_object.expects(:datastreams_in_fedora).returns({:meh=>'feh'})
      datastreams = @test_object.datastreams
      @test_object.instance_variable_get(:@datastreams).values.should == ['feh']
      datastreams.values.should ==['feh']
      @test_object.instance_variable_get(:@datastreams).should_not equal(ivar_before)
    end
  end

  describe '.datastreams_in_memory' do
    it "should return the @datastreams array" do
      the_ivar = @test_object.instance_variable_set(:@datastreams, {})
      @test_object.datastreams_in_memory.should equal(the_ivar)
    end
  end

  describe '.datastreams_in_fedora' do
    it "should read the datastreams list from fedora" do
      @test_object.expects(:datastreams_xml).returns(Hash['datastream' => Hash[]])
      @test_object.datastreams_in_fedora
    end
    it "should pull the dsLabel if it is set" do
      @test_object.expects(:datastreams_xml).returns({"datastream"=>[
        {"label"=>"Dublin Core Record for this object", "dsid"=>"DC", "mimeType"=>"text/xml"}, 
        {"label"=>"", "dsid"=>"RELS-EXT", "mimeType"=>"text/xml"}, 
        {"label"=>"Sample Image", "dsid"=>"IMAGE1", "mimeType"=>"image/png"}]})
      result = @test_object.datastreams_in_fedora
      result["DC"].label.should == "Dublin Core Record for this object"
      result["RELS-EXT"].label.should == ""
      result["IMAGE1"].label.should == "Sample Image"
    end
    
    it "should pull the mimeType if it is set" do
      pending
      # Implementing this would require re-workign the initializer in Fedora::Datastream
      @test_object.expects(:datastreams_xml).returns({"datastream"=>[
        {"label"=>"Dublin Core Record for this object", "dsid"=>"DC", "mimeType"=>"text/xml"}, 
        {"label"=>"", "dsid"=>"RELS-EXT", "mimeType"=>"text/xml"}, 
        {"label"=>"Sample Image", "dsid"=>"IMAGE1", "mimeType"=>"image/png"}]})
      result = @test_object.datastreams_in_fedora
      result["DC"].attributes[:mimeType].should == "text/xml"
      result["RELS-EXT"].attributes[:mimeType].should == "text/xml"
      result["IMAGE1"].attributes[:mimeType].should == "image/png"
    end
  end

  describe 'add' do
    it "should call .add_datastream" do
      @test_object.expects(:add_datastream)
      @test_object.add(stub("datastream").stub_everything)
    end
  end
  
  describe 'refresh' do
    it "should pull object attributes from Fedora then merge the contents of .datastreams_in_fedora and .datastreams_in_memory, giving preference to the ones in memory" do 
      @test_object.stubs(:datastreams_in_fedora).returns({:foo => "foo", :bar => "bar in fedora"})
      @test_object.stubs(:datastreams_in_memory).returns({:baz => "baz", :bar => "bar in memory"})
      @test_object.inner_object.expects(:load_attributes_from_fedora)
      result = @test_object.refresh
      result.should == {:foo => "foo", :baz => "baz", :bar => "bar in memory"}
      @test_object.instance_variable_get(:@datastreams).should == result
    end
  end
end