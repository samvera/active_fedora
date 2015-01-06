require 'spec_helper'

describe ActiveFedora::Datastreams do
  subject { ActiveFedora::Base.new }

  describe '.has_metadata' do
    before do
      class FooHistory < ActiveFedora::Base
         has_metadata :name => 'dsid'
         has_metadata 'complex_ds', :versionable => true, :autocreate => true, :type => 'Z', :label => 'My Label', :control_group => 'Z'
      end
    end

    it "should have a ds_specs entry" do
      expect(FooHistory.ds_specs).to have_key('dsid')
    end

    it "should have reasonable defaults" do
      expect(FooHistory.ds_specs['dsid']).to include(:autocreate => false)
    end

    it "should let you override defaults" do
      expect(FooHistory.ds_specs['complex_ds']).to include(:versionable => true, :autocreate => true, :type => 'Z', :label => 'My Label', :control_group => 'Z')
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
      expect(FooHistory.ds_specs['dsid']).to include(:type => ActiveFedora::Datastream, :label => 'File Datastream', :control_group => 'M')
      expect(FooHistory.ds_specs['another']).to include(:type => ActiveFedora::Datastream, :label => 'File Datastream', :control_group => 'M')
    end
  end

  describe "#serialize_datastreams" do
    it "should touch each datastream" do
      m1 = double()
      m2 = double()

      expect(m1).to receive(:serialize!)
      expect(m2).to receive(:serialize!)
       subject.stub(:datastreams => { :m1 => m1, :m2 => m2})
       subject.serialize_datastreams
    end
  end

  describe "#add_disseminator_location_to_datastreams" do
    it "should infer dsLocations for E datastreams without hitting Fedora" do

      mock_specs = {:e => { :disseminator => 'xyz' }}
      mock_ds = double(:controlGroup => 'E')
      ActiveFedora::Base.stub(:ds_specs => mock_specs)
      ActiveFedora.stub(:config_for_environment => { :url => 'http://localhost'})
      subject.stub(:pid => 'test:1', :datastreams => {:e => mock_ds})
      expect(mock_ds).to receive(:dsLocation=).with("http://localhost/objects/test:1/methods/xyz")
      subject.add_disseminator_location_to_datastreams
    end
  end

  describe "#corresponding_datastream_name" do
    before(:each) do
      subject.stub(:datastreams => { 'abc' => double(), 'a_b_c' => double(), 'a-b' => double()})
    end

    it "should use the name, if it exists" do
      expect(subject.corresponding_datastream_name('abc')).to eq('abc')
    end

    it "should hash-erize underscores" do
      expect(subject.corresponding_datastream_name('a_b')).to eq('a-b')
    end

    it "should return nil if nothing matches" do
      expect(subject.corresponding_datastream_name('xyz')).to be_nil
    end
  end

  describe "#datastreams" do
    it "should return the datastream hash proxy" do
      allow(subject).to receive(:load_datastreams)
      expect(subject.datastreams).to be_a_kind_of(ActiveFedora::DatastreamHash)
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
      expect(ds).to receive(:model=).with(subject)

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
      expect(subject.inner_object).to receive(:datastream_object_for).with('dsid', {})
      subject.datastream_from_spec({}, 'dsid')
    end
  end

  describe "#load_datastreams" do
    it "should load and configure persisted datastreams and should add any datastreams left over in the ds specs" do
      skip
    end
  end

  describe "#add_datastream" do
    it "should add the datastream to the object" do
      ds = double(:dsid => 'Abc')
      subject.add_datastream(ds)
      expect(subject.datastreams['Abc']).to eq(ds)
    end

    it "should mint a dsid" do
      ds = ActiveFedora::Datastream.new
      expect(subject.add_datastream(ds)).to eq('DS1')
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
      expect(subject.metadata_streams).to include(ds1, ds2, ds3)
      expect(subject.metadata_streams).not_to include(relsextds)
      expect(subject.metadata_streams).not_to include(file_ds)
    end
  end

  describe "#generate_dsid" do
    it "should create an autoincrementing dsid" do
      expect(subject.generate_dsid('FOO')).to eq('FOO1')
    end

    it "should start from the highest existin dsid" do
      subject.stub(:datastreams => {'FOO56' => double()})
      expect(subject.generate_dsid('FOO')).to eq('FOO57')
    end
  end

  describe "#dc" do
    it "should be the DC datastream" do
      m = double
      subject.stub(:datastreams => { 'DC' => m})
      expect(subject.dc).to eq(m)
    end
  end


  describe "#relsext" do
    it "should be the RELS-EXT datastream" do
      m = double
      subject.stub(:datastreams => { 'RELS-EXT' => m})
      expect(subject.rels_ext).to eq(m)
    end

    it "should make one up otherwise" do
      subject.stub(:datastreams => {})

      expect(subject.rels_ext).to be_a_kind_of(ActiveFedora::RelsExtDatastream)
    end
  end

  describe "#add_file_datastream" do
    # tested elsewhere :/
  end

  describe "#create_datastream" do
    it "should mint a DSID" do
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {})
      expect(ds.dsid).to eq('DS1')
    end

    it "should raise an argument error if the supplied dsid is nonsense" do
      expect { subject.create_datastream(ActiveFedora::Datastream, 0) }.to raise_error(ArgumentError)
    end

    it "should try to get a mime type from the blob" do
      mock_file = double(:content_type => 'x-application/asdf')
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      expect(ds.mimeType).to eq('x-application/asdf')
    end

    it "should provide a default mime type" do
      mock_file = double()
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      expect(ds.mimeType).to eq('application/octet-stream')
    end

    it "should use the filename as a default label" do
     mock_file = double(:path => '/asdf/fdsa')
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {:blob => mock_file})
      expect(ds.dsLabel).to eq('fdsa')
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
