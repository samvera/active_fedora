require 'spec_helper'

describe ActiveFedora::Datastreams do
  before do
    @test_object = ActiveFedora::Base.new
  end

  describe "#create_datastream" do
    it 'should create a datastream object using the type of object supplied in the string (does reflection)' do
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:blob=>f})
      ds.class.should == ActiveFedora::Datastream
      ds.dsLabel.should == "minivan.jpg"
      ds.mimeType.should == "image/jpeg"
    end
    it 'should create a datastream object from a string' do
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:blob=>"My file data"})
      ds.class.should == ActiveFedora::Datastream
      ds.dsLabel.should == nil
      ds.mimeType.should == "application/octet-stream"
    end

    it 'should not set dsLocation if dsLocation is nil' do
      ActiveFedora::Datastream.any_instance.expects(:dsLocation=).never
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:dsLocation=>nil})
    end

    it 'should set attributes passed in onto the datastream' do
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:dsLocation=>"a1", :mimeType=>'image/png', :controlGroup=>'X', :dsLabel=>'My Label', :checksumType=>'SHA-1'})
      ds.location.should == 'a1'
      ds.mimeType.should == 'image/png'
      ds.controlGroup.should == 'X'
      ds.label.should == 'My Label'
      ds.checksumType.should == 'SHA-1'
    end
  end

  describe ".add_file_datastream" do
    before do
      @mock_file = mock('file')
    end
    it "should pass prefix" do
      stub_add_ds(@test_object.pid, ['content1'])
      @test_object.add_file_datastream(@mock_file, :prefix=>'content' )
      @test_object.datastreams.keys.should include 'content1'
    end
    it "should pass dsid" do
      stub_add_ds(@test_object.pid, ['MY_DSID'])
      @test_object.add_file_datastream(@mock_file, :dsid=>'MY_DSID')
      @test_object.datastreams.keys.should include 'MY_DSID'
    end
    it "without dsid or prefix" do
      stub_add_ds(@test_object.pid, ['DS1'])
      @test_object.add_file_datastream(@mock_file, {} )
      @test_object.datastreams.keys.should include 'DS1'
    end
    it "Should pass checksum Type" do
      stub_add_ds(@test_object.pid, ['DS1'])
      @test_object.add_file_datastream(@mock_file, {:checksumType=>'MD5'} )
      @test_object.datastreams['DS1'].checksumType.should == 'MD5'
    end
  end

end
