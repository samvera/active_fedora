require 'spec_helper'

describe ActiveFedora::DatastreamCollections do
  describe '.has_datastream' do
    before(:all) do
      
      class MockHasDatastream < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"EAD", :type=>ActiveFedora::Datastream, :mimeType=>"application/xml", :controlGroup=>'M' 
        has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E'
      end
    end
    
    it 'should cache a definition of named datastream and create helper methods to add/remove/access them' do
      @test_object2 = MockHasDatastream.new
      #prefix should default to name in caps if not specified in has_datastream call
      @test_object2.named_datastreams_desc.should == {"thumbnail"=>{:name=>"thumbnail",:prefix => "THUMB", 
                                                                    :type=>"ActiveFedora::Datastream", :mimeType=>"image/jpeg", 
                                                                    :controlGroup=>'M'},
                                                      "EAD"=>       {:name=>"EAD", :prefix=>"EAD",
                                                                    :type=>"ActiveFedora::Datastream", :mimeType=>"application/xml", 
                                                                    :controlGroup=>'M' },
                                                      "external"=>  {:name=>"external", :prefix=>"EXTERNAL",
                                                                    :type=>"ActiveFedora::Datastream", :controlGroup=>'E' }}
      @test_object2.should respond_to(:thumbnail_append)
      @test_object2.should respond_to(:thumbnail_file_append)
      @test_object2.should respond_to(:thumbnail)
      @test_object2.should respond_to(:thumbnail_ids)
      @test_object2.should respond_to(:ead_append)
      @test_object2.should respond_to(:ead_file_append)
      @test_object2.should respond_to(:EAD)
      @test_object2.should respond_to(:EAD_ids)
      @test_object2.should respond_to(:external)
      @test_object2.should respond_to(:external_ids)
    end
  end
  describe '#datastream_names' do
    before(:all) do
      class MockDatastreamNames < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"EAD", :type=>ActiveFedora::Datastream, :mimeType=>"application/xml", :controlGroup=>'M' 
      end
    end
    
    it 'should return a set of datastream names defined by has_datastream' do
      @test_object2 = MockDatastreamNames.new
      @test_object2.datastream_names.should include("thumbnail","EAD")
    end
  end
  
  describe '#add_named_datastream' do
    before(:all) do
      class MockAddNamedDatastream < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
        has_datastream :name=>"anymime", :type=>ActiveFedora::Datastream, :controlGroup=>'M' 
        has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E'
      end
    end
    before do

      @test_object2 = MockAddNamedDatastream.new
      @f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      @f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      @f.stub(:content_type).and_return("image/jpeg")
      @f2.stub(:original_filename).and_return("dino.jpg")
    end
      
    it 'cannot add a datastream with name that does not exist' do
      expect { @test_object2.add_named_datastream("thumb",{:content_type=>"image/jpeg",:blob=>f}) }.to raise_error
    end

    it "should accept a file blob" do
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>@f})
    end

    it "should accept a file handle" do
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:file=>@f})
    end

    it "should  allow access to file content" do
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:file=>@f})
      @test_object2.save!
      @test_object2.thumbnail[0].content
    end

    it "should raise an error if neither a blob nor file is set" do
      expect { @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg"}) }.to raise_error
    end

    it "should use the given label for the dsLabel" do
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>@f2, :label=>"my_image"})
      @test_object2.high.first.dsLabel.should == "my_image"
    end

    it "should fallback on using the file name" do
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>@f2})
      @test_object2.high.first.dsLabel.should == "dino.jpg"
    end 

    it "should check the file for a content type" do
      @f.should_receive(:content_type).and_return("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:file=>@f})
    end

    it "should raise an error if no content type is avialable" do
      expect { @test_object2.add_named_datastream("thumbnail",{:file=>@f2}) }.to raise_error
    end

    it "should encsure mimetype and content type match" do
      @f.stub(:content_type).and_return("image/tiff")
      expect { @test_object2.add_named_datastream("thumbnail",{:file=>f}) }.to raise_error
    end
      
    it "should allow any mime type" do
      #check for if any mime type allowed
      @test_object2.add_named_datastream("anymime",{:file=>@f})
      #check datastream created is of type ActiveFedora::Datastream
      @test_object2.anymime.first.class.should == ActiveFedora::Datastream
    end

    it "should cgecj that a dsid forms to the prefix" do
      #if dsid supplied check that conforms to prefix
      @f.stub(:content_type).and_return("image/jpeg")
      expect { @test_object2.add_named_datastream("thumbnail",{:file=>@f,:dsid=>"DS1"}) }.to raise_error
    end

    it "should have the right properties" do
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>@f2})
      #if prefix not set check uses name in CAPS and dsid uses prefix
      #@test_object2.high.first.attributes[:prefix].should == "HIGH"
      @test_object2.high.first.dsid.match(/HIGH[0-9]/)
      #check datastreams added with other right properties
      @test_object2.high.first.controlGroup.should == "M"
    end

    it "should work with external datastreams" do
      
      #check external datastream
      @test_object2.add_named_datastream("external",{:dsLocation=>"http://myreasource.com"})
      #check dslocation goes to dslabel
      @test_object2.external.first.dsLabel.should == "http://myreasource.com"
      #check datastreams added to fedora (may want to stub this at first)
    end
  end
  
  describe '#add_named_file_datastream' do
    before do
      class MockAddNamedFileDatastream < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
        has_datastream :name=>"anymime", :type=>ActiveFedora::Datastream, :controlGroup=>'M' 
      end
    end
    
    it 'should add a datastream as controlGroup M with blob set to file' do
      @test_object2 = MockAddNamedFileDatastream.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      #these normally supplied in multi-part post request
      f.stub(:original_filename).and_return("minivan.jpg")
      f.stub(:content_type).and_return("image/jpeg")
      @test_object2.add_named_file_datastream("thumbnail",f)
      thumb = @test_object2.thumbnail.first
      thumb.class.should == ActiveFedora::Datastream
      thumb.mimeType.should == "image/jpeg"
      thumb.dsid.should == "THUMB1"
      thumb.controlGroup.should == "M"
      thumb.dsLabel.should == "minivan.jpg"
      #thumb.name.should == "thumbnail"
        # :prefix=>"THUMB", :content_type=>"image/jpeg", :dsid=>"THUMB1", :dsID=>"THUMB1", 
        # :pid=>@test_object2.pid, :mimeType=>"image/jpeg", :controlGroup=>"M", :dsLabel=>"minivan.jpg", :name=>"thumbnail"}
      
    end
  end

  describe '#update_named_datastream' do
    before do
      class MockUpdateNamedDatastream < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      end
    end
    
    it 'should update a datastream and not increment the dsid' do
      @test_object2 = MockUpdateNamedDatastream.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f.stub(:content_type).and_return("image/jpeg")
      f.stub(:original_filename).and_return("minivan.jpg")
      f2.stub(:content_type).and_return("image/jpeg")
      f2.stub(:original_filename).and_return("dino.jpg")
      #check raise exception if dsid not supplied
      @test_object2.add_named_datastream("thumbnail",{:file=>f})
      had_exception = false
      begin
        @test_object2.update_named_datastream("thumbnail",{:file=>f})
      rescue
        had_exception = true
      end
      raise "Failed to raise exception if dsid not supplied" unless had_exception
      #raise exception if dsid does not exist
      had_exception = false
      begin
        @test_object2.update_named_datastream("thumbnail",{:file=>f,:dsid=>"THUMB100"})
      rescue
        had_exception = true
      end
      raise "Failed to raise exception if dsid does not exist" unless had_exception  
      #check datastream is updated in place without new dsid  
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      thumb1 = @test_object2.thumbnail.first
      thumb1.dsid.should == 'THUMB1'
      thumb1.pid.should == @test_object2.pid
      thumb1.dsLabel.should == 'minivan.jpg'
      f.rewind
      @test_object2.update_named_datastream("thumbnail",{:file=>f2,:dsid=>"THUMB1"})
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      # @test_object2.thumbnail.first.attributes.should == {:type=>"ActiveFedora::Datastream",
      #                                                     :content_type=>"image/jpeg", 
      #                                                     :prefix=>"THUMB", :mimeType=>"image/jpeg", 
      #                                                     :controlGroup=>"M", :dsid=>"THUMB1", 
      #                                                     :pid=>@test_object2.pid, :dsID=>"THUMB1", 
      #                                                     :name=>"thumbnail", :dsLabel=>"dino.jpg"}
      thumb1 = @test_object2.thumbnail.first
      thumb1.dsid.should == 'THUMB1'
      thumb1.pid.should == @test_object2.pid
      thumb1.dsLabel.should == 'dino.jpg'
    end
  end
  describe '#named_datastreams_desc' do
      
    before do
      class MockNamedDatastreamsDesc < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      end
    end
    
    it 'should intialize a value to an empty hash and then not modify afterward' do
      @test_object2 = MockNamedDatastreamsDesc.new
      @test_object2.named_datastreams_desc.should == {"thumbnail"=>{:name=>"thumbnail",:prefix => "THUMB", 
                                                                    :type=>"ActiveFedora::Datastream", :mimeType=>"image/jpeg", 
                                                                    :controlGroup=>'M'}}
    end
  end

  describe '#is_named_datastream?' do
    before do
      class MockIsNamedDatastream < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      end
    end
    
    it 'should return true if a named datastream exists in model' do
      @test_object2 = MockIsNamedDatastream.new
      @test_object2.is_named_datastream?("thumbnail").should == true
      @test_object2.is_named_datastream?("thumb").should == false
    end
  end
  
  
  describe '#named_datastreams' do
    before do
      class MockNamedDatastreams < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
        has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E' 
      end
    end
    
    it 'should return a hash of datastream names to arrays of datastreams' do
      @test_object2 = MockNamedDatastreams.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg" ))
      f.stub(:content_type).and_return("image/jpeg")
      f.stub(:original_filename).and_return("minivan.jpg")
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stub(:content_type).and_return("image/jpeg")
      f2.stub(:original_filename).and_return("dino.jpg")
      @test_object2.thumbnail_file_append(f)
      @test_object2.high_file_append(f2)
      @test_object2.external_append({:dsLocation=>"http://myresource.com"})
      datastreams = @test_object2.named_datastreams
      datastreams.keys.include?("thumbnail").should == true
      datastreams.keys.include?("external").should == true
      datastreams.keys.include?("high").should == true
      datastreams.keys.size.should == 3
      datastreams["thumbnail"].size.should == 1
      datastreams["thumbnail"].first.dsid.should == 'THUMB1'
      datastreams["thumbnail"].first.dsLabel.should == 'minivan.jpg'
      datastreams["thumbnail"].first.controlGroup.should == "M"

      datastreams["external"].size.should == 1
      datastreams["external"].first.dsid.should == "EXTERNAL1"
      datastreams["external"].first.dsLocation.should == "http://myresource.com"
      datastreams["external"].first.controlGroup.should == "E"
      datastreams["external"].first.content.should == "" 

      datastreams["high"].size.should == 1
      datastreams["high"].first.dsLabel.should == 'dino.jpg'
      datastreams["high"].first.controlGroup.should == "M"
      datastreams["high"].first.dsid.should == "HIGH1"
    end
  end
  
  
    
  describe '#named_datastreams_ids' do
    before do
      class MockNamedDatastreamsIds < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
        has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E' 
      end
    end
    
    it 'should provide a hash of datastreams names to array of datastream ids' do
      @test_object2 = MockNamedDatastreamsIds.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg" ))
      f.stub(:content_type).and_return("image/jpeg")
      f.stub(:original_filename).and_return("minivan.jpg")
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stub(:content_type).and_return("image/jpeg")
      f2.stub(:original_filename).and_return("dino.jpg")
      @test_object2.thumbnail_file_append(f)
      @test_object2.high_file_append(f2)
      @test_object2.external_append({:dsLocation=>"http://myresource.com"})
      @test_object2.named_datastreams_ids.should == {"thumbnail"=>["THUMB1"],"high"=>["HIGH1"],"external"=>["EXTERNAL1"]}
    end
  end
  
    
  describe '#create_named_datastream_finders' do
    before do
      class MockCreateNamedDatastreamFinder < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
      end
    end
    
    it 'should create helper methods to get named datastreams or dsids' do
      @test_object2 = MockCreateNamedDatastreamFinder.new
      @test_object2.should respond_to(:thumbnail)
      @test_object2.should respond_to(:thumbnail_ids)  
      @test_object2.should respond_to(:high)
      @test_object2.should respond_to(:high_ids)
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stub(:original_filename).and_return("dino.jpg")
      f.stub(:content_type).and_return("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f, :label=>"testDS"})
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      t2_thumb1 = @test_object2.thumbnail.first
      t2_thumb1.mimeType.should == "image/jpeg"
      t2_thumb1.controlGroup.should == "M"
      t2_thumb1.dsLabel.should == "testDS"
      t2_thumb1.pid.should == @test_object2.pid 
      t2_thumb1.dsid.should == "THUMB1"
      # :type=>"ActiveFedora::Datastream", 
      # :prefix=>"THUMB", :content_type=>"image/jpeg", :dsid=>"THUMB1", :dsID=>"THUMB1", 
      # :pid=>@test_object2.pid, :mimeType=>"image/jpeg", :controlGroup=>"M", :dsLabel=>"testDS", :name=>"thumbnail", :label=>"testDS"}
      @test_object2.thumbnail_ids.should == ["THUMB1"]
      @test_object2.high_ids.include?("HIGH1") == true
      @test_object2.high_ids.include?("HIGH2") == true
      @test_object2.high_ids.size.should == 2
      #just check returning datastream object at this point
      @test_object2.high.first.class.should == ActiveFedora::Datastream
    end
  end
    
  describe '#create_named_datastream_update_methods' do
    before do
      class MockCreateNamedDatastreamUpdateMethods < ActiveFedora::Base
        include ActiveFedora::DatastreamCollections
        has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
        has_datastream :name=>"EAD", :type=>ActiveFedora::Datastream, :mimeType=>"application/xml", :controlGroup=>'M' 
        has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E' 
      end
    end
    
    it 'should create append method for each has_datastream entry' do
      @test_object2 = MockCreateNamedDatastreamUpdateMethods.new
      @test_object3 = MockCreateNamedDatastreamUpdateMethods.new
      @test_object2.should respond_to(:thumbnail_append)
      @test_object2.should respond_to(:ead_append)
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f.stub(:content_type).and_return("image/jpeg")
      f.stub(:original_filename).and_return("minivan.jpg")
      @test_object2.thumbnail_file_append(f)
      t2_thumb1 = @test_object2.thumbnail.first
      t2_thumb1.mimeType.should == "image/jpeg"
      t2_thumb1.dsLabel.should == "minivan.jpg"
      t2_thumb1.pid.should == @test_object2.pid 
      t2_thumb1.dsid.should == "THUMB1"
      @test_object3.thumbnail_append({:file=>f})
      t3_thumb1 = @test_object3.thumbnail.first
      t3_thumb1.mimeType.should == "image/jpeg"
      t3_thumb1.dsLabel.should == "minivan.jpg"
      t3_thumb1.pid.should == @test_object3.pid 
      t3_thumb1.dsid.should == "THUMB1"
      @test_object3.external_append({:dsLocation=>"http://myresource.com"})
      t3_external1 = @test_object3.external.first
      t3_external1.dsLabel.should == "http://myresource.com"
      t3_external1.dsLocation.should == "http://myresource.com"
      t3_external1.pid.should == @test_object3.pid 
      t3_external1.dsid.should == "EXTERNAL1"
      t3_external1.controlGroup == 'E'
    end
  end
end
