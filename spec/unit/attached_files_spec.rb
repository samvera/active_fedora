require 'spec_helper'

describe ActiveFedora::AttachedFiles do
  subject { ActiveFedora::Base.new }
  describe "contains" do
    before do
      class FooHistory < ActiveFedora::Base
         contains 'dsid', class_name: 'ActiveFedora::SimpleDatastream'
         contains 'complex_ds', autocreate: true, class_name: 'Z'
         contains 'thumbnail'
      end
    end
    after do
      Object.send(:remove_const, :FooHistory)
    end

    it "should have a child_resource_reflection" do
      expect(FooHistory.child_resource_reflections).to have_key(:dsid)
      expect(FooHistory.child_resource_reflections).to have_key(:thumbnail)
    end

    it "should let you override defaults" do
      expect(FooHistory.child_resource_reflections[:complex_ds].options).to include(autocreate: true)
      expect(FooHistory.child_resource_reflections[:complex_ds].class_name).to eq 'Z'
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
      expect(FooHistory.child_resource_reflections).to have_key(:dsid)
    end

    it "should have reasonable defaults" do
      expect(FooHistory.child_resource_reflections[:dsid].options).to include(class_name: 'ActiveFedora::SimpleDatastream')
    end

    it "should let you override defaults" do
      expect(FooHistory.child_resource_reflections[:complex_ds].options).to include(autocreate: true)
      expect(FooHistory.child_resource_reflections[:complex_ds].class_name).to eq 'Z'
    end

    it "should raise an error if you don't give a type" do
      expect{ FooHistory.has_metadata "bob" }.to raise_error ArgumentError,
        "You must provide a :type property for the datastream 'bob'"
    end

    it "should raise an error if you don't give a dsid" do
      expect{ FooHistory.has_metadata type: ActiveFedora::SimpleDatastream }.to raise_error ArgumentError,
        "You must provide a name (dsid) for the datastream"
    end

    describe "creates accessors" do
      subject { FooHistory.new }
      it "should exist on the instance" do
        expect(subject.dsid).to eq subject.attached_files['dsid']
      end
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
      expect(FooHistory.child_resource_reflections[:dsid].klass).to eq ActiveFedora::File
      expect(FooHistory.child_resource_reflections[:another].klass).to eq ActiveFedora::File
    end
  end

  describe "#add_file" do
    before do
      class Bar < ActiveFedora::File; end

      class FooHistory < ActiveFedora::Base
         contains :content, class_name: 'Bar'
      end
    end

    after do
      Object.send(:remove_const, :Bar)
      Object.send(:remove_const, :FooHistory)
    end
    let(:container) { FooHistory.new }

    describe "#add_file_datastream" do
      context "a reflection matches the :dsid property" do
        it "should build the reflection" do
          expect(Deprecation).to receive(:warn)
          container.add_file_datastream('blah', path: 'content')
          expect(container.content).to be_instance_of Bar
          expect(container.content.content).to eq 'blah'
        end
      end
    end
    context "with the deprecated :dsid property" do
      it "should build the reflection" do
        expect(Deprecation).to receive(:warn)
        container.add_file('blah', dsid: 'content')
        expect(container.content).to be_instance_of Bar
        expect(container.content.content).to eq 'blah'
      end
    end
    context "a reflection matches the :path property" do
      it "should build the reflection" do
        container.add_file('blah', path: 'content')
        expect(container.content).to be_instance_of Bar
        expect(container.content.content).to eq 'blah'
      end
    end

    context "the deprecated 3 args erasure" do
      it "should build the reflection" do
        expect(Deprecation).to receive(:warn)
        container.add_file('blah', 'content', 'name.png')
        expect(container.content).to be_instance_of Bar
        expect(container.content.content).to eq 'blah'
      end
    end

    context "the deprecated 4 args erasure" do
      it "should build the reflection" do
        expect(Deprecation).to receive(:warn)
        container.add_file('blah', 'content', 'name.png', 'image/png')
        expect(container.content).to be_instance_of Bar
        expect(container.content.content).to eq 'blah'
      end
    end

    context "no reflection matches the :path property" do
      it "should create a singleton reflection and build it" do
        container.add_file('blah', path: 'fizz')
        expect(container.fizz).to be_instance_of ActiveFedora::File
        expect(container.fizz.content).to eq 'blah'
      end
    end
  end

  describe "#serialize_attached_files" do
    it "should touch each file" do
      m1 = double()
      m2 = double()

      expect(m1).to receive(:serialize!)
      expect(m2).to receive(:serialize!)
      allow(subject).to receive(:attached_files).and_return(:m1 => m1, :m2 => m2)
      subject.serialize_attached_files
    end
  end

  describe "#accessor_name" do
    it "should use the name" do
      expect(subject.send(:accessor_name, 'abc')).to eq 'abc'
    end

    it "should use the name" do
      expect(subject.send(:accessor_name, 'ARCHIVAL_XML')).to eq 'ARCHIVAL_XML'
    end

    it "should use the name" do
      expect(subject.send(:accessor_name, 'descMetadata')).to eq 'descMetadata'
    end

    it "should hash-erize underscores" do
      expect(subject.send(:accessor_name, 'a-b')).to eq 'a_b'
    end
  end

  describe "#attached_files" do
    it "should return the datastream hash proxy" do
      allow(subject).to receive(:load_datastreams)
      expect(subject.attached_files).to be_a_kind_of(ActiveFedora::FilesHash)
    end
  end

  describe "#attach_file" do
    let(:dsid) { 'Abc' }
    let(:file) { ActiveFedora::File.new }
    before do
      subject.attach_file(file, dsid)
    end

    it "should add the datastream to the object" do
      expect(subject.attached_files['Abc']).to eq file
    end

    describe "dynamic accessors" do
      context "when the file is named with dash" do
        let(:dsid) { 'eac-cpf' }
        it "should convert dashes to underscores" do
          expect(subject.eac_cpf).to eq file
        end
      end

      context "when the file is named with underscore" do
        let(:dsid) { 'foo_bar' }
        it "should preserve the underscore" do
          expect(subject.foo_bar).to eq file
        end
      end
    end
  end

  describe "#metadata_streams" do
    it "should only be metadata datastreams" do
      ds1 = double(:metadata? => true)
      ds2 = double(:metadata? => true)
      ds3 = double(:metadata? => true)
      file_ds = double(:metadata? => false)
      allow(subject).to receive(:attached_files).and_return(:a => ds1, :b => ds2, :c => ds3, :e => file_ds)
      expect(subject.metadata_streams).to include(ds1, ds2, ds3)
      expect(subject.metadata_streams).to_not include(file_ds)
    end
  end
end
