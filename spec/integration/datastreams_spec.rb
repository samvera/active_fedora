require 'spec_helper'

describe ActiveFedora::Datastreams do
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
        def load_datastreams
          super
          unless self.datastreams.keys.include? 'test_ds'
            add_file_datastream("XXX", dsid: 'test_ds', mime_type: 'text/html')
          end
        end
      end
    end

    let(:file) { DSTest.create }
    let(:ds) { file.test_ds }

    subject { ds.content }

    after do
      file.destroy
      Object.send(:remove_const, :DSTest)
    end

    it { should == 'XXX'}

    context "After updating" do
      before do
        ds.content = "Foobar"
        file.save!
      end

      it "Should update datastream" do
        expect(DSTest.find(file.pid).datastreams['test_ds'].content).to eq 'Foobar'
        expect(DSTest.find(file.pid).test_ds.content).to eq 'Foobar'
      end
    end

  end

  describe "an instance of ActiveFedora::Base" do
    let(:obj) { ActiveFedora::Base.new }
    describe ".datastreams" do
      subject {obj.datastreams}
      it "should return a Hash of datastreams from fedora" do
        expect(subject).to be_a_kind_of(ActiveFedora::DatastreamHash)
        expect(subject).to be_empty
      end

      it "should initialize the datastream pointers with @new_object=false" do
        subject.each_value do |ds|
          expect(ds).to_not be_new
        end
      end
    end

    describe ".metadata_streams" do
      let(:mds1) { ActiveFedora::SimpleDatastream.new(obj, "md1") }
      let(:mds2) { ActiveFedora::QualifiedDublinCoreDatastream.new(obj, "qdc") }
      before do
        fds = ActiveFedora::Datastream.new(obj, "fds")
        obj.add_datastream(mds1)
        obj.add_datastream(mds2)
        obj.add_datastream(fds)
      end

      it "should return all of the datastreams from the object that are kinds of OmDatastream " do
        expect(obj.metadata_streams).to match_array [mds1, mds2]
      end
    end

    describe '.add_file_datastream' do
      before do
        f = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext" ))
        obj.add_file_datastream(f, mime_type: "image/jpeg")
        obj.save
      end

      it "should set the correct mime_type if :mime_type is passed in and path does not contain correct extension" do
        expect(obj.reload.datastreams["DS1"].mime_type).to eq "image/jpeg"
      end
    end

    describe '.add_datastream' do
      let(:ds) { ActiveFedora::Datastream.new(obj, 'DS1') }

      it "should be able to add datastreams" do
        expect(obj.add_datastream(ds)).to eq 'DS1'
      end

      it "adding and saving should add the datastream to the datastreams array" do
        ds.content = fixture('dino.jpg').read
        expect(obj.datastreams).to_not have_key("DS1")
        obj.add_datastream(ds)
        obj.save
        expect(obj.datastreams).to have_key("DS1")
      end

    end

    describe "retrieving datastream content" do
      let(:obj) { ActiveFedora::Base.create }
      after { obj.destroy }

      let(:ds) { ActiveFedora::Datastream.new(obj, 'DS1').tap {|ds| ds.content = "foo"; ds.save } }

      it "should retrieve blobs that match the saved blobs" do
        obj.add_datastream(ds)
        expect(obj.reload.datastreams["DS1"].content).to eq "foo"
      end
    end
  end
end
