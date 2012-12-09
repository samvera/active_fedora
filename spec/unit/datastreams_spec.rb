require 'spec_helper'

describe ActiveFedora::Datastreams do
  subject { ActiveFedora::Base.new }

  describe '.has_metadata' do
    before do
      class FooHistory < ActiveFedora::Base
         has_metadata :name => 'dsid'
         has_metadata :name => 'complex_ds', :versionable => true, :autocreate => true, :type => 'Z', :label => 'My Label', :control_group => 'Z'
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
  end

  describe '.has_file_datastream' do
    before do
      class FooHistory < ActiveFedora::Base
         has_file_datastream :name => 'dsid'
      end
    end

    it "should have reasonable defaults" do
      FooHistory.ds_specs['dsid'].should include(:type => ActiveFedora::Datastream, :label => 'File Datastream', :control_group => 'M')
    end
  end

  describe "#serialize_datastreams" do
    it "should touch each datastream" do
      m1 = mock()
      m2 = mock()

      m1.should_receive(:serialize!)
      m2.should_receive(:serialize!)
       subject.stub(:datastreams => { :m1 => m1, :m2 => m2})
       subject.serialize_datastreams
    end
  end

  describe "#add_disseminator_location_to_datastreams" do
    it "should infer dsLocations for E datastreams without hitting Fedora" do
      
      mock_specs = {:e => { :disseminator => 'xyz' }}
      mock_ds = mock(:controlGroup => 'E')
      ActiveFedora::Base.stub(:ds_specs => mock_specs)
      ActiveFedora.stub(:config_for_environment => { :url => 'http://localhost'})
      subject.stub(:pid => 'test:1', :datastreams => {:e => mock_ds})
      mock_ds.should_receive(:dsLocation=).with("http://localhost/objects/test:1/methods/xyz")
      subject.add_disseminator_location_to_datastreams
    end
  end

  describe "#corresponding_datastream_name" do
    before(:each) do
      subject.stub(:datastreams => { 'abc' => mock(), 'a_b_c' => mock(), 'a-b' => mock()})
    end

    it "should use the name, if it exists" do
      subject.corresponding_datastream_name('abc').should == 'abc'
    end

    it "should hash-erize underscores" do
      subject.corresponding_datastream_name('a_b').should == 'a-b'
    end

    it "should return nil if nothing matches" do
      subject.corresponding_datastream_name('xyz').should be_nil
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
      subject.configure_datastream(mock(:dsid => 'abc'))
    end

    it "should be ok if there is no ds spec" do
      mock_dsspec = mock()
      subject.stub(:ds_specs => {})
      subject.configure_datastream(mock(:dsid => 'abc'))
    end

    it "should configure RelsExtDatastream" do
      mock_dsspec = { :type => ActiveFedora::RelsExtDatastream }
      subject.stub(:ds_specs => {'abc' => mock_dsspec})

      ds = mock(:dsid => 'abc')
      ds.should_receive(:model=).with(subject)

      subject.configure_datastream(ds)
    end

    it "should run a Proc" do
      ds = mock(:dsid => 'abc')
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
      subject.inner_object.should_receive(:datastream_object_for).with('dsid', {})
      subject.datastream_from_spec({}, 'dsid')
    end
  end

  describe "#load_datastreams" do
    it "should load and configure persisted datastreams and should add any datastreams left over in the ds specs" do
      pending
    end
  end

  describe "#add_datastream" do
    it "should add the datastream to the object" do
      ds = mock(:dsid => 'Abc')
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
      ds1 = mock(:metadata? => true)
      ds2 = mock(:metadata? => true)
      ds3 = mock(:metadata? => true)
      relsextds = ActiveFedora::RelsExtDatastream.new
      file_ds = mock(:metadata? => false)
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
      subject.stub(:datastreams => {'FOO56' => mock()})
      subject.generate_dsid('FOO').should == 'FOO57'
    end
  end

  describe "#dc" do
    it "should be the DC datastream" do
      m = mock
      subject.stub(:datastreams => { 'DC' => m})
      subject.dc.should == m
    end
  end


  describe "#relsext" do
    it "should be the RELS-EXT datastream" do
      m = mock
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
      mock_file = mock(:content_type => 'x-application/asdf')
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      ds.mimeType.should == 'x-application/asdf'
    end

    it "should provide a default mime type" do
      mock_file = mock()
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      ds.mimeType.should == 'application/octet-stream'
    end

    it "should use the filename as a default label" do
     mock_file = mock(:path => '/asdf/fdsa')
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
