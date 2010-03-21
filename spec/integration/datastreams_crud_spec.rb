require File.join( File.dirname(__FILE__),  "../spec_helper" )
# Datastream API:
#  - To list datastream
#    curl -i http://localhost:8080/fedora/objects/test:02/datastreams
#    curl -i http://localhost:8080/fedora/objects/test:02/datastreams?format=xml
#    
#    invalid: curl -i http://localhost:8080/fedora/objects/test:02/datastreams.xml
#    
#  - To obtain a datastream
#    curl -i http://localhost:8080/fedora/objects/test:02/datastreams/DC
#    curl -i http://localhost:8080/fedora/objects/test:02/datastreams/DS1
# 
#  - To create create a new datastream
#  
#  regular post (always creates inline (I) datastream.  Will fail if not valid XML):
#    curl -i -H "Content-type: text/xml" -XPOST --data-binary @build.xml -u fedoraAdmin:fedoraAdmin "http://localhost:8080/fedora/objects/test:02/datastreams/DS1?dsLabel=A%20Test%20Datastream&altIDs=3333" 
# 
#  "E" and "R" datastreams
#    curl -i -H "Content-type: text/html" -XPOST "http://localhost:8080/fedora/objects/test:02/datastreams/REDIRECT?dsLabel=A%20Redirect%20Datastream&altIDs=3333&controlGroup=R&dsLocation=http://www.yourmediashelf.com" -u fedoraAdmin:fedoraAdmin
#    curl -i -H "Content-type: text/html" -XPOST "http://localhost:8080/fedora/objects/test:02/datastreams/EXT?dsLabel=A%20Ext%20Datastream&altIDs=3333&controlGroup=E&dsLocation=http://www.yahoo.com" -u fedoraAdmin:fedoraAdmin   
#    
#  multipart/form-data (always creates managed content (M) datastream):
#    curl -i -H -XPOST -F file=@build.xml -u fedoraAdmin:fedoraAdmin "http://localhost:8080/fedora/objects/test:02/datastreams/DS3?dsLabel=hello&altIDs=3333" 
#    curl -i -H -XPOST -F file=@dino.jpg -u fedoraAdmin:fedoraAdmin "http://localhost:8080/fedora/objects/test:02/datastreams/JPEG?dsLabel=hello&altIDs=3333" 
#  MIME Type is set according to Content Type Header:
#    curl -i -H -XPOST -F "file=@01 Float On.m4a;type=audio/mp4a-latm"  -u fedoraAdmin:fedoraAdmin "http://localhost:8080/fedora/objects/test:02/datastreams/Float_On.m4a?dsLabel=hello&altIDs=3333" 
#    curl -i -H -XPOST -F "file=@educause2004Fedora.ppt;type=application/vnd.ms-powerpoint"  -u fedoraAdmin:fedoraAdmin "http://localhost:8080/fedora/objects/test:02/datastreams/PPT.ppt?dsLabel=hello&altIDs=3333" 
#  
#  mutipart/related is also supported but can only be tested with xform clients.
#  
#  - To update a datastream
#    curl -i -H "Content-type: text/xml" -XPUT "http://localhost:8080/fedora/objects/test:02/datastreams/DS1?dsLabel=hello&altIDs=3333" --data-binary @build.xml -u fedoraAdmin:fedoraAdmin
#    curl -i -H "Content-type: text/xml" -XPOST "http://localhost:8080/fedora/objects/test:02/datastreams/DS1?dsLabel=hello&altIDs=3333" --data-binary @build.xml -u fedoraAdmin:fedoraAdmin
#   
#  - To delete a datastream 
#    curl -i -XDELETE "http://localhost:8080/fedora/objects/test:02/datastreams/DS1" -u fedoraAdmin:fedoraAdmin
# 
#    curl -i -H -XPOST -F file=@test/fixtures/minivan-in-minneapolis.jpg  -u fedoraAdmin:fedoraAdmin "http://localhost:8080/fedora/objects/test:test_xml_post/datastreams/FOO" 
# 
#    curl -i -XDELETE -u admin:muradora "http://localhost:9090/fedora/objects/test:test:test_object_1" 
#  
#    curl -i -H "Content-type: text/xml" -XPOST --data-binary @test/fixtures/mods-mskcc-filledsample.xml -u fedoraAdmin:fedoraAdmin "http://localhost:9090/fedora/objects/test:02/datastreams/DS1?dsLabel=A%20Test%20Datastream" 
# 
#    curl -i -H "Content-type: image/jpeg" -XPOST -F file=@test/fixtures/dino.jpg -u admin:muradora "http://localhost:9090/fedora/objects/test:02/datastreams/DINO?dsLabel=A%20Test%20Datastream"
describe Fedora::Repository do
  def sample_mods
    xml = <<-EOS
    <mods:mods xmlns:xlink="http://www.w3.org/1999/xlink" version="3.2"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mods="http://www.loc.gov/mods/v3"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        xmlns="http://www.w3.org/1999/xhtml">
        <mods:identifier>mskcc:2045</mods:identifier>
        <mods:titleInfo authority="" displayLabel="">
            <mods:title>Sample Title</mods:title>
            <mods:subTitle>Sample SubTitle</mods:subTitle>
        </mods:titleInfo>
        <mods:name type="personal" authority="" ID="owner">
        	<mods:namePart type="family">Smith</mods:namePart>
    	<mods:namePart type="given">John</mods:namePart>
    	<mods:namePart type="termsOfAddress">Mr.</mods:namePart>
             <mods:affiliation>Surgery</mods:affiliation>
            <mods:role>
                <mods:roleTerm type="text" authority="">Owner</mods:roleTerm>
            </mods:role>
        </mods:name>
        <mods:name type="personal" authority="non-owner">
        	<mods:namePart type="family">Rushdie</mods:namePart>
    	<mods:namePart type="given">Salman</mods:namePart>
    	<mods:namePart type="termsOfAddress">Mr.</mods:namePart>
             <mods:affiliation>Surgery</mods:affiliation>
            <mods:role>
                <mods:roleTerm type="text" authority="">Contributor</mods:roleTerm>
            </mods:role>
        </mods:name>
        <mods:originInfo>
            <mods:place>
                <mods:placeTerm type="text">Sample Place of Creation</mods:placeTerm>
            </mods:place>
            <mods:publisher>MSKCC</mods:publisher>
            <mods:dateIssued encoding="" keydate="" qualifier="" point=""/>
            <mods:dateCreated encoding="" keydate="" qualifier="" point=""/>
            <mods:dateModified encoding="" keydate="" qualifier="" point=""/>
            <mods:copyrightDate encoding="" keydate="" qualifier="" point=""/>
            <mods:dateOther encoding="" keydate="" qualifier="" point=""/>
        </mods:originInfo>
        <mods:abstract displayLabel="" type=""></mods:abstract>
        <mods:note type=""/>
        <mods:subject authority="lcsh">
            <mods:topic>carcinoma</mods:topic>
            <mods:topic>adinoma</mods:topic>
         </mods:subject>
        <!-- part, extension -->
    </mods:mods>    
    EOS
  end
  
  before(:all) do
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
    @fedora = Fedora::Repository.instance
  end

  before(:each) do
    @test_object = Fedora::FedoraObject.new(:label => 'test', 
      :contentModel => 'Image',
      :state => 'A',
      :ownerID => 'fedoraAdmin')

    @fedora.save(@test_object).should be_true
  end
  
  after(:each) do
    @fedora.delete(@test_object).should be_true
  end
  
  def fetch_content(pid, dsID)
    content = @fedora.fetch_content("#{pid}/datastreams/#{dsID}/content")
  end
  
  it "should create/update xml datastream" do
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'foo', :altIDs => '3333', 
      :blob => sample_mods)
    @fedora.save(ds).should be_true
    
    ds.attributes[:dsLabel] = 'bar'
    @fedora.save(ds).should be_true
  end

  it "should be able to save file objects" do
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'hello', :altIDs => '3333', 
      :controlGroup => 'M', :blob => fixture('dino.jpg'))
      
    ds.control_group.should == 'M'
    @fedora.save(ds).should be_true
  end

  it "should be able to save StringIO objects" do
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'hello', :altIDs => '3333', :controlGroup => 'M', :blob => StringIO.new("hi there"))
      
    @fedora.save(ds).should be_true
end
  
  it "should create/update image/file datastream" do
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'hello', :altIDs => '3333', 
      :controlGroup => 'M', :blob => fixture('dino.jpg'))
      
    @fedora.save(ds).should be_true
    
    content = fetch_content(@test_object.pid, 'DS1')
    content.content_type.should == 'image/jpeg'
        
    ds.blob = fixture('minivan.jpg')
    @fedora.save(ds).should be_true
  end

  it "should set controlGroup to 'M' if mimeType is specified" do
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'foo',
      :mimeType => 'text/plain', :blob => "This is plain text")
  end
  
  it "should create datastream with custom mimeType for text blob" do
    blob = "This is plain text"
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'foo',
      :mimeType => 'text/plain', :blob => blob)
    @fedora.save(ds).should be_true
    
    content = @fedora.fetch_content("#{@test_object.pid}/datastreams/DS1/content")
    content.should == blob
    content.content_type.should == 'text/plain'
  end
  
  it "should create datastream with custom mimeType for file blob" do
    blob = "This is plain text"
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'foo',
      :mimeType => 'image/jpeg', :blob => fixture('dino.jpg'))
    @fedora.save(ds).should be_true
    
    content = fetch_content(@test_object.pid, "DS1")
    content.content_type.should == 'image/jpeg'
  end
  
  it "should delete datastream by ref" do
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'foo', :altIDs => '3333', :blob => sample_mods)
    @fedora.save(ds).should be_true
    @fedora.delete(ds).should be_true
  end
  
  it "should delete datastream by uri" do
    ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DS1', :dsLabel => 'foo', :altIDs => '3333', :blob => sample_mods)
    @fedora.save(ds).should be_true    
    @fedora.delete(ds.uri).should be_true
  end
  
  it "should fetch thumbnail jpg for Image of Coliseum in Rome" do
    # Have to check for two possible sizes because the image size changed between Fedora 3.0 and Fedora 3.1
    fetch_content("demo:26", "TEI_SOURCE").length.should satisfy{ |l| l == 1098 || 1086}
  end
  
  describe ".label" do
    it "should apply to the dsLabel when you save the datastream" do 
      ds = Fedora::Datastream.new(:pid => @test_object.pid, :dsID => 'DSLabelTest', :blob => sample_mods)
      ds.label = "My Test dsLabel"
      @fedora.save(ds)
      object_rexml = REXML::Document.new(@test_object.object_xml)
      #puts object_rexml.root.elements["foxml:datastream[@ID='DSLabelTest']/foxml:datastreamVersion"].inspect
      object_rexml.root.elements["foxml:datastream[@ID='DSLabelTest']/foxml:datastreamVersion[last()]"].attributes["LABEL"].should == ds.label
    end
  end
end
