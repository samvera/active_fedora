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
      expect(FooHistory.ds_specs).to have_key('dsid')
    end

    it "should have reasonable defaults" do
      expect(FooHistory.ds_specs['dsid']).to include(:autocreate => false)
    end

    it "should let you override defaults" do
      expect(FooHistory.ds_specs['complex_ds']).to include(:versionable => true, :autocreate => true, :type => 'Z', :label => 'My Label', :control_group => 'Z')
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
       allow(subject).to receive_messages(:datastreams => { :m1 => m1, :m2 => m2})
       subject.serialize_datastreams
    end
  end

  describe "#add_disseminator_location_to_datastreams" do
    it "should infer dsLocations for E datastreams without hitting Fedora" do
      
      mock_specs = {'e' => { :disseminator => 'xyz' }}
      mock_ds = double(:controlGroup => 'E')
      allow(ActiveFedora::Base).to receive_messages(:ds_specs => mock_specs)
      allow(ActiveFedora).to receive_messages(:config_for_environment => { :url => 'http://localhost'})
      allow(subject).to receive_messages(:pid => 'test:1', :datastreams => {'e' => mock_ds})
      expect(mock_ds).to receive(:dsLocation=).with("http://localhost/objects/test:1/methods/xyz")
      subject.add_disseminator_location_to_datastreams
    end
  end

  describe ".name_for_dsid" do
    it "should use the name" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'abc')).to eq('abc')
    end

    it "should use the name" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'ARCHIVAL_XML')).to eq('ARCHIVAL_XML')
    end

    it "should use the name" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'descMetadata')).to eq('descMetadata')
    end

    it "should hash-erize underscores" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'a-b')).to eq('a_b')
    end
  end
 
  describe "#datastreams" do
    it "should return the datastream hash proxy" do
      allow(subject).to receive(:load_datastreams)
      expect(subject.datastreams).to be_a_kind_of(ActiveFedora::DatastreamHash)
    end
    
    it "should round-trip to/from YAML" do
      expect(YAML.load(subject.datastreams.to_yaml).inspect).to eq(subject.datastreams.inspect)
    end
  end

  describe "#configure_datastream" do
    it "should look up the ds_spec" do
      mock_dsspec = { :type => nil }
      allow(subject).to receive_messages(:ds_specs => {'abc' => mock_dsspec})
      subject.configure_datastream(double(:dsid => 'abc'))
    end

    it "should be ok if there is no ds spec" do
      mock_dsspec = double()
      allow(subject).to receive_messages(:ds_specs => {})
      subject.configure_datastream(double(:dsid => 'abc'))
    end

    it "should configure RelsExtDatastream" do
      mock_dsspec = { :type => ActiveFedora::RelsExtDatastream }
      allow(subject).to receive_messages(:ds_specs => {'abc' => mock_dsspec})

      ds = double(:dsid => 'abc')
      expect(ds).to receive(:model=).with(subject)

      subject.configure_datastream(ds)
    end

    it "should run a Proc" do
      ds = double(:dsid => 'abc')
      @count = 0
      mock_dsspec = { :block => lambda { |x| @count += 1 } }
      allow(subject).to receive_messages(:ds_specs => {'abc' => mock_dsspec})


      expect {
      subject.configure_datastream(ds)
      }.to change { @count }.by(1)
    end
  end

  describe "#datastream_from_spec" do
    it "should fetch the rubydora datastream" do
      expect(subject.inner_object).to receive(:datastream_object_for).with('dsid', {}, {})
      subject.datastream_from_spec({}, 'dsid')
    end
  end

  describe "#add_datastream" do
    it "should add the datastream to the object" do
      ds = double(:dsid => 'Abc')
      subject.add_datastream(ds)
      expect(subject.datastreams['Abc']).to eq(ds)
    end

    it "should mint a dsid" do
      ds = ActiveFedora::Datastream.new(subject.inner_object)
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
      allow(subject).to receive_messages(:datastreams => {:a => ds1, :b => ds2, :c => ds3, :d => relsextds, :e => file_ds})
      expect(subject.metadata_streams).to include(ds1, ds2, ds3)
      expect(subject.metadata_streams).not_to include(relsextds)
      expect(subject.metadata_streams).not_to include(file_ds)
    end
  end

  describe "#relsext" do
    it "should be the RELS-EXT datastream" do
      m = double
      allow(subject).to receive_messages(:datastreams => { 'RELS-EXT' => m})
      expect(subject.rels_ext).to eq(m)
    end

    it "should make one up otherwise" do
      allow(subject).to receive_messages(:datastreams => {})

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

    it "should not set content for controlGroup 'E'" do
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {controlGroup: 'E'})
      expect(ds.content).to be_nil
    end

    it "should not set content for controlGroup 'R'" do
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {controlGroup: 'R'})
      expect(ds.content).to be_nil
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
