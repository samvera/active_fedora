require 'spec_helper'

describe ActiveFedora::DatastreamCollections do
  before(:all) do
    class MockAFBaseDatastream < ActiveFedora::Base
      include ActiveFedora::DatastreamCollections
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
    end
  end

  #
  # Named datastream specs
  #
  describe '#add_named_datastream' do
    it 'should add a datastream with the given name to the object in fedora' do
      @test_object2 = MockAFBaseDatastream.new
      f = File.open(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"), 'rb')
      f2 = File.open(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ), 'rb')
      f2.stub(:original_filename).and_return("dino.jpg")
      f.stub(:content_type).and_return("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f, :label=>"testDS"})
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      ds = @test_object2.thumbnail.first
      ds2 = @test_object2.high.first
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      @test_object2.named_datastreams.keys.size.should == 2
      @test_object2.named_datastreams.keys.include?("thumbnail").should == true
      @test_object2.named_datastreams.keys.include?("high").should == true
      @test_object2.named_datastreams["thumbnail"].size.should == 1
      @test_object2.named_datastreams["high"].size.should == 1
      t2_thumb1 = @test_object2.named_datastreams["thumbnail"].first
      t2_thumb1.dsid.should == ds.dsid
      t2_thumb1.mimeType.should == ds.mimeType
      t2_thumb1.pid.should == ds.pid
      t2_thumb1.dsLabel.should == ds.dsLabel
      t2_thumb1.controlGroup.should == ds.controlGroup
      t2_high1 = @test_object2.named_datastreams["high"].first
      t2_high1.dsid.should == ds2.dsid
      t2_high1.mimeType.should == ds2.mimeType
      t2_high1.pid.should == ds2.pid
      t2_high1.dsLabel.should == ds2.dsLabel
      t2_high1.controlGroup.should == ds2.controlGroup
    end
  end
  
  describe '#add_named_file_datastream' do
    it 'should add a file datastream with the given name to the object in fedora' do
      @test_object2 = MockAFBaseDatastream.new
      f = File.open(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"), 'rb')
      f.stub(:content_type).and_return("image/jpeg")
      @test_object2.add_named_file_datastream("thumbnail",f)
      ds = @test_object2.thumbnail.first
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      @test_object2.named_datastreams["thumbnail"].size.should == 1
      t2_thumb1 = @test_object2.named_datastreams["thumbnail"].first
      t2_thumb1.dsid.should == "THUMB1"
      t2_thumb1.mimeType.should == "image/jpeg"
      t2_thumb1.pid.should == @test_object2.pid
      t2_thumb1.dsLabel.should == "minivan.jpg"
      t2_thumb1.controlGroup.should == "M"
    end
  end
  
  describe '#update_named_datastream' do
    it 'should update a named datastream to have a new file' do
      @test_object2 = MockAFBaseDatastream.new
      f = File.open(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"), 'rb')
      minivan = f.read
      f.rewind
      f2 = File.open(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ), 'rb')
      dino = f2.read
      f2.rewind
      f.stub(:content_type).and_return("image/jpeg")
      f.stub(:original_filename).and_return("minivan.jpg")
      f2.stub(:content_type).and_return("image/jpeg")
      f2.stub(:original_filename).and_return("dino.jpg")
      #check raise exception if dsid not supplied
      @test_object2.add_named_datastream("thumbnail",{:file=>f})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      ds = @test_object2.thumbnail.first
      ds.dsid.should == "THUMB1"
      ds.mimeType.should == "image/jpeg"
      ds.pid.should == @test_object2.pid
      ds.dsLabel.should == "minivan.jpg"
      ds.controlGroup.should == "M"

      ds.content.should == minivan 
      @test_object2.update_named_datastream("thumbnail",{:file=>f2,:dsid=>"THUMB1"})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      ds2 = @test_object2.thumbnail.first
      ds2.dsid.should == "THUMB1"
      ds2.mimeType.should == "image/jpeg"
      ds2.pid.should == @test_object2.pid
      ds2.dsLabel.should == "dino.jpg"
      ds2.controlGroup.should == "M"
      (ds2.content == dino).should be_true
    end
  end
  
  describe '#named_datastreams_ids' do
    it 'should return a hash of datastream name to an array of dsids' do
      @test_object2 = MockAFBaseDatastream.new
      f = File.open(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"), 'rb')
      f2 = File.open(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ), 'rb')
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f})
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f2})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      named_datastreams_ids = @test_object2.named_datastreams_ids

      expect(named_datastreams_ids.keys.sort).to eq(['high', 'thumbnail'])
      expect(named_datastreams_ids['high']).to eq([])
      expect(named_datastreams_ids['thumbnail'].sort).to eq(["THUMB1", "THUMB2"])
    end
  end

end