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

    subject(:history) { obj }
    let(:obj) { BarHistory4.new(title: ['test1'], id: 'test:123') }

    describe "#attribute_names" do
      context "on an instance" do
        it "lists the attributes" do
          expect(history.attribute_names).to eq ["title", "abstract"]
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
        expect(history.inspect).to eq "#<BarHistory4 id: \"test:123\", title: [\"test1\"], abstract: nil>"
      end

      describe "with no attributes" do
        subject(:object) { described_class.new }
        it "shows a id" do
          expect(object.inspect).to eq "#<ActiveFedora::Base id: nil>"
        end
      end

      describe "with relationships" do
        before do
          class BarHistory2 < BarHistory4
            belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent, class_name: 'BarHistory4'
          end
          history.library = library
        end

        subject(:history) { BarHistory2.new }
        let(:library) { BarHistory4.create }

        after do
          Object.send(:remove_const, :BarHistory2)
        end

        it "shows the library_id" do
          expect(history.inspect).to eq "#<BarHistory2 id: nil, title: [], abstract: nil, library_id: \"#{library.id}\">"
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
          expect(history.title).to eq ['test1']
        end
      end

      context "using hash accessors" do
        context "on single value fields" do
          it "has a default value" do
            expect(history[:abstract]).to be_nil
          end

          context "when there are two assertions for the predicate" do
            before do
              history.resource[:abstract] = ['foo', 'bar']
            end
            it "raises an error if just returning the first value would cause data loss" do
              expect { history[:abstract] }.to raise_error ActiveFedora::ConstraintError, "Expected \"abstract\" of test:123 to have 0-1 statements, but there are 2"
            end
          end
        end

        context "multiple values" do
          it "returns values" do
            expect(history[:title]).to eq ['test1']
          end
        end

        context "on Fedora attributes" do
          it "return values" do
            expect(history[:type]).to be_empty
            expect(history[:rdf_label]).to contain_exactly("test1")
          end
        end
      end
    end

    describe 'change tracking' do
      it "is able to track change status" do
        expect {
          history.abstract = "Moo"
        }.to change { history.abstract_changed? }.from(false).to(true)
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
        expect { history.title = "Quack" }.to raise_error ArgumentError
        expect { history.title = ["Quack"] }.not_to raise_error
        expect { history.title = nil }.not_to raise_error
      end

      it "does not allow an enumerable to a unique attribute writer" do
        expect { history.abstract = "Low" }.not_to raise_error
        expect { history.abstract = ["Low"]
        }.to raise_error ArgumentError, "You attempted to set the property `abstract' of test:123 to an enumerable value. However, this property is declared as singular."
        expect { history.abstract = nil }.not_to raise_error
      end
    end
  end
end
