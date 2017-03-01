require 'spec_helper'

describe ActiveFedora::AttachedFiles do
  subject(:af_base) { ActiveFedora::Base.new }
  describe "has_subresource" do
    before do
      class Sample1 < ActiveFedora::File
      end
      class Sample2 < ActiveFedora::File
      end
      class FooHistory < ActiveFedora::Base
        has_subresource 'dsid', class_name: 'Sample2'
        has_subresource 'complex_ds', autocreate: true, class_name: 'Sample1'
        has_subresource 'thumbnail'
        has_subresource 'child_resource', class_name: 'ActiveFedora::Base'
      end
    end
    after do
      Object.send(:remove_const, :Sample1)
      Object.send(:remove_const, :Sample2)
      Object.send(:remove_const, :FooHistory)
    end

    it "has a child_resource_reflection" do
      expect(FooHistory.child_resource_reflections).to have_key(:dsid)
      expect(FooHistory.child_resource_reflections).to have_key(:thumbnail)
      expect(FooHistory.child_resource_reflections).not_to have_key(:child_resource)
    end

    it "lets you override defaults" do
      expect(FooHistory.child_resource_reflections[:complex_ds].options).to include(autocreate: true)
      expect(FooHistory.child_resource_reflections[:complex_ds].class_name).to eq 'Sample1'
    end

    it "raises an error if you don't give a dsid" do
      expect { FooHistory.has_subresource nil, type: Sample2 }.to raise_error ArgumentError,
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
      m1 = instance_double(ActiveFedora::File)
      m2 = instance_double(ActiveFedora::File)

      expect(m1).to receive(:serialize!)
      expect(m2).to receive(:serialize!)
      allow(af_base).to receive(:declared_attached_files).and_return(m1: m1, m2: m2)
      af_base.serialize_attached_files
    end
  end

  describe "#accessor_name" do
    subject { af_base.send(:accessor_name, value) }
    context "with lowercase" do
      let(:value) { 'abc' }
      it { is_expected.to eq 'abc' }
    end

    context "with uppercase" do
      let(:value) { 'ARCHIVAL_XML' }
      it { is_expected.to eq 'ARCHIVAL_XML' }
    end

    context "with camelcase" do
      let(:value) { 'descMetadata' }
      it { is_expected.to eq 'descMetadata' }
    end

    context "with dashes" do
      let(:value) { 'a-b' }
      it { is_expected.to eq 'a_b' }
    end
  end

  describe "#attached_files" do
    it "returns the datastream hash proxy" do
      allow(af_base).to receive(:load_datastreams)
      expect(af_base.attached_files).to be_a_kind_of(ActiveFedora::FilesHash)
    end
  end

  describe "#attach_file" do
    let(:file) { ActiveFedora::File.new }

    it "does not call save on the file" do
      expect(file).to receive(:save).never
      af_base.attach_file(file, 'part1')
    end

    it "adds the file to the attached_files hash" do
      expect {
        af_base.attach_file(file, 'part1')
      }.to change { af_base.attached_files.key?(:part1) }.from(false).to(true)
    end

    context "after attaching the file" do
      let(:dsid) { 'Abc' }
      before do
        af_base.attach_file(file, dsid)
      end

      it "adds the datastream to the object" do
        expect(af_base.attached_files['Abc']).to eq file
      end

      describe "dynamic accessors" do
        context "when the file is named with dash" do
          let(:dsid) { 'eac-cpf' }
          it "converts dashes to underscores" do
            expect(af_base.eac_cpf).to eq file
          end
        end

        context "when the file is named with underscore" do
          let(:dsid) { 'foo_bar' }
          it "preserves the underscore" do
            expect(af_base.foo_bar).to eq file
          end
        end
      end
    end
  end

  describe "#metadata_streams" do
    it "only is metadata datastreams" do
      ds1 = instance_double(ActiveFedora::File, metadata?: true)
      ds2 = instance_double(ActiveFedora::File, metadata?: true)
      ds3 = instance_double(ActiveFedora::File, metadata?: true)
      file_ds = instance_double(ActiveFedora::File, metadata?: false)
      allow(af_base).to receive(:attached_files).and_return(a: ds1, b: ds2, c: ds3, e: file_ds)
      expect(af_base.metadata_streams).to include(ds1, ds2, ds3)
      expect(af_base.metadata_streams).to_not include(file_ds)
    end
  end

  context "When the resource is using idiomatic basic containment" do
    before do
      class Sample1 < ActiveFedora::Base
        is_a_container
      end
    end
    after do
      Object.send(:remove_const, :Sample1)
    end

    before do
      child = obj.contains.build
      child.content = "Stuff"
      child.save!
    end
    let(:obj) { Sample1.create! }
    let(:obj2) { Sample1.find(obj.id) }

    it "doesn't conflate attached_file and contains" do
      expect(obj2.attached_files.keys).to be_empty
    end
  end
end
