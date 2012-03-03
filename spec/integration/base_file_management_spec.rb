require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:each) do
    class  FileMgmt < ActiveFedora::Base
      include ActiveFedora::FileManagement
    end
    @test_container = FileMgmt.new
    @test_container.add_relationship(:has_collection_member, "info:fedora/foo:2")
    @test_container.save
  end
  
  after(:each) do
    @test_container.delete
    Object.send(:remove_const, :FileMgmt)
  end
  
  it "should persist and re-load collection members" do
    container_copy = FileMgmt.load_instance(@test_container.pid)
    container_copy.collection_members(:response_format=>:id_array).should == ["foo:2"]
  end
    
end
