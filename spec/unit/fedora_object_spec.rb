require File.join( File.dirname(__FILE__),  "../spec_helper" )

describe Fedora::FedoraObject do
  
  before(:each) do
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
    @test_object = Fedora::FedoraObject.new
  end
  
  it 'should respond to #object_xml' do
    Fedora::FedoraObject.should respond_to(:object_xml)
  end
  it 'hash should not have to_query) on it' do
    Fedora::BaseObject.new
    {:foo=>:bar}.to_fedora_query.should == 'foo=bar'
  end
  
  it 'should respond to .object_xml' do
    @test_object.should respond_to(:object_xml)
  end
  
  it "should provide .url" do
    @test_object.should respond_to(:url)
  end
  
  describe ".url" do
    it "should return the Repository fedora_url with /objects/pid appended" do
      Fedora::Repository.instance.expects(:fedora_url).returns(mock("fedora url", :scheme => "_scheme_", :host => "_host_", :port => "_port_", :path => "_path_"))
      @test_object.expects(:pid).returns("_PID_")
      @test_object.url.should == "_scheme_://_host_:_port__path_/objects/_PID_"
    end
  end
  
  describe ".label" do
    before(:all) do
      @properties = [:label, :state, :modified_date, :create_date, :owner_id]
      @sample_attributes = {:label => "label", :state => "state", :modified_date => "modified_date", :create_date => "create_date", :owner_id => "owner_id"}
    end
    it "should give preference to pulling from attributes hash" do
      @test_object.expects(:attributes).times(@properties.length*2).returns(@sample_attributes)
      @properties.each do |p|
        @test_object.send(p)
      end
    end
    
    it "should rely solely on attributes hash if new_object" do
      @test_object.new_object = true
      @test_object.expects(:properties_from_fedora).never
      @test_object.expects(:attributes).times(@properties.length*2).returns(@sample_attributes)
      @properties.each do |p|
        @test_object.send(p)
      end
    end
    
    it "should call properties_from_fedora if not a new_object" do
      @test_object.new_object = false
      @test_object.expects(:properties_from_fedora).times(@properties.length).returns(@sample_attributes)
      @test_object.expects(:attributes).times(@properties.length).returns({})
      @properties.each do |p|
        @test_object.send(p)
      end
    end
    
  end

end
