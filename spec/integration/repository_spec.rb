require File.join( File.dirname(__FILE__),  "../spec_helper" )

# - Objects API - http://www.fedora-commons.org/documentation/3.0b1/userdocs/server/webservices/rest/index.html

#  - Object profile
#  
#    curl -i http://localhost:8080/fedora/objects/demo:10
#    curl -i http://localhost:8080/fedora/objects/demo:10.xml
#    curl -i http://localhost:8080/fedora/objects/demo:10?resultFormat=xml
# 
#  - Object history
#    curl -i http://localhost:8080/fedora/objects/demo:10/versions
#    curl -i http://localhost:8080/fedora/objects/demo:10/versions.xml
#    curl -i http://localhost:8080/fedora/objects/demo:10/versions/2007-07-25T17:08:11.915Z
#    curl -i http://localhost:8080/fedora/objects/demo:10/versions/2007-07-25T17:08:11.915Z.xml
#    curl -i http://localhost:8080/fedora/objects/demo:10/versions/2007-07-25T17:08:11.915Z?resultFormat=xml
#    
#  - Object export
#    curl -i -u fedoraAdmin:fedoraAdmin http://localhost:8080/fedora/objects/demo:10/export?resultFormat=foxml1.0&context=private 
#    
#  - Object XML
#    curl -i http://localhost:8080/fedora/objects/demo:10/objectXML
#    curl -i http://localhost:8080/fedora/objects/demo:10/objectXML?resultFormat=xml
#  
#  - Object methods
#    curl -i http://localhost:8080/fedora/objects/demo:10/methods
#    curl -i http://localhost:8080/fedora/objects/demo:10/methods?resultFormat=xml
#    curl -i http://localhost:8080/fedora/objects/demo:10/methods/2007-07-25T17:08:11.915Z
#    curl -i http://localhost:8080/fedora/objects/demo:10/methods/2007-07-25T17:08:11.915Z.xml
#    
#    invalid: curl -i http://localhost:8080/fedora/objects/demo:10/methods.xml
#    
#  - Create
#    curl -i -H "Content-type: text/xml" -XPOST "http://localhost:8080/fedora/objects/new?label=Test&namespace=test" --data "" -u fedoraAdmin:fedoraAdmin
#    curl -i -H "Content-type: text/xml" -XPOST "http://localhost:9090/fedora/objects/new" --data "" -u fedoraAdmin:fedoraAdmin
# 
#    curl -i -H "Content-type: text/xml" -XPOST "http://localhost:8080/fedora/objects/test:02?label=Test" --data "" -u fedoraAdmin:fedoraAdmin
#    curl -i -H "Content-type: text/xml" -XPOST "http://localhost:8080/fedora/objects/test:01?label=Test&altIDs=3333" --data-binary @foxml.xml -u fedoraAdmin:fedoraAdmin
#       
#  - Delete
#    curl -i  -u fedoraAdmin:fedoraAdmin -XDELETE http://localhost:8080/fedora/objects/demo:10
#    
# Objects API
#    curl -i http://localhost:8080/fedora/objects
#    curl -i http://localhost:8080/fedora/objects?resultFormat=xml
#    curl -i http://localhost:8080/fedora/objects/nextPID -u fedoraAdmin:fedoraAdmin
#    curl -i http://localhost:8080/fedora/objects/nextPID.xml -u fedoraAdmin:fedoraAdmin
 
describe Fedora::Repository, "constructor" do
  it "should accept URL as string" do
    fedora_url = "http://fedoraAdmin:fedoraAdmin@127.0.0.1:8080/fedora"
    repository = Fedora::Repository.register(fedora_url)
    
    repository.fedora_url.should == URI.parse(fedora_url)
  end
  
  it "should accept URL as URI object" do
    fedora_url = URI.parse("http://fedoraAdmin:fedoraAdmin@127.0.0.1:8080/fedora")
    repository = Fedora::Repository.register(fedora_url)
    
    repository.fedora_url.should == fedora_url
  end
  
  it "should reject invalid url format" do
    lambda { Fedora::Repository.register("http://:8080/") }.should raise_error
  end
end

describe Fedora::Repository, "CRUD" do
  before(:all) do
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
  end

  before(:each) do
    @test_object = Fedora::FedoraObject.new(:label => 'test', 
      :state => 'A',
      :ownerID => 'fedoraAdmin')
  end
  
  after(:each) do
    if !@test_object.new_object?
      begin
        Fedora::Repository.instance.delete(@test_object)
      end
    end
  end
  
  it "should create new fedora object with auto pid" do
    Fedora::Repository.instance.save(@test_object).should be_true
    
    @test_object.should have(0).errors
    @test_object.pid.should_not be_nil
    @test_object.label.should == 'test'
    @test_object.state.should == 'A'
    @test_object.owner_id.should == 'fedoraAdmin'
  end
  
  it "should create new fedora object with assigned pid" do
    @test_object.pid = "demo:1000"
    Fedora::Repository.instance.save(@test_object).should be_true    
    @test_object.should have(0).errors
    @test_object.pid.should == "demo:1000"
  end
    
  it "should update object state" do
    Fedora::Repository.instance.save(@test_object).should be_true

    @test_object.state = 'I'
    Fedora::Repository.instance.update(@test_object).should be_true
    @test_object.state.should == 'I'
  end
  
  it "should delete object by ref" do
    Fedora::Repository.instance.create(@test_object).should be_true
    Fedora::Repository.instance.delete(@test_object).should be_true
    # prevent after statement from attempting to delete again
    @test_object.new_object = true
  end
  
  it "should delete object by pid" do
    Fedora::Repository.instance.create(@test_object).should be_true
    Fedora::Repository.instance.delete(@test_object.uri).should be_true  
    # prevent after statement from attempting to delete again
    @test_object.new_object = true
  end
  
