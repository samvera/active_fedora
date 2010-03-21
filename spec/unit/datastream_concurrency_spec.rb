require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require "rexml/document"
require 'ftools'

describe ActiveFedora::Datastream do
  
  before(:each) do
    Fedora::Repository.instance.expects(:nextid).returns("foo")
    @test_object = ActiveFedora::Base.new
    @test_datastream = ActiveFedora::Datastream.new(:pid=>@test_object.pid, :dsid=>'abcd', :blob=>StringIO.new("hi there"))
  end
  
  it "should provide #last_modified_in_repository" do
    @test_datastream.should respond_to(:last_modified_in_repository)
  end
  
  it 'should update @last_modified when #save or #content is called' do 
    pending
    Fedora::Repository.any_instance.stubs(:save)
    Fedora::Repository.any_instance.stubs(:fetch_custom)
    @test_datastream.expects(:last_modified=).times(2)
    @test_datastream.expects(:last_modified_in_repository).times(3)
    @test_datastream.save
    @test_datastream.content
  end
  
  describe '#save' do
    it 'should not save to fedora if @last_modified does not match the datetime from fedora'
    it 'should save to fedora if @last_modified matches the datetime from fedora'
  end
  
  describe '#last_modified_in_repository' do
      it "should retrieve a datetime from fedora"
  end
  
  it 'should provide #check_concurrency' do
    @test_datastream.should respond_to(:check_concurrency)
  end
  
  describe '#check_concurrency' do
    it 'should return true if @last_modified matches the datetime from fedora' do
      pending
      @test_datastream.expects(:last_modified_in_repository).returns("2008-10-17T00:17:18.194Z")
      @test_datastream.last_modified = "2008-10-17T00:17:18.194Z"
      @test_datastream.check_concurrency.should == true
    end
    
    it 'should raise an error if @last_modified does not match the datetime from fedora' do
      pending
      @test_datastream.expects(:last_modified_in_repository).returns("blah blah blah")
      @test_datastream.last_modified = "2008-10-17T00:17:18.194Z"
      @test_datastream.check_concurrency.should raise_error()
    end
    
  end
  
end
