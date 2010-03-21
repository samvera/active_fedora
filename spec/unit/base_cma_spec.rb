require File.join( File.dirname(__FILE__), "../spec_helper" )

describe ActiveFedora::Base do
  
  before(:each) do
    Fedora::Repository.instance.stubs(:nextid).returns('_nextid_')
    @test_object = ActiveFedora::Base.new
  end
  
  describe '.save' do

    it "should add hasModel relationship that points to the CModel if @new_object" do
      @test_object.expects(:new_object?).returns(true)
      
      @test_object.expects(:add_relationship).with(:has_model, ActiveFedora::ContentModel.pid_from_ruby_class(@test_object.class))
      mock_repo = mock("repository")
      mock_repo.expects(:save).with(@test_object.inner_object)
      Fedora::Repository.stubs(:instance).returns(mock_repo)
      @test_object.stubs(:update_index)
      @test_object.expects(:refresh)
      @test_object.save
    end
  end

end
