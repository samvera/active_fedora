require 'spec_helper'

describe ActiveFedora::Datastreams do
  subject { ActiveFedora::Base.new }

  describe '.has_metadata' do
    before do
      class FooHistory < ActiveFedora::Base
         has_metadata :name => 'dsid', type: ActiveFedora::SimpleDatastream
         has_metadata 'complex_ds', :versionable => true, :autocreate => true, :type => 'Z', :label => 'My Label', :control_group => 'Z'
      end
    end

    it "should have a ds_specs entry" do
      FooHistory.ds_specs.should have_key('dsid')
    end

    it "should have reasonable defaults" do
      FooHistory.ds_specs['dsid'].should include(:autocreate => false)
    end

    it "should let you override defaults" do
      FooHistory.ds_specs['complex_ds'].should include(:versionable => true, :autocreate => true, :type => 'Z', :label => 'My Label', :control_group => 'Z')
    end

    it "should raise an error if you don't give a type" do
      expect{ FooHistory.has_metadata "bob" }.to raise_error ArgumentError,
        "You must provide a :type property for the datastream 'bob'"
    end

    it "should raise an error if you don't give a dsid" do
      expect{ FooHistory.has_metadata type: ActiveFedora::SimpleDatastream }.to raise_error ArgumentError,
        "You must provide a name (dsid) for the datastream"
    end
  end

  describe '.has_file_datastream' do
    before do
      class FooHistory < ActiveFedora::Base
         has_file_datastream :name => 'dsid'
         has_file_datastream 'another'
      end
    end

    it "should have reasonable defaults" do
      FooHistory.ds_specs['dsid'].should include(:type => ActiveFedora::Datastream, :label => 'File Datastream', :control_group => 'M')
      FooHistory.ds_specs['another'].should include(:type => ActiveFedora::Datastream, :label => 'File Datastream', :control_group => 'M')
    end
  end

  describe "#serialize_datastreams" do
    it "should touch each datastream" do
      m1 = double()
      m2 = double()

      m1.should_receive(:serialize!)
      m2.should_receive(:serialize!)
       subject.stub(:datastreams => { :m1 => m1, :m2 => m2})
       subject.serialize_datastreams
    end
  end

  describe "#add_disseminator_location_to_datastreams" do
    it "should infer dsLocations for E datastreams without hitting Fedora" do
      
      mock_specs = {'e' => { :disseminator => 'xyz' }}
      mock_ds = double(:controlGroup => 'E')
      ActiveFedora::Base.stub(:ds_specs => mock_specs)
      ActiveFedora.stub(:config_for_environment => { :url => 'http://localhost'})
      subject.stub(:pid => 'test:1', :datastreams => {'e' => mock_ds})
      mock_ds.should_receive(:dsLocation=).with("http://localhost/objects/test:1/methods/xyz")
      subject.add_disseminator_location_to_datastreams
    end
  end

  describe ".name_for_dsid" do
    it "should use the name" do
      ActiveFedora::Base.send(:name_for_dsid, 'abc').should == 'abc'
    end

    it "should use the name" do
      ActiveFedora::Base.send(:name_for_dsid, 'ARCHIVAL_XML').should == 'ARCHIVAL_XML'
    end

    it "should use the name" do
      ActiveFedora::Base.send(:name_for_dsid, 'descMetadata').should == 'descMetadata'
    end

    it "should hash-erize underscores" do
      ActiveFedora::Base.send(:name_for_dsid, 'a-b').should == 'a_b'
    end
  end
 
  describe "#datastreams" do
    it "should return the datastream hash proxy" do
      subject.stub(:load_datastreams)
      subject.datastreams.should be_a_kind_of(ActiveFedora::DatastreamHash)
    end
  end

  describe "#configure_datastream" do
    it "should look up the ds_spec" do
      mock_dsspec = { :type => nil }
      subject.stub(:ds_specs => {'abc' => mock_dsspec})
      subject.configure_datastream(double(:dsid => 'abc'))
    end

    it "should be ok if there is no ds spec" do
      mock_dsspec = double()
      subject.stub(:ds_specs => {})
      subject.configure_datastream(double(:dsid => 'abc'))
    end

    it "should configure RelsExtDatastream" do
      mock_dsspec = { :type => ActiveFedora::RelsExtDatastream }
      subject.stub(:ds_specs => {'abc' => mock_dsspec})

      ds = double(:dsid => 'abc')
      ds.should_receive(:model=).with(subject)

      subject.configure_datastream(ds)
    end

    it "should run a Proc" do
      ds = double(:dsid => 'abc')
      @count = 0
      mock_dsspec = { :block => lambda { |x| @count += 1 } }
      subject.stub(:ds_specs => {'abc' => mock_dsspec})


      expect {
      subject.configure_datastream(ds)
      }.to change { @count }.by(1)
    end
  end

  describe "#datastream_from_spec" do
    it "should fetch the rubydora datastream" do
      subject.inner_object.should_receive(:datastream_object_for).with('dsid', {}, {})
      subject.datastream_from_spec({}, 'dsid')
    end
  end

  describe "#add_datastream" do
    it "should add the datastream to the object" do
      ds = double(:dsid => 'Abc')
      subject.add_datastream(ds)
      subject.datastreams['Abc'].should == ds
    end

    it "should mint a dsid" do
      ds = ActiveFedora::Datastream.new
      subject.add_datastream(ds).should == 'DS1'
    end
  end

  describe "#metadata_streams" do
    it "should only be metadata datastreams" do
      ds1 = double(:metadata? => true)
      ds2 = double(:metadata? => true)
      ds3 = double(:metadata? => true)
      relsextds = ActiveFedora::RelsExtDatastream.new
      file_ds = double(:metadata? => false)
      subject.stub(:datastreams => {:a => ds1, :b => ds2, :c => ds3, :d => relsextds, :e => file_ds})
      subject.metadata_streams.should include(ds1, ds2, ds3)
      subject.metadata_streams.should_not include(relsextds)
      subject.metadata_streams.should_not include(file_ds)
    end
  end

  describe "#generate_dsid" do
    it "should create an autoincrementing dsid" do
      subject.generate_dsid('FOO').should == 'FOO1'
    end

    it "should start from the highest existin dsid" do
      subject.stub(:datastreams => {'FOO56' => double()})
      subject.generate_dsid('FOO').should == 'FOO57'
    end
  end

  describe "#relsext" do
    it "should be the RELS-EXT datastream" do
      m = double
      subject.stub(:datastreams => { 'RELS-EXT' => m})
      subject.rels_ext.should == m
    end

    it "should make one up otherwise" do
      subject.stub(:datastreams => {})

      subject.rels_ext.should be_a_kind_of(ActiveFedora::RelsExtDatastream)
    end
  end

  describe "#add_file_datastream" do
    # tested elsewhere :/
  end 

  describe "#create_datastream" do
    it "should mint a DSID" do
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {})
      ds.dsid.should == 'DS1'
    end

    it "should raise an argument error if the supplied dsid is nonsense" do
      expect { subject.create_datastream(ActiveFedora::Datastream, 0) }.to raise_error(ArgumentError)
    end

    it "should try to get a mime type from the blob" do
      mock_file = double(:content_type => 'x-application/asdf')
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      ds.mimeType.should == 'x-application/asdf'
    end

    it "should provide a default mime type" do
      mock_file = double()
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      ds.mimeType.should == 'application/octet-stream'
    end

    it "should use the filename as a default label" do
     mock_file = double(:path => '/asdf/fdsa')
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      ds.dsLabel.should == 'fdsa'
    end
  end

  describe "#additional_attributes_for_external_and_redirect_control_groups" do
    before(:all) do
      @behavior = ActiveFedora::Datastreams.deprecation_behavior
      ActiveFedora::Datastreams.deprecation_behavior = :silence
    end
  
     after :all do
      ActiveFedora::Datastreams.deprecation_behavior = @behavior
    end

  end
end
