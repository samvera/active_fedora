require 'spec_helper'

describe ActiveFedora::Datastreams do
  subject { ActiveFedora::Base.new }
  describe "contains" do
    before do
      class FooHistory < ActiveFedora::Base
         contains 'dsid', class_name: ActiveFedora::SimpleDatastream
         contains 'complex_ds', autocreate: true, class_name: 'Z'
      end
    end
    after do
      Object.send(:remove_const, :FooHistory)
    end

    it "should have a child_resource_reflection" do
      expect(FooHistory.child_resource_reflections).to have_key('dsid')
    end

    it "should let you override defaults" do
      expect(FooHistory.child_resource_reflections['complex_ds'].options).to include(autocreate: true)
      expect(FooHistory.child_resource_reflections['complex_ds'].class_name).to eq 'Z'
    end

    it "should raise an error if you don't give a dsid" do
      expect{ FooHistory.contains nil, type: ActiveFedora::SimpleDatastream }.to raise_error ArgumentError,
        "You must provide a name (dsid) for the datastream"
    end
  end

  describe '.has_metadata' do
    before do
      @original_behavior = Deprecation.default_deprecation_behavior
      Deprecation.default_deprecation_behavior = :silence
      class FooHistory < ActiveFedora::Base
         has_metadata :name => 'dsid', type: ActiveFedora::SimpleDatastream
         has_metadata 'complex_ds', autocreate: true, type: 'Z'
      end
    end
    after do
      Deprecation.default_deprecation_behavior = @original_behavior
      Object.send(:remove_const, :FooHistory)
    end

    it "should have a child_resource_reflection" do
      expect(FooHistory.child_resource_reflections).to have_key('dsid')
    end

    it "should have reasonable defaults" do
      expect(FooHistory.child_resource_reflections['dsid'].options).to include(class_name: ActiveFedora::SimpleDatastream)
    end

    it "should let you override defaults" do
      expect(FooHistory.child_resource_reflections['complex_ds'].options).to include(autocreate: true)
      expect(FooHistory.child_resource_reflections['complex_ds'].class_name).to eq 'Z'
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
    after do
      Object.send(:remove_const, :FooHistory)
    end

    it "should have reasonable defaults" do
      expect(FooHistory.child_resource_reflections['dsid'].klass).to eq ActiveFedora::Datastream
      expect(FooHistory.child_resource_reflections['another'].klass).to eq ActiveFedora::Datastream
    end
  end

  describe "#serialize_datastreams" do
    it "should touch each datastream" do
      m1 = double()
      m2 = double()

      expect(m1).to receive(:serialize!)
      expect(m2).to receive(:serialize!)
      allow(subject).to receive(:datastreams).and_return(:m1 => m1, :m2 => m2)
      subject.serialize_datastreams
    end
  end

  describe ".name_for_dsid" do
    it "should use the name" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'abc')).to eq 'abc'
    end

    it "should use the name" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'ARCHIVAL_XML')).to eq 'ARCHIVAL_XML'
    end

    it "should use the name" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'descMetadata')).to eq 'descMetadata'
    end

    it "should hash-erize underscores" do
      expect(ActiveFedora::Base.send(:name_for_dsid, 'a-b')).to eq 'a_b'
    end
  end

  describe "#datastreams" do
    it "should return the datastream hash proxy" do
      allow(subject).to receive(:load_datastreams)
      expect(subject.datastreams).to be_a_kind_of(ActiveFedora::DatastreamHash)
    end

    it "should round-trip to/from YAML" do
      expect(YAML.load(subject.datastreams.to_yaml).inspect).to eq subject.datastreams.inspect
    end
  end

  describe "#configure_datastream" do
    it "should run a Proc" do
      ds = double(:dsid => 'abc')
      @count = 0
      reflection = double(options: { block: lambda { |x| @count += 1 } })

      expect {
        subject.configure_datastream(ds, reflection)
      }.to change { @count }.by(1)
    end
  end

  describe "#add_datastream" do
    it "should add the datastream to the object" do
      ds = double(:dsid => 'Abc')
      subject.add_datastream(ds)
      expect(subject.datastreams['Abc']).to eq ds
    end

    it "should mint a dsid" do
      ds = ActiveFedora::Datastream.new(subject)
      expect(subject.add_datastream(ds)).to eq 'DS1'
    end
  end

  describe "#metadata_streams" do
    it "should only be metadata datastreams" do
      ds1 = double(:metadata? => true)
      ds2 = double(:metadata? => true)
      ds3 = double(:metadata? => true)
      file_ds = double(:metadata? => false)
      allow(subject).to receive(:datastreams).and_return(:a => ds1, :b => ds2, :c => ds3, :e => file_ds)
      expect(subject.metadata_streams).to include(ds1, ds2, ds3)
      expect(subject.metadata_streams).to_not include(file_ds)
    end
  end

  describe "#create_datastream" do
    it "should mint a DSID" do
      ds = subject.create_datastream(ActiveFedora::Datastream, nil, {})
      expect(ds.dsid).to eq 'DS1'
    end

    it "should raise an argument error if the supplied dsid is nonsense" do
      expect { subject.create_datastream(ActiveFedora::Datastream, 0) }.to raise_error(ArgumentError)
    end
  end

  describe "#additional_attributes_for_external_and_redirect_control_groups" do
    before(:all) do
      @behavior = ActiveFedora::Datastreams.deprecation_behavior
      ActiveFedora::Datastreams.deprecation_behavior = :silence
    end

    after(:all) do
      ActiveFedora::Datastreams.deprecation_behavior = @behavior
    end

  end
end
