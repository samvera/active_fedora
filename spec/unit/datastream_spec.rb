require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "nokogiri"
require 'ftools'

describe ActiveFedora::Datastream do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_datastream = ActiveFedora::Datastream.new(@test_object.inner_object, 'abcd')
    #:pid=>@test_object.pid, :dsid=>'abcd', :blob=>StringIO.new("hi there"))
    @test_datastream.content = "hi there"
  end

  it "should escape dots in  to_param" do
    @test_datastream.stubs(:dsid).returns('foo.bar')
    @test_datastream.to_param.should == 'foo%2ebar'
  end
  
  it 'should provide #save, #before_save and #after_save' do
    @test_datastream.should respond_to(:save)
    @test_datastream.should respond_to(:before_save)
    @test_datastream.should respond_to(:after_save)
  end
  
  describe '#save' do
    it 'should call #before_save and #after_save' do
      @mock_repo = mock('repository')
      @mock_repo.stubs(:add_datastream).with(:versionable => true, :pid => nil, :dsid => 'abcd', :controlGroup => 'M', :dsState => 'A', :content => 'hi there', :checksumType => 'DISABLED')
      @mock_repo.expects(:datastream).with(:dsid => 'abcd', :pid => nil)
      @test_object.inner_object.stubs(:repository).returns(@mock_repo)
      @test_object.inner_object.stubs(:pid).returns(@pid)

      @test_datastream.stubs(:last_modified_in_repository)
      @test_datastream.expects(:before_save)
      @test_datastream.expects(:after_save)
      @test_datastream.save
    end
    
    it "should set @dirty to false" do
      @mock_repo = mock('repository')
      @mock_repo.stubs(:add_datastream).with(:versionable => true, :pid => @test_object.pid, :dsid => 'abcd', :controlGroup => 'M', :dsState => 'A', :content => 'hi there', :checksumType => 'DISABLED')
      @mock_repo.expects(:datastream).with(:dsid => 'abcd', :pid => @test_object.pid)
      @test_object.inner_object.stubs(:repository).returns(@mock_repo)
      @test_datastream.expects(:dirty=).with(false)
      @test_datastream.save
    end
  end
  
  describe '.content=' do
    it "should update the content and ng_xml, marking the datastream as changed" do
      sample_xml = "<foo><xmlelement/></foo>"
      @test_datastream.instance_variable_get(:@changed_attributes).clear
      @test_datastream.should_not be_changed
      @test_datastream.content.should_not be_equivalent_to(sample_xml)
      @test_datastream.content = sample_xml
      @test_datastream.should be_changed
      @test_datastream.content.should be_equivalent_to(sample_xml)
    end
  end
  
  describe ".dirty?" do
    it "should return the value of the @dirty attribute" do
      @test_datastream.dirty.should equal(@test_datastream.dirty?)
      @test_datastream.dirty = "boo"
      @test_datastream.dirty?.should == "boo"    
    end
  end 
  
  it "should have mimeType accessors" do
    ds1 = ActiveFedora::Datastream.new(nil, nil)#:mime_type=>"text/foo")    
    ds1.mimeType = "text/foo"
    ds1.mimeType.should == "text/foo"
    ds2 = ActiveFedora::Datastream.new(nil, nil)#:mime_type=>"text/bar")
    ds2.mimeType = "text/bar"
    ds2.mimeType.should == "text/bar"
  end

  describe ".size" do
    it "should lazily load the datastream size attribute from the fedora repository" do
      ds_profile = <<-EOS
        <datastreamProfile 
            xmlns=\"http://www.fedora.info/definitions/1/0/management/\"  
            xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" 
            xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" 
            xsi:schemaLocation=\"http://www.fedora.info/definitions/1/0/management/ http://www.fedora.info/definitions/1/0/datastreamProfile.xsd\" 
            pid=\"#{@test_object.pid}\" 
            dsID=\"#{@test_datastream.dsid}\" >
         <dsLabel></dsLabel>
         <dsVersionID>#{@test_datastream.dsid}.1</dsVersionID>
         <dsCreateDate>2011-07-11T16:48:13.536Z</dsCreateDate>
         <dsState>A</dsState>
         <dsMIME>text/xml</dsMIME>
         <dsFormatURI></dsFormatURI>
         <dsControlGroup>X</dsControlGroup>
         <dsSize>9999</dsSize>
         <dsVersionable>true</dsVersionable>
         <dsInfoType></dsInfoType>
         <dsLocation>#{@test_object.pid}+#{@test_datastream.dsid}+#{@test_datastream.dsid}.1</dsLocation>
         <dsLocationType></dsLocationType>
         <dsChecksumType>DISABLED</dsChecksumType>
         <dsChecksum>none</dsChecksum>
         </datastreamProfile>"
      EOS
      @test_datastream.expects(:repository).returns(@mock_repo)
      @mock_repo.expects(:datastream).with(:dsid => 'abcd', :pid => @test_object.pid).returns(ds_profile)
      @test_datastream.size.should == "9999"
    end

    it "should default to an empty string if ds has not been saved" do
      @test_datastream.size.should be_nil
    end
  end

end
