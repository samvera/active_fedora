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
      allow(f2).to receive(:original_filename).and_return("dino.jpg")
      allow(f).to receive(:content_type).and_return("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f, :label=>"testDS"})
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      ds = @test_object2.thumbnail.first
      ds2 = @test_object2.high.first
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      expect(@test_object2.named_datastreams.keys.size).to eq(2)
      expect(@test_object2.named_datastreams.keys.include?("thumbnail")).to eq(true)
      expect(@test_object2.named_datastreams.keys.include?("high")).to eq(true)
      expect(@test_object2.named_datastreams["thumbnail"].size).to eq(1)
      expect(@test_object2.named_datastreams["high"].size).to eq(1)
      t2_thumb1 = @test_object2.named_datastreams["thumbnail"].first
      expect(t2_thumb1.dsid).to eq(ds.dsid)
      expect(t2_thumb1.mimeType).to eq(ds.mimeType)
      expect(t2_thumb1.pid).to eq(ds.pid)
      expect(t2_thumb1.dsLabel).to eq(ds.dsLabel)
      expect(t2_thumb1.controlGroup).to eq(ds.controlGroup)
      t2_high1 = @test_object2.named_datastreams["high"].first
      expect(t2_high1.dsid).to eq(ds2.dsid)
      expect(t2_high1.mimeType).to eq(ds2.mimeType)
      expect(t2_high1.pid).to eq(ds2.pid)
      expect(t2_high1.dsLabel).to eq(ds2.dsLabel)
      expect(t2_high1.controlGroup).to eq(ds2.controlGroup)
    end
  end

  describe '#add_named_file_datastream' do
    it 'should add a file datastream with the given name to the object in fedora' do
      @test_object2 = MockAFBaseDatastream.new
#      @test_object2.new_object = true
      f = File.open(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"), 'rb')
      allow(f).to receive(:content_type).and_return("image/jpeg")
      @test_object2.add_named_file_datastream("thumbnail",f)
      ds = @test_object2.thumbnail.first
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      expect(@test_object2.named_datastreams["thumbnail"].size).to eq(1)
      t2_thumb1 = @test_object2.named_datastreams["thumbnail"].first
      expect(t2_thumb1.dsid).to eq("THUMB1")
      expect(t2_thumb1.mimeType).to eq("image/jpeg")
      expect(t2_thumb1.pid).to eq(@test_object2.pid)
      expect(t2_thumb1.dsLabel).to eq("minivan.jpg")
      expect(t2_thumb1.controlGroup).to eq("M")

# .attributes.should == {"label"=>ds.label,"dsid"=>ds.dsid,
#                                                                                  "mimeType"=>ds.attributes[:mimeType],
#                                                                                  :controlGroup=>ds.attributes[:controlGroup],
#                                                                                  :pid=>ds.pid, :dsID=>ds.dsid, :dsLabel=>ds.attributes[:dsLabel]}
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
      allow(f).to receive(:content_type).and_return("image/jpeg")
      allow(f).to receive(:original_filename).and_return("minivan.jpg")
      allow(f2).to receive(:content_type).and_return("image/jpeg")
      allow(f2).to receive(:original_filename).and_return("dino.jpg")
      #check raise exception if dsid not supplied
      @test_object2.add_named_datastream("thumbnail",{:file=>f})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)

      expect(@test_object2.thumbnail.size).to eq(1)
      @test_object2.thumbnail_ids == ["THUMB1"]
      ds = @test_object2.thumbnail.first
      expect(ds.dsid).to eq("THUMB1")
      expect(ds.mimeType).to eq("image/jpeg")
      expect(ds.pid).to eq(@test_object2.pid)
      expect(ds.dsLabel).to eq("minivan.jpg")
      expect(ds.controlGroup).to eq("M")

      expect(ds.content).to eq(minivan)
      @test_object2.update_named_datastream("thumbnail",{:file=>f2,:dsid=>"THUMB1"})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      expect(@test_object2.thumbnail.size).to eq(1)
      @test_object2.thumbnail_ids == ["THUMB1"]
      ds2 = @test_object2.thumbnail.first
      expect(ds2.dsid).to eq("THUMB1")
      expect(ds2.mimeType).to eq("image/jpeg")
      expect(ds2.pid).to eq(@test_object2.pid)
      expect(ds2.dsLabel).to eq("dino.jpg")
      expect(ds2.controlGroup).to eq("M")
      expect(ds2.content == dino).to be_truthy
    end
  end

  describe '#named_datastreams_ids' do
    it 'should return a hash of datastream name to an array of dsids' do
      @test_object2 = MockAFBaseDatastream.new
#      @test_object2.new_object = true
      f = File.open(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"), 'rb')
      f2 = File.open(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ), 'rb')
      allow(f2).to receive(:original_filename).and_return("dino.jpg")
      allow(f).to receive(:content_type).and_return("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f, :label=>"testDS"})
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f2})
      @test_object2.save
      @test_object2 = MockAFBaseDatastream.find(@test_object2.pid)
      expect(@test_object2.named_datastreams_ids).to eq({"high"=>[], "thumbnail"=>["THUMB1", "THUMB2"]})
    end
  end

end
