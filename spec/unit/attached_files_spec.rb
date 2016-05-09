require 'spec_helper'

describe ActiveFedora::AttachedFiles do
  subject { ActiveFedora::Base.new }
  describe "has_subresource" do
    before do
      class Z < ActiveFedora::File
      end
      class FooHistory < ActiveFedora::Base
        has_subresource 'dsid', class_name: 'ActiveFedora::QualifiedDublinCoreDatastream'
        has_subresource 'complex_ds', autocreate: true, class_name: 'Z'
        has_subresource 'thumbnail'
        has_subresource 'child_resource', class_name: 'ActiveFedora::Base'
      end
    end
    after do
      Object.send(:remove_const, :Z)
      Object.send(:remove_const, :FooHistory)
    end

    it "has a child_resource_reflection" do
      expect(FooHistory.child_resource_reflections).to have_key(:dsid)
      expect(FooHistory.child_resource_reflections).to have_key(:thumbnail)
      expect(FooHistory.child_resource_reflections).not_to have_key(:child_resource)
    end

    it "lets you override defaults" do
      expect(FooHistory.child_resource_reflections[:complex_ds].options).to include(autocreate: true)
      expect(FooHistory.child_resource_reflections[:complex_ds].class_name).to eq 'Z'
    end

    it "raises an error if you don't give a dsid" do
      expect { FooHistory.has_subresource nil, type: ActiveFedora::QualifiedDublinCoreDatastream }.to raise_error ArgumentError,
                                                                                                                  "You must provide a path name (f.k.a. dsid) for the resource"
    end
  end

  describe "#add_file" do
    before do
      class Bar < ActiveFedora::File; end

      class FooHistory < ActiveFedora::Base
        has_subresource :content, class_name: 'Bar'
      end
    end

    after do
      Object.send(:remove_const, :Bar)
      Object.send(:remove_const, :FooHistory)
    end
    let(:container) { FooHistory.new }

    context "a reflection matches the :path property" do
      it "builds the reflection" do
        container.add_file('blah', path: 'content')
        expect(container.content).to be_instance_of Bar
        expect(container.content.content).to eq 'blah'
      end
    end

    context "no reflection matches the :path property" do
      it "creates a singleton reflection and build it" do
        container.add_file('blah', path: 'fizz')
        expect(container.fizz).to be_instance_of ActiveFedora::File
        expect(container.fizz.content).to eq 'blah'
      end
    end
  end

  describe "#declared_attached_files" do
    subject { obj.declared_attached_files }

    context "when there are undeclared attached files" do
      let(:obj) { ActiveFedora::Base.create }
      let(:file) { ActiveFedora::File.new }
      before do
        obj.attach_file(file, 'Abc')
      end
      it { is_expected.to be_empty }
    end

    context "when there are declared attached files" do
      before do
        class FooHistory < ActiveFedora::Base
          has_subresource 'thumbnail'
        end
      end

      after do
        Object.send(:remove_const, :FooHistory)
      end
      let(:obj) { FooHistory.new }
      it { is_expected.to have_key :thumbnail }
    end
  end

  describe "#serialize_attached_files" do
    it "touches each file" do
      m1 = double
      m2 = double

      expect(m1).to receive(:serialize!)
      expect(m2).to receive(:serialize!)
      allow(subject).to receive(:declared_attached_files).and_return(m1: m1, m2: m2)
      subject.serialize_attached_files
    end
  end

  describe "#accessor_name" do
    it "uses the name" do
      expect(subject.send(:accessor_name, 'abc')).to eq 'abc'
    end

    it "uses the name" do
      expect(subject.send(:accessor_name, 'ARCHIVAL_XML')).to eq 'ARCHIVAL_XML'
    end

    it "uses the name" do
      expect(subject.send(:accessor_name, 'descMetadata')).to eq 'descMetadata'
    end

    it "hash-erizes underscores" do
      expect(subject.send(:accessor_name, 'a-b')).to eq 'a_b'
    end
  end

  describe "#attached_files" do
    it "returns the datastream hash proxy" do
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

    it "adds the datastream to the object" do
      expect(subject.attached_files['Abc']).to eq file
    end

    describe "dynamic accessors" do
      context "when the file is named with dash" do
        let(:dsid) { 'eac-cpf' }
        it "converts dashes to underscores" do
          expect(subject.eac_cpf).to eq file
        end
      end

      context "when the file is named with underscore" do
        let(:dsid) { 'foo_bar' }
        it "preserves the underscore" do
          expect(subject.foo_bar).to eq file
        end
      end
    end
  end

  describe "#metadata_streams" do
    it "only is metadata datastreams" do
      ds1 = double(metadata?: true)
      ds2 = double(metadata?: true)
      ds3 = double(metadata?: true)
      file_ds = double(metadata?: false)
      allow(subject).to receive(:attached_files).and_return(a: ds1, b: ds2, c: ds3, e: file_ds)
      expect(subject.metadata_streams).to include(ds1, ds2, ds3)
      expect(subject.metadata_streams).to_not include(file_ds)
    end
  end
end
