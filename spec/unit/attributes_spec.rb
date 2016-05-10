require 'spec_helper'

describe ActiveFedora::Base do
  context "when properties are defined on an object" do
    before :all do
      class BarHistory4 < ActiveFedora::Base
        property :title, predicate: ::RDF::Vocab::DC.title do |index|
          index.as :symbol
        end
        property :abstract, predicate: ::RDF::Vocab::DC.abstract, multiple: false
      end
    end

    after :all do
      Object.send(:remove_const, :BarHistory4)
    end

    let(:obj) { BarHistory4.new(title: ['test1']) }
    subject { obj }

    describe "#attribute_names" do
      context "on an instance" do
        it "lists the attributes" do
          expect(subject.attribute_names).to eq ["title", "abstract"]
        end
      end

      context "on a class" do
        it "lists the attributes" do
          expect(BarHistory4.attribute_names).to eq ["title", "abstract"]
        end
      end
    end

    describe "#inspect" do
      it "shows the attributes" do
        expect(subject.inspect).to eq "#<BarHistory4 id: nil, title: [\"test1\"], abstract: nil>"
      end

      describe "with a id" do
        before { allow(subject).to receive(:id).and_return('test:123') }

        it "shows a id" do
          expect(subject.inspect).to eq "#<BarHistory4 id: \"test:123\", title: [\"test1\"], abstract: nil>"
        end
      end

      describe "with no attributes" do
        subject { described_class.new }
        it "shows a id" do
          expect(subject.inspect).to eq "#<ActiveFedora::Base id: nil>"
        end
      end

      describe "with relationships" do
        before do
          class BarHistory2 < BarHistory4
            belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent, class_name: 'BarHistory4'
          end
          subject.library = library
        end

        let(:library) { BarHistory4.create }
        subject { BarHistory2.new }

        after do
          Object.send(:remove_const, :BarHistory2)
        end

        it "shows the library_id" do
          expect(subject.inspect).to eq "#<BarHistory2 id: nil, title: [], abstract: nil, library_id: \"#{library.id}\">"
        end
      end
    end

    describe "#unique?" do
      it "reveals the unique properties" do
        expect(BarHistory4.unique?(:abstract)).to be true
        expect(BarHistory4.unique?(:title)).to be false
      end
    end

    describe "accessing attributes" do
      context "using generated methods" do
        it "returns values" do
          expect(subject.title).to eq ['test1']
        end
      end

      context "using hash accessors" do
        context "on single value fields" do
          it "has a default value" do
            expect(subject[:abstract]).to be_nil
          end

          context "when there are two assertions for the predicate" do
            before do
              subject.resource[:abstract] = ['foo', 'bar']
            end
            it "raises an error if just returning the first value would cause data loss" do
              expect { subject[:abstract] }.to raise_error ActiveFedora::ConstraintError, "Expected \"abstract\" to have 0-1 statements, but there are 2"
            end
          end
        end

        context "multiple values" do
          it "returns values" do
            expect(subject[:title]).to eq ['test1']
          end
        end

        context "on Fedora attributes" do
          it "return values" do
            expect(subject[:type]).to be_empty
            expect(subject[:rdf_label]).to contain_exactly("test1")
          end
        end
      end
    end

    describe 'change tracking' do
      it "is able to track change status" do
        expect {
          subject.abstract = "Moo"
        }.to change { subject.abstract_changed? }.from(false).to(true)
      end
    end

    describe "indexing" do
      let(:solr_doc) { obj.to_solr }

      it "indexs the attributes" do
        expect(solr_doc['title_ssim']).to eq ['test1']
      end
    end

    describe "when an object of the wrong cardinality is set" do
      it "does not allow passing a string to a multiple property writer" do
        expect { subject.title = "Quack" }.to raise_error ArgumentError
        expect { subject.title = ["Quack"] }.not_to raise_error
        expect { subject.title = nil }.not_to raise_error
      end

      it "does not allow an enumerable to a unique attribute writer" do
        expect { subject.abstract = "Low" }.not_to raise_error
        expect { subject.abstract = ["Low"]
        }.to raise_error ArgumentError, "You attempted to set the property `abstract' to an enumerable value. However, this property is declared as singular."
        expect { subject.abstract = nil }.not_to raise_error
      end
    end
  end
end
