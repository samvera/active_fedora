require 'spec_helper'

describe ActiveFedora::AttachedFiles do
  describe "#contains" do
    before do
      class FooHistory < ActiveFedora::Base
         contains 'child'
      end
    end
    after do
      Object.send(:remove_const, :FooHistory)
    end

    context "when the object exists" do
      let!(:o) { FooHistory.create }
      before do
        o.child.content = "HMMM"
        o.save
      end

      it "should not need to do a head on the children" do
        f = FooHistory.find(o.id)
        expect(f.ldp_source.client).not_to receive(:head)
        f.child.content
      end
    end
  end
  describe "serializing datastreams" do
    before do
      class TestingMetadataSerializing < ActiveFedora::Base
        has_metadata "nokogiri_autocreate_on", autocreate: true, type: ActiveFedora::OmDatastream
        has_metadata "nokogiri_autocreate_off", autocreate: false, type: ActiveFedora::OmDatastream
      end
    end

    after do
      Object.send(:remove_const, :TestingMetadataSerializing)
    end

    subject { TestingMetadataSerializing.new }

    it "should work" do
      subject.save(:validate => false)
      expect(subject.nokogiri_autocreate_on).to_not be_new_record
      expect(subject.nokogiri_autocreate_off).to be_new_record
    end
  end

  describe "#has_file_datastream" do
    before do
      class HasFile < ActiveFedora::Base
        has_file_datastream "file_ds"
        has_file_datastream "file_ds2", autocreate: false
      end
    end

    after do
      has_file.delete
      Object.send(:remove_const, :HasFile)
    end

    let(:has_file) { HasFile.create("test:ds_versionable_has_file") }

    it "should create datastreams from the spec on new objects" do
      has_file.file_ds.content = "blah blah blah"
      expect(has_file.file_ds).to be_changed
      expect(has_file.file_ds2).to_not be_changed # no autocreate
      expect(has_file.file_ds2).to be_new_record
      has_file.save
      has_file.reload
      expect(has_file.file_ds).to_not be_changed
      expect(has_file.file_ds2).to_not be_changed # no autocreate
      expect(has_file.file_ds2).to be_new_record
    end
  end

  describe "Datastreams synched together" do
    before do
      class DSTest < ActiveFedora::Base
        def load_attached_files
          super
          unless attached_files.keys.include? :test_ds
            add_file("XXX", path: 'test_ds', mime_type: 'text/html')
          end
        end
      end
    end

    let(:file) { DSTest.create }
    let(:ds) { file.test_ds }

    subject { ds.content }

    after do
      Object.send(:remove_const, :DSTest)
    end

    it { should == 'XXX'}

    context "After updating" do
      before do
        ds.content = "Foobar"
        file.save!
      end

      it "Should update datastream" do
        expect(DSTest.find(file.id).attached_files['test_ds'].content).to eq 'Foobar'
        expect(DSTest.find(file.id).test_ds.content).to eq 'Foobar'
      end
    end

  end

  describe "an instance of ActiveFedora::Base" do
    let(:obj) { ActiveFedora::Base.new }

    describe ".attached_files" do
      subject { obj.attached_files }
      it "should return a Hash of datastreams from fedora" do
        expect(subject).to be_a_kind_of(ActiveFedora::FilesHash)
        expect(subject).to be_empty
      end

      it "should initialize the datastream pointers with @new_object=false" do
        subject.each_value do |ds|
          expect(ds).to_not be_new
        end
      end
    end

    describe ".metadata_streams" do
      let(:mds1) { ActiveFedora::SimpleDatastream.new }
      let(:mds2) { ActiveFedora::QualifiedDublinCoreDatastream.new }
      let(:fds) { ActiveFedora::File.new }
      before do
        fds = ActiveFedora::File.new
        obj.attach_file(mds1, 'md1')
        obj.attach_file(mds2, 'qdc')
        obj.attach_file(fds, 'fds')
      end

      it "should return all of the datastreams from the object that are kinds of OmDatastream " do
        expect(obj.metadata_streams).to match_array [mds1, mds2]
      end
    end

    describe '#add_file' do
      before do
        f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
        obj.add_file(f, mime_type: "image/jpeg")
        obj.save
      end

      it "should set the correct mime_type if :mime_type is passed in and path does not contain correct extension" do
        expect(obj.reload.attached_files["DS1"].mime_type).to eq "image/jpeg"
      end
    end

    describe '.attach_file' do
      let(:ds) { ActiveFedora::File.new }

      it "should be able to add datastreams" do
        expect(obj.attach_file(ds, 'DS1')).to eq 'DS1'
      end

      it "adding and saving should add the datastream to the datastreams array" do
        ds.content = fixture('dino.jpg').read
        expect(obj.attached_files).to_not have_key(:DS1)
        obj.attach_file(ds, 'DS1')
        obj.save
        expect(obj.attached_files).to have_key(:DS1)
      end

    end

    describe "retrieving datastream content" do
      let(:obj) { ActiveFedora::Base.create }
      after { obj.destroy }

      let(:ds) { ActiveFedora::File.new(obj.uri+'/DS1').tap {|ds| ds.content = "foo"; ds.save } }

      it "should retrieve blobs that match the saved blobs" do
        obj.attach_file(ds, 'DS1')
        expect(obj.reload.attached_files["DS1"].content).to eq "foo"
      end
    end
  end
end
