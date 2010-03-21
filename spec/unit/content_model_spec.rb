require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'mocha'


describe ActiveFedora::ContentModel do
  
  before(:each) do
    Fedora::Repository.instance.stubs(:nextid).returns("_nextid_")
    @test_cmodel = ActiveFedora::ContentModel.new
  end
  
  it "should provide #new" do
    ActiveFedora::ContentModel.should respond_to(:new)
  end
  
  describe "#new" do
    it "should create a kind of ActiveFedora::Base object" do
      @test_cmodel.should be_kind_of(ActiveFedora::Base)
    end
    it "should set pid_suffix to empty string unless overriden in options hash" do
      @test_cmodel.pid_suffix.should == ""
      boo_model = ActiveFedora::ContentModel.new(:pid_suffix => "boo")
      boo_model.pid_suffix.should == "boo"
    end
    it "should set namespace to cmodel unless overriden in options hash" do
      @test_cmodel.namespace.should == "afmodel"
      boo_model = ActiveFedora::ContentModel.new(:namespace => "boo")
      boo_model.namespace.should == "boo"
    end
  end
  
  it "should provide @pid_suffix" do
    @test_cmodel.should respond_to(:pid_suffix)
    @test_cmodel.should respond_to(:pid_suffix=)
  end
  
  it 'should provide #pid_from_ruby_class' do
    ActiveFedora::ContentModel.should respond_to(:pid_from_ruby_class)
  end
  
  describe "#pid_from_ruby_class" do
    it "should construct pids" do
     ActiveFedora::ContentModel.pid_from_ruby_class(@test_cmodel.class).should == "afmodel:ActiveFedora_ContentModel"
     ActiveFedora::ContentModel.pid_from_ruby_class(@test_cmodel.class, :namespace => "foo", :pid_suffix => "BarBar").should == "foo:ActiveFedora_ContentModelBarBar"
    end
  end
  

end
