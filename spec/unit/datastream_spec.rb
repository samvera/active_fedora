require 'spec_helper'

require 'active_fedora'
require "nokogiri"

describe ActiveFedora::Datastream do
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
    @test_datastream = ActiveFedora::Datastream.new(@test_object.inner_object, 'abcd')
    @test_datastream.content = "hi there"
  end

  its(:metadata?) { should be_false}

  it "should escape dots in  to_param" do
    @test_datastream.stub(:dsid).and_return('foo.bar')
    @test_datastream.to_param.should == 'foo%2ebar'
  end
  
  it "should be inspectable" do
    @test_datastream.inspect.should match /#<ActiveFedora::Datastream @pid=\"__DO_NOT_USE__\" @dsid=\"abcd\" @controlGroup=\"M\" changed=\"true\" @mimeType=\"\" >/
  end

  describe '#validate_content_present' do
    before :each do
      @test_datastream.content = nil
      @test_datastream.dsLocation = nil
    end

    it "should expect content on an Inline (X) datastream" do
      @test_datastream.controlGroup = 'X'
      @test_datastream.dsLocation = "http://example.com/test/content/abcd"
      @test_datastream.validate_content_present.should be_false
      @test_datastream.content = "<foo><xmlelement/></foo>"
      @test_datastream.validate_content_present.should be_true
    end

    it "should expect content on a Managed (M) datastream" do
      @test_datastream.controlGroup = 'M'
      @test_datastream.dsLocation = "http://example.com/test/content/abcd"
      @test_datastream.validate_content_present.should be_false
      @test_datastream.content = "<foo><xmlelement/></foo>"
      @test_datastream.validate_content_present.should be_true
      @test_datastream.should_not be_external
    end

    it "should expect a dsLocation on an External (E) datastream" do
      @test_datastream.controlGroup = 'E'
      @test_datastream.content = "<foo><xmlelement/></foo>"
      @test_datastream.validate_content_present.should be_false
      @test_datastream.dsLocation = "http://example.com/test/content/abcd"
      @test_datastream.validate_content_present.should be_true
      @test_datastream.should be_external
    end

    it "should expect a dsLocation on a Redirect (R) datastream" do
      @test_datastream.controlGroup = 'R'
      @test_datastream.content = "<foo><xmlelement/></foo>"
      @test_datastream.validate_content_present.should be_false
      @test_datastream.dsLocation = "http://example.com/test/content/abcd"
      @test_datastream.validate_content_present.should be_true
    end
  end
  
  it "should have mimeType accessors" do
    ds1 = ActiveFedora::Datastream.new
    ds1.mimeType = "text/foo"
    ds1.mimeType.should == "text/foo"
    ds2 = ActiveFedora::Datastream.new
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

      mock_repo = mock('repository', :config=>{})
      @test_object.inner_object.stub(:repository).and_return(mock_repo)
      mock_repo.should_receive(:datastream).with(:dsid => 'abcd', :pid => @test_object.pid).and_return(ds_profile)
      @test_datastream.size.should == 9999
    end

    it "should default to an empty string if ds has not been saved" do
      @test_datastream.size.should be_nil
    end
  end
end
