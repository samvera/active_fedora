require 'spec_helper'

describe ActiveFedora::AttachedFiles do
  describe "#has_subresource" do
    before do
      class FooHistory < ActiveFedora::Base
        has_subresource 'child'
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

      it "does not need to do a head on the children" do
        f = FooHistory.find(o.id)
        expect(f.ldp_source.client).not_to receive(:head)
        f.child.content
      end
    end
  end

  describe "Datastreams synched together" do
    before do
      class DSTest < ActiveFedora::Base
        def load_attached_files
          super
          return if attached_files.keys.include? :test_ds
          add_file("XXX", path: 'test_ds', mime_type: 'text/html')
        end
      end
    end

    subject { ds.content }
    let(:file) { DSTest.create }
    let(:ds) { file.test_ds }

    after do
      Object.send(:remove_const, :DSTest)
    end

    it { is_expected.to eq('XXX') }

    context "After updating" do
      before do
        ds.content = "Foobar"
        file.save!
      end

      it "updates datastream" do
        expect(DSTest.find(file.id).attached_files['test_ds'].content).to eq 'Foobar'
        expect(DSTest.find(file.id).test_ds.content).to eq 'Foobar'
      end
    end
  end

  describe "an instance of ActiveFedora::Base" do
    let(:obj) { ActiveFedora::Base.new }

    describe ".attached_files" do
      subject(:attached_files) { obj.attached_files }
      it "returns a Hash of datastreams from fedora" do
        expect(attached_files).to be_a_kind_of(ActiveFedora::FilesHash)
        expect(attached_files).to be_empty
      end

      it "initializes the datastream pointers with @new_object=false" do
        attached_files.each_value do |ds|
          expect(ds).to_not be_new
        end
      end
    end

    describe ".metadata_streams" do
      before do
        class Metadata < ActiveFedora::File
          def metadata?
            true
          end
        end

        obj.attach_file(mds1, 'md1')
        obj.attach_file(mds2, 'qdc')
        obj.attach_file(fds, 'fds')
      end

      let(:mds1) { Metadata.new }
      let(:mds2) { Metadata.new }
      let(:fds) { ActiveFedora::File.new }

      after do
        Object.send(:remove_const, :Metadata)
      end

      it "returns all of the datastreams from the object that are kinds of OmDatastream" do
        expect(obj.metadata_streams).to match_array [mds1, mds2]
      end
    end

    describe '#add_file' do
      before do
        f = File.new(File.join(File.dirname(__FILE__), "../fixtures/dino_jpg_no_file_ext"))
        obj.add_file(f, mime_type: "image/jpeg")
        obj.save
      end

      it "sets the correct mime_type if :mime_type is passed in and path does not contain correct extension" do
        expect(obj.reload.attached_files["DS1"].mime_type).to eq "image/jpeg"
      end
    end

    describe '.attach_file' do
      let(:ds) { ActiveFedora::File.new }

      it "is able to add datastreams" do
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

      let(:ds) { ActiveFedora::File.new(obj.uri + '/DS1') { |ds| ds.content = "foo"; ds.save } }

      it "retrieves blobs that match the saved blobs" do
        obj.attach_file(ds, 'DS1')
        expect(obj.reload.attached_files["DS1"].content).to eq "foo"
      end
    end
  end
end
