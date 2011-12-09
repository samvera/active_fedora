require File.join( File.dirname(__FILE__), "../spec_helper" )

class Test < ActiveFedora::Base
  include ActiveFedora::ServiceDefinitions
  #has_service_definition "monkey:100"
end

describe ActiveFedora::ServiceDefinitions do
  before(:each) do
    mmap = <<-MMAP
<fmm:MethodMap xmlns:fmm="http://fedora.comm.nsdlib.org/service/methodmap" name="Fedora MethodMap for listing collection members">
<fmm:Method operationName="getDocumentStyle1"/>
<fmm:Method operationName="getDocumentStyle2"/>
</fmm:MethodMap>
    MMAP
    stub_get("monkey:99")
    Rubydora::Repository.any_instance.stubs(:client).returns @mock_client
    Rubydora::Repository.any_instance.stubs(:datastream_dissemination).with({:pid=>'test:12',:dsid=>'METHODMAP'}).returns mmap
    Test.has_service_definition "test:12"
  end
  describe "method lookup" do
    it "should find method keys in the YAML config" do
      ActiveFedora::ServiceDefinitions.lookup_method("fedora-system:3", "viewObjectProfile").should == :object_profile
    end
  end
  describe "method creation" do
    it "should create the system sdef methods" do
      obj = Test.new(:pid=>"monkey:99")
      (obj.respond_to? :object_profile).should == true
    end
    it "should create the declared sdef methods" do
      obj = Test.new(:pid=>"monkey:99")
      (obj.respond_to? :document_style_1).should == true
    end
  end
  describe "generated method" do
    it "should call the appropriate rubydora rest api method" do
      Rubydora::Repository.any_instance.expects(:dissemination).with({:pid=>'monkey:99',:sdef=>'test:12', :method=>'getDocumentStyle1'})
      #@mock_client.stubs(:[]).with('objects/monkey%3A99/methods/test%3A12/getDocumentStyle1')
      obj = Test.new(:pid=>"monkey:99")
      obj.document_style_1
    end
    it "should call the appropriate rubydora rest api method with parameters" do
      Rubydora::Repository.any_instance.expects(:dissemination).with({:pid=>'monkey:99',:sdef=>'test:12', :method=>'getDocumentStyle1', :format=>'xml'})
      obj = Test.new(:pid=>"monkey:99")
      obj.document_style_1({:format=>'xml'})
    end
    it "should call the appropriate rubydora rest api method with a block" do
      pending "how to mock the passed block to rubydora"
    end
  end
end
