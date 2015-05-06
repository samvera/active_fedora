require 'spec_helper'

describe "Direct containers" do
  describe "#directly_contains" do
    context "when the class is ActiveFedora::File" do
      before do
        class FooHistory < ActiveFedora::Base
           directly_contains :files, has_member_relation: ::RDF::URI.new("http://example.com/hasFiles")
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end

      let(:file) { o.files.build }
      let(:reloaded) { FooHistory.find(o.id) }

      context "with no files" do
        let(:o) { FooHistory.new }
        subject { o.files }

        it { is_expected.to be_empty }
        it { is_expected.to eq [] }
      end

      context "when the object exists" do
        let(:o) { FooHistory.create }

        before do
          file.content = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.files.first }
          it "has the content" do
            expect(subject.content).to eq 'HMMM'
          end
        end

        describe "#to_a" do
          subject { reloaded.files }
          it "has the content" do
            expect(subject.to_a).to eq [file]
          end
        end

        describe "#append" do
          let(:file2) { o.files.build }
          it "has two files" do
            expect(o.files).to eq [file, file2]
          end

          context "and then saved/reloaded" do
            before do
              file2.content = "Derp"
              o.save!
            end
            it "has two files" do
              expect(reloaded.files).to eq [file, file2]
            end
          end
        end
      end

      context "when the object is new" do
        let(:o) { FooHistory.new }
        let(:file) { o.files.build }

        it "fails" do
          # This is the expected behavior right now. In the future make the uri get assigned by autosave.
          expect { o.files.build }.to raise_error "Can't get uri. Owner isn't saved"
        end
      end
    end

    context "when the class is a subclass of ActiveFedora::File" do
      before do
        class SubFile < ActiveFedora::File; end
        class FooHistory < ActiveFedora::Base
           directly_contains :files, has_member_relation: ::RDF::URI.new("http://example.com/hasFiles"), class_name: 'SubFile'
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
        Object.send(:remove_const, :SubFile)
      end

      let(:o) { FooHistory.create }
      let(:file) { o.files.build }
      let(:reloaded) { FooHistory.find(o.id) }

      describe "#build" do
        subject { file }
        it { is_expected.to be_kind_of SubFile }
      end

      context "when the object exists" do
        before do
          file.content = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.files.first }
          it "has the content" do
            expect(subject.content).to eq 'HMMM'
          end
        end
      end
    end

    context "when using is_member_of_relation" do
      before do
        class FooHistory < ActiveFedora::Base
           directly_contains :files, is_member_of_relation: ::RDF::URI.new("http://example.com/isWithin")
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end

      let(:file) { o.files.build }
      let(:reloaded) { FooHistory.find(o.id) }

      context "with no files" do
        let(:o) { FooHistory.new }
        subject { o.files }

        it { is_expected.to be_empty }
        it { is_expected.to eq [] }
      end

      context "when the object exists" do
        let(:o) { FooHistory.create }

        before do
          file.content = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.files.first }
          it "has the content" do
            expect(subject.content).to eq 'HMMM'
          end
        end
      end
    end
  end
end