=begin
  it "should fetch object profile Image of Coliseum in Rome" do
    xml = Fedora::Repository.instance.fetch_content("demo:5")
    validate_xml(xml, 'objectProfile')
    xml.should =~ %r{Data Object (Coliseum) for Local Simple Image Demo}
  end
=end
end

describe Fedora::Repository, "find_objects" do
  before(:all) do
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
  end
  
  def fields_to_s(fields)
    fields.inject("") { |s, f| s += '&' + f.to_s + '=true' }
  end
  
  def when_find_objects(*args)
    fake_connection = mock("Connection")
    Fedora::Repository.instance.expects(:connection).returns(fake_connection)
    yield fake_connection
    
    Fedora::Repository.instance.find_objects(*args)
  end
  
  it "should include all fields by default" do
    when_find_objects('label~Image*') { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s(Fedora::ALL_FIELDS))
    }
  end
  
  it "should include all fields when :include => :all " do
    when_find_objects('label~Image*', :include => :all) { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s(Fedora::ALL_FIELDS))
    }
  end
  
  it "should fetch results with limit" do
    when_find_objects('label~Image*', :limit => 10) { |conn|
      conn.expects(:get).with('/fedora/objects?maxResults=10&query=label%7EImage%2A&resultFormat=xml' + fields_to_s(Fedora::ALL_FIELDS))
    }
  end
  
  it "should fetch results with some fields but not :pid" do
    when_find_objects('label~Image*', :select => [:label, :mDate]) { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s([:pid, :label, :mDate]))
    }
  end
  
  it "should fetch results with some fields with :pid" do
    when_find_objects('label~Image*', :select => [:pid, :label, :mDate]) { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s([:pid, :label, :mDate]))
    }
  end
  
  def sample_response_xml(n = 1)
    header = %Q(<result xmlns="http://www.fedora.info/definitions/1/0/types/">
  <listSession>
    <token>aToken</token>
    <cursor>0</cursor>
  </listSession>
  <resultList>)

    body = %Q(<objectFields>
      <pid>demo:10</pid>
      <label>Column Detail, Pavillion III, IVA Image Collection - University of Virginia</label>
    </objectFields>) * n

    header + body + %Q(</resultList></result>)
  end

  it "should convert xml response with 0 objectFields into array of FedoraObject" do
    objects = when_find_objects('label~Image*', :select => [:pid, :label, :mDate]) { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s([:pid, :label, :mDate])).
        returns(Fedora::XmlFormat.decode(sample_response_xml))
    }
    
    objects.session_token.should == 'aToken'
    objects.should_not be_empty
  end
  
  it "should return FedoraObjects with new_object set to false" do
    objects = when_find_objects('label~Image*', :select => [:pid, :label, :mDate]) { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s([:pid, :label, :mDate])).
        returns(Fedora::XmlFormat.decode(sample_response_xml))
    }
    objects.each do |obj|
      obj.should_not be_new_object
    end
    
  end
  
  it "should convert xml response with single objectFields into array of FedoraObject" do
    objects = when_find_objects('label~Image*', :select => [:pid, :label, :mDate]) { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s([:pid, :label, :mDate])).
        returns(Fedora::XmlFormat.decode(sample_response_xml(1)))
    }
    
    objects.session_token.should == 'aToken'
    objects.should have(1).record
    objects.first.pid.should == 'demo:10'
    objects.first.should be_kind_of(Fedora::FedoraObject)
  end
  
  it "should convert xml response 2 objectFields into array of FedoraObject" do
    objects = when_find_objects('label~Image*', :select => [:pid, :label, :mDate]) { |conn|
      conn.expects(:get).with('/fedora/objects?query=label%7EImage%2A&resultFormat=xml' + fields_to_s([:pid, :label, :mDate])).
        returns(Fedora::XmlFormat.decode(sample_response_xml(2)))
    }
    
    objects.session_token.should == 'aToken'
    objects.should have(2).records
  end
end

describe Fedora::Repository, "ingest" do
  
  after(:each) do
    begin
      Fedora::Repository.instance.delete("test:12")
    end
  end
  
  it "should successfully ingest foxml" do
    foxml_file = fixture("test_12.foxml.xml")
    foxml = fixture("test_12.foxml.xml").read
    response = Fedora::Repository.instance.ingest(foxml_file)
    response.code.should == "201"
    response.body.should == "test:12"
  end
  
end

describe Fedora::Repository do
  before(:all) do
    require 'rexml/document'
  end
  
  it "should fetch history" do
    xml = Fedora::Repository.instance.fetch_custom("demo:20", :versions)
    validate_xml(xml, 'fedoraObjectHistory')
    xml.should =~ /pid="demo:20"/
  end

  it "should fetch profile" do
    xml = Fedora::Repository.instance.fetch_custom("demo:20", :profile)
    validate_xml(xml, 'objectProfile')
    xml.should =~ /pid="demo:20"/
  end

  it "should fetch export" do
    xml = Fedora::Repository.instance.fetch_custom("demo:20", :export)
    validate_xml(xml, 'digitalObject')
    xml.should =~ /demo:20/
    xml.should =~ /datastream/
  end

  it "should fetch objectXML" do
    xml = Fedora::Repository.instance.fetch_custom("demo:20", :objectXML)
    xml.should =~ /digitalObject/
    xml.should =~ /pid="demo:20"/i
  end

  it "should list object methods" do
    xml = Fedora::Repository.instance.fetch_custom("demo:20", :methods)
    xml.should =~ /objectMethods/
    xml.should =~ /pid="demo:20"/i
  end
  
end
