require 'spec_helper'

describe ActiveFedora::Datastreams do
  before do
    @test_object = ActiveFedora::Base.new
  end

  it "should respond_to has_metadata" do
    ActiveFedora::Base.respond_to?(:has_metadata).should be_true
  end

  describe "datastream_from_spec" do
    it "should accept versionable" do
      ds = @test_object.datastream_from_spec({:type=>ActiveFedora::Datastream, :versionable=>false}, 'test')
      ds.versionable.should be_false
      ds = @test_object.datastream_from_spec({:type=>ActiveFedora::Datastream, :versionable=>true}, 'test')
      ds.versionable.should be_true
    end
    it "should default versionable to true" do
      ds = @test_object.datastream_from_spec({:type=>ActiveFedora::Datastream}, 'test') 
      ds.versionable.should be_true
    end

  end

  describe "has_metadata" do
    @@last_pid = 0
    def increment_pid
      @@last_pid += 1    
    end

    before(:each) do
      @this_pid = increment_pid.to_s
      stub_get(@this_pid)
      Rubydora::Repository.any_instance.stubs(:client).returns(@mock_client)
      ActiveFedora::Base.stubs(:assign_pid).returns(@this_pid)
      #ActiveFedora::RubydoraConnection.instance.stubs(:nextid).returns(@this_pid)
    end

    describe "updates the spec" do
      before do
        class FooHistory < ActiveFedora::Base
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end
      subject { FooHistory}
      it "should update the ds_spec" do
        FooHistory.ds_specs.keys.should == ['RELS-EXT']
        FooHistory.has_metadata :type=>ActiveFedora::Datastream, :name=>'new_ds'
        FooHistory.ds_specs.keys.should include 'new_ds'
      end
      it "should be able to set a type" do
        FooHistory.has_metadata :type=>ActiveFedora::Datastream, :name=>'new_ds', :control_group=>'R'
        FooHistory.ds_specs['new_ds'][:control_group].should == 'R'
      end
      it "should be able to set versionable to false" do
        FooHistory.has_metadata :type=>ActiveFedora::Datastream, :name=>'new_ds', :versionable=>false
        FooHistory.ds_specs['new_ds'][:versionable].should be_false
      end
      it "should be able to set versionable to true" do
        FooHistory.has_metadata :type=>ActiveFedora::Datastream, :name=>'new_ds', :versionable=>true
        FooHistory.ds_specs['new_ds'][:versionable].should be_true
      end
      it "should not set versionable if it's not supplied" do
        FooHistory.has_metadata :type=>ActiveFedora::Datastream, :name=>'new_ds'
        FooHistory.ds_specs['new_ds'].keys.should_not include :versionable
      end
      
    end

    describe "creates datastreams" do
      before do
        class FooHistory < ActiveFedora::Base
          has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
            m.field "fubar", :string
            m.field "swank", :text
          end
          has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"withText2", :label=>"withLabel" do |m|
            m.field "fubar", :text
          end 
        end
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT', 'someData', 'withText', 'withText2'])

        @n = FooHistory.new()
        FooHistory.stubs(:assign_pid).returns(@this_pid)
        @n.datastreams['RELS-EXT'].expects(:changed?).returns(true).at_least_once
        @n.expects(:update_index)
        @n.save
      end

      after do
        Object.send(:remove_const, :FooHistory)
      end

      it "should create specified datastreams with specified fields" do
        @n.datastreams["someData"].should_not be_nil
        @n.datastreams["someData"].fubar_values='bar'
        @n.datastreams["someData"].fubar_values.should == ['bar']
        @n.datastreams["withText2"].dsLabel.should == "withLabel"
      end
    end


    it "should create specified datastreams with appropriate control group" do
      ActiveFedora.stubs(:config_for_environment).returns(:url=>'sub_url')
      stub_ingest(@this_pid)
      stub_add_ds(@this_pid, ['RELS-EXT', 'DC', 'rightsMetadata', 'properties', 'descMetadata', 'UKETD_DC'])
      stub_get(@this_pid, ['RELS-EXT', 'DC', 'rightsMetadata', 'properties', 'descMetadata', 'UKETD_DC'])
      class UketdObject < ActiveFedora::Base
        has_metadata :name => "rightsMetadata", :label=>"Rights metadata", :type => ActiveFedora::NokogiriDatastream 
        
        # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
        # TODO: define terminology for ETD
        has_metadata :name => "descMetadata", :label=>"MODS metadata", :control_group=>"M", :type => ActiveFedora::NokogiriDatastream

        has_metadata :name => "UKETD_DC", :label=>"UKETD_DC metadata", :control_group => "E", :disseminator=>"hull-sDef:uketdObject/getUKETDMetadata", :type => ActiveFedora::NokogiriDatastream

        has_metadata :name => "DC", :type => ActiveFedora::NokogiriDatastream, :label=>"DC admin metadata"

        # A place to put extra metadata values
        has_metadata :name => "properties", :label=>"Workflow properties", :type => ActiveFedora::MetadataDatastream do |m|
          m.field 'collection', :string
          m.field 'depositor', :string
        end

      end
      @n = UketdObject.new()
      UketdObject.stubs(:assign_pid).returns(@this_pid)
      @n.save
      @n.datastreams["DC"].controlGroup.should eql("X")
      @n.datastreams["rightsMetadata"].controlGroup.should eql("X")
      @n.datastreams["properties"].controlGroup.should eql("X")
      @n.datastreams["descMetadata"].controlGroup.should eql("M")
      @n.datastreams["UKETD_DC"].controlGroup.should eql("E")
      @n.datastreams["UKETD_DC"].dsLocation.should == "sub_url/objects/#{@this_pid}/methods/hull-sDef:uketdObject/getUKETDMetadata"
    end


    context ":control_group => 'E'" do
      before do
        stub_get(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT', 'externalDisseminator', 'externalUrl'])
      end

      after :each do
        # clean up test class
        Object.send(:remove_const, :MoreFooHistory)
      end
      
      it "should allow :control_group => 'E' with a :url option" do
        class MoreFooHistory < ActiveFedora::Base
          has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"externalDisseminator",:control_group => "E", :url => "http://exampl.com/mypic.jpg"
        end
        stub_ingest(@this_pid)
        @n = MoreFooHistory.new
        MoreFooHistory.stubs(:assign_pid).returns(@this_pid)
        @n.save
        @n.datastreams['externalDisseminator'].dsLocation.should == "http://exampl.com/mypic.jpg"
      end
      
      describe "control_group E without a url" do
        before do
          class MoreFooHistory < ActiveFedora::Base
            has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"externalDisseminator",:control_group => "E"
          end
          stub_ingest(@this_pid)
          @n = MoreFooHistory.new
          MoreFooHistory.stubs(:assign_pid).returns(@this_pid)
        end
        it "should allow :control_group => 'E' without a :url option" do
          @n.datastreams['externalDisseminator'].dsLocation.present?.should == false
          @n.save
        end
        
        it "should fail validation if a :url is not added before save" do
          @n.datastreams['externalDisseminator'].validate_content_present.should == false
          @n.save
        end
        
        it "should pass validation if a :url is added before save" do
          @n.datastreams['externalDisseminator'].dsLocation = "http://exampl.com/mypic.jpg"
          @n.datastreams['externalDisseminator'].validate_content_present.should == true
          @n.save
        end
      end
    end

    context ":control_group => 'R'" do
      before do
        stub_get(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT', 'externalDisseminator' ])
      end
      
      after :each do
        Object.send(:remove_const, :MoreFooHistory)
      end
      
      it "should allow :control_group => 'R' with a :url option" do
        stub_ingest(@this_pid)
        class MoreFooHistory < ActiveFedora::Base
          has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"externalDisseminator",:control_group => "R", :url => "http://exampl.com/mypic.jpg"
        end
        @n = MoreFooHistory.new
        MoreFooHistory.stubs(:assign_pid).returns(@this_pid)
        @n.save
      end
    
      describe "control_group R without url" do
        before do
          class MoreFooHistory < ActiveFedora::Base
            has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"externalDisseminator",:control_group => "R"
          end
          MoreFooHistory.stubs(:assign_pid).returns(@this_pid)
          stub_ingest(@this_pid)
          @n = MoreFooHistory.new
        end
        it "should allow :control_group => 'R' without a :url option" do
          @n.datastreams['externalDisseminator'].dsLocation.present?.should == false
          @n.save
        end
      
        it "should fail validation if a :url is not added before save" do
          @n.datastreams['externalDisseminator'].validate_content_present.should == false
          @n.save
        end
      
        it "should pass validation if a :url is added before save" do
          @n.datastreams['externalDisseminator'].dsLocation = "http://exampl.com/mypic.jpg"
          @n.datastreams['externalDisseminator'].validate_content_present.should == true
          @n.save
        end
      end
    end
  end

  describe "#create_datastream" do
    it 'should create a datastream object using the type of object supplied in the string (does reflection)' do
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:blob=>f})
      ds.class.should == ActiveFedora::Datastream
      ds.dsLabel.should == "minivan.jpg"
      ds.mimeType.should == "image/jpeg"
    end
    it 'should create a datastream object from a string' do
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:blob=>"My file data"})
      ds.class.should == ActiveFedora::Datastream
      ds.dsLabel.should == nil
      ds.mimeType.should == "application/octet-stream"
    end

    it 'should not set dsLocation if dsLocation is nil' do
      ActiveFedora::Datastream.any_instance.expects(:dsLocation=).never
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:dsLocation=>nil})
    end

    it 'should set attributes passed in onto the datastream' do
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:dsLocation=>"a1", :mimeType=>'image/png', :controlGroup=>'X', :dsLabel=>'My Label', :checksumType=>'SHA-1'})
      ds.location.should == 'a1'
      ds.mimeType.should == 'image/png'
      ds.controlGroup.should == 'X'
      ds.label.should == 'My Label'
      ds.checksumType.should == 'SHA-1'
    end
  end

  describe ".has_file_datastream" do
    before do
      class FileDS < ActiveFedora::Datastream; end
      class FooHistory < ActiveFedora::Base
        has_file_datastream
        has_file_datastream :name=>"second", :label=>"Second file", :type=>FileDS, :control_group=>'X'
      end
    end
    after do
      Object.send(:remove_const, :FooHistory)
      Object.send(:remove_const, :FileDS)
    end
    it "Should add a line in ds_spec" do
      FooHistory.ds_specs['content'][:type].should == ActiveFedora::Datastream
      FooHistory.ds_specs['content'][:label].should == "File Datastream"
      FooHistory.ds_specs['content'][:control_group].should == "M"
      FooHistory.ds_specs['second'][:type].should == FileDS
      FooHistory.ds_specs['second'][:label].should == "Second file"
      FooHistory.ds_specs['second'][:control_group].should == "X"
    end
  end

  describe "#add_file_datastream" do
    before do
      @mock_file = mock('file')
    end
    it "should pass prefix" do
      stub_add_ds(@test_object.pid, ['content1'])
      @test_object.add_file_datastream(@mock_file, :prefix=>'content' )
      @test_object.datastreams.keys.should include 'content1'
    end
    it "should pass dsid" do
      stub_add_ds(@test_object.pid, ['MY_DSID'])
      @test_object.add_file_datastream(@mock_file, :dsid=>'MY_DSID')
      @test_object.datastreams.keys.should include 'MY_DSID'
    end
    it "without dsid or prefix" do
      stub_add_ds(@test_object.pid, ['DS1'])
      @test_object.add_file_datastream(@mock_file, {} )
      @test_object.datastreams.keys.should include 'DS1'
    end
    it "Should pass checksum Type" do
      stub_add_ds(@test_object.pid, ['DS1'])
      @test_object.add_file_datastream(@mock_file, {:checksumType=>'MD5'} )
      @test_object.datastreams['DS1'].checksumType.should == 'MD5'
    end
  end

end
