require File.join( File.dirname(__FILE__),  "../spec_helper" )

describe Fedora::Repository do
  
  after(:all) do
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
  end
  
  it "should trim extra slash on uri" do
    Fedora::Repository.expects(:new).with('http://bar.baz/bat', nil)
    Fedora::Repository.register('http://bar.baz/bat/')
    Fedora::Repository.expects(:new).with('http://bar.baz/bat', nil)
    Fedora::Repository.register(URI.parse('http://bar.baz/bat/'))
  end

  it "should accept a url to register" do 
    Fedora::Repository.expects(:new).with('http://bar.baz', nil).returns(stub_everything)
    Fedora::Repository.register('http://bar.baz').should_not be_nil
    z = Fedora::Repository.instance
    z.should_not be_nil
    (z === Fedora::Repository.instance).should == true
  end
  
  it "should initialize a repo" do 
    Fedora::Repository.expects(:new).with('http://foo.bar', nil).returns(stub_everything)
    Fedora::Repository.register('http://foo.bar')
    z = Fedora::Repository.instance
    y = Fedora::Repository.instance
    z.should_not be_nil
    y.should_not be_nil
    (z===y).should == true
  end

  it 'should be a singleton' do
    Fedora::Repository.expects(:new).with('http://foo.bar',nil).returns(stub_everything)
    Fedora::Repository.register('http://foo.bar')
    a = Fedora::Repository.instance
    b = Fedora::Repository.instance
    (a === b).should == true
  end

  it "should be able to reserve an id" do
    bodymock = mock('body')
    bodymock.expects(:body).returns <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
   <pidList xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.fedora.info/definitions/1/0/management/ http://www.fedora.info/definitions/1/0/objectHistory.xsd">
     <pid>changeme:5035</pid>
     </pidList>
    EOS

    Fedora::Repository.register('http://fedoraAdmin:fedoraAdmin@127.0.0.1:8080/fedora').should_not be_nil
    Fedora::Repository.instance.send(:connection).expects(:post).with('/fedora/management/getNextPID?xml=true').returns(bodymock)
    Fedora::Repository.instance.should_not be_nil
    Fedora::Repository.instance.nextid.should == 'changeme:5035'
  end
  
  it "should have attributes corresponding to the info in fedora/describe" do
    Fedora::Repository.register('http://foo.bar')
    #skipping oai_namespace_identifier and oai_delimiter
    %w[repository_name base_url fedora_version pid_namespace pid_delimiter].each do |attribute_name|
      Fedora::Repository.instance.should respond_to(attribute_name)
      Fedora::Repository.instance.should respond_to(attribute_name + "=")
    end
  end
  
  describe "export" do
    it "should call fetch_custom with the appropriate parameters" do
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:FOXML-1.1", :context=>"archive")
      Fedora::Repository.instance.export("test:my_pid")
    end
    it "should support :foxml, :mets, :atom, and :atom_zip" do
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:ATOM-1.1", :context=>"archive")
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:ATOMZip-1.1", :context=>"archive")
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:FOXML-1.1", :context=>"archive")
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:METSFedoraExt-1.1", :context=>"archive")
      
      Fedora::Repository.instance.export("test:my_pid", :format=>:atom)
      Fedora::Repository.instance.export("test:my_pid", :format=>:atom_zip)
      Fedora::Repository.instance.export("test:my_pid", :format=>:foxml)
      Fedora::Repository.instance.export("test:my_pid", :format=>:mets)
    end
    it "should allow you to pass through the format uri as a string" do
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:ATOMZip-1.1", :context=>"archive")
      Fedora::Repository.instance.export("test:my_pid", :format=>"info:fedora/fedora-system:ATOMZip-1.1") 
    end
    it "should support export context" do
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:ATOM-1.1", :context=>"public").times(2)
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:ATOM-1.1", :context=>"migrate")
      Fedora::Repository.instance.expects(:fetch_custom).with("test:my_pid", "export", :format=>"info:fedora/fedora-system:ATOM-1.1", :context=>"archive")

      Fedora::Repository.instance.export("test:my_pid", :format=>:atom, :context=>:public)
      Fedora::Repository.instance.export("test:my_pid", :format=>:atom, :context=>"public")
      Fedora::Repository.instance.export("test:my_pid", :format=>:atom, :context=>:migrate)
      Fedora::Repository.instance.export("test:my_pid", :format=>:atom, :context=>:archive)
    end
  end
    
  describe "ingest" do
    it "should post the provided xml or file to fedora" do
      foxml = fixture("test_12.foxml.xml").read
      connection = Fedora::Repository.instance.send(:connection)
      connection.expects(:post).with("/fedora/objects/new",foxml)
      Fedora::Repository.instance.ingest(foxml)
    end
    it "should accept a file as its input" do
      foxml_file = fixture("test_12.foxml.xml")
      foxml = fixture("test_12.foxml.xml").read
      connection = Fedora::Repository.instance.send(:connection)
      connection.expects(:post).with("/fedora/objects/new",foxml)
      Fedora::Repository.instance.ingest(foxml_file)
    end
  end
  
  describe "#register" do
    after(:all) do
      Fedora::Repository.register(ActiveFedora.fedora_config[:url])
    end
    it "should initialize the attributes from fedora/describe" do
      sample_attrs = {"sampleSearch-URL"=>["http://127.0.0.1:8080/fedora/search"], "repositoryOAI-identifier"=>[{"OAI-sample"=>["oai:example.org:changeme:100"], "OAI-delimiter"=>[":"], "OAI-namespaceIdentifier"=>["example.org"]}], "repositoryBaseURL"=>["http://127.0.0.1:8080/fedora"], "xsi:schemaLocation"=>"http://www.fedora.info/definitions/1/0/access/ http://www.fedora.info/definitions/1/0/fedoraRepository.xsd", "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema", "repositoryPID"=>[{"PID-sample"=>["changeme:100"], "PID-namespaceIdentifier"=>["changeme"], "PID-delimiter"=>[":"], "retainPID"=>["*"]}], "adminEmail"=>["bob@example.org", "sally@example.org"], "repositoryVersion"=>["3.1"], "sampleOAI-URL"=>["http://localhost:8080/fedora/oai?verb=Identify"], "sampleAccess-URL"=>["http://localhost:8080/fedora/get/demo:5"], "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "repositoryName"=>["Fedora Repository"]}
      Fedora::Repository.any_instance.expects(:describe_repository).returns(sample_attrs)
      Fedora::Repository.register('http://foo.bar')
      boo = Fedora::Repository.instance
      boo.repository_name.should == "Fedora Repository"
      boo.base_url.should ==  "http://127.0.0.1:8080/fedora"
      boo.fedora_version.should ==  "3.1"
      boo.pid_namespace.should ==  "changeme"
      boo.pid_delimiter.should == ":"
    end
  end
  
  
  it "should provide .describe_repository" do
    Fedora::Repository.instance.should respond_to(:describe_repository)
  end

end
