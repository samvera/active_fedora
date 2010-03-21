require File.join( File.dirname(__FILE__), "../spec_helper" )

describe ActiveFedora::Base do
  
  before(:each) do
    @test_container = ActiveFedora::Base.new
    @test_container.add_relationship(:has_collection_member, "foo:2")
    @test_container.save
  end
  
  after(:each) do
    @test_container.delete
  end
  
  it "should persist and re-load collection members" do
    container_copy = ActiveFedora::Base.load_instance(@test_container.pid)
    container_copy.collection_members(:response_format=>:id_array).should == ["foo:2"]
  end
    
end