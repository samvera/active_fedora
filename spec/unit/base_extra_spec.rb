require File.join( File.dirname(__FILE__), "../spec_helper" )
require 'active_fedora'
require 'active_fedora/base'
require 'active_fedora/metadata_datastream'

describe ActiveFedora::Base do
  
  before(:each) do
    Fedora::Repository.instance.expects(:nextid).returns("__nextid__")
    @test_object = ActiveFedora::Base.new
    #Fedora::Repository.instance.delete(@test_object.inner_object)
  end
  
  describe ".metadata_streams" do
    it "should return all of the datastreams from the object that are kinds of MetadataDatastreams " do
      mock_mds1 = mock("metadata ds")
      mock_mds1.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      mock_mds2 = mock("metadata ds")
      mock_mds2.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      mock_fds = mock("file ds")
      mock_fds.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      @test_object.expects(:datastreams).returns({:foo => mock_mds1, :bar => mock_mds2, :baz => mock_fds})
      
      result = @test_object.metadata_streams
      result.length.should == 2
      result.should include(mock_mds1)
      result.should include(mock_mds2)
    end
  end
  
  describe ".file_streams" do
    it "should return all of the datastreams from the object that are kinds of MetadataDatastreams" do
      mock_fds1 = mock("file ds", :dsid => "file1")
      mock_fds1.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      mock_fds2 = mock("file ds", :dsid => "file2")
      mock_fds2.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      mock_mds = mock("metadata ds")
      mock_mds.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      @test_object.expects(:datastreams).returns({:foo => mock_fds1, :bar=> mock_fds2, :baz => mock_mds})
      
      result = @test_object.file_streams
      result.length.should == 2
      result.should include(mock_fds1)
      result.should include(mock_fds2)

    end
    it "should skip DC and RELS-EXT datastreams" do
      mock_fds1 = mock("file ds", :dsid => "foo")
      mock_fds1.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      dc = mock("DC", :dsid => "DC")
      dc.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      rels_ext = mock("RELS-EXT", :dsid => "RELS-EXT")
      rels_ext.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      @test_object.expects(:datastreams).returns({:foo => mock_fds1, :dc => dc, :rels_ext => rels_ext})
      
      result = @test_object.file_streams
      result.length.should == 1
      result.should include(mock_fds1)
    end
  end

  describe ".update_index" do
    it "should call .to_solr on all MetadataDatastreams AND RelsExtDatastreams and pass the resulting document to solr" do
      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock("SolrConnection", :update)))
      # Actually uses self.to_solr internally to gather solr info from all metadata datastreams
      mock1 = mock("ds1", :to_solr)
      mock2 = mock("ds2", :to_solr)
      mock3 = mock("RELS-EXT", :to_solr)
      mock1.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      mock2.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(true)
      mock3.expects(:kind_of?).with(ActiveFedora::MetadataDatastream).returns(false)
      mock3.expects(:kind_of?).with(ActiveFedora::RelsExtDatastream).returns(true)

      @test_object.expects(:datastreams).returns({:ds1 => mock1, :ds2 => mock2, :rels_ext => mock3})
      @test_object.update_index
    end

    it "should retrieve a solr Connection and call Connection.update" do
      ActiveFedora::SolrService.expects(:instance).returns(mock("SolrService", :conn => mock("SolrConnection", :update)))
      @test_object.update_index
    end

  end
  
  describe ".delete" do
    
    before(:each) do
    end
    
    it "should delete object from repository and index" do
      @test_object.expects(:pid).returns("foo")
      ActiveFedora::SolrService.instance.conn.expects(:delete).with("foo")      
      Fedora::Repository.instance.stubs(:delete).with(@test_object.inner_object)
      @test_object.delete
    end

  end
  
  describe '#pids_from_uris' do 
    it "should strip the info:fedora/ out of a given string" do 
      ActiveFedora::Base.pids_from_uris("info:fedora/FOOBAR").should == "FOOBAR"
    end
    it "should accept an array of strings"do 
      ActiveFedora::Base.pids_from_uris(["info:fedora/FOOBAR", "info:fedora/BAZFOO"]).should == ["FOOBAR", "BAZFOO"]
    end
  end

end
