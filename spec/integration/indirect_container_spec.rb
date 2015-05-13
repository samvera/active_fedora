require 'spec_helper'

describe "Indirect containers" do
  before do
    class RelatedObject < ActiveFedora::Base
      property :title, predicate: ::RDF::DC.title, multiple: false
    end
    class Proxy < ActiveFedora::Base
      belongs_to :proxy_for, predicate: ::RDF::URI.new('http://www.openarchives.org/ore/terms/proxyFor'), class_name: 'ActiveFedora::Base'
    end
  end

  after do
    Object.send(:remove_const, :RelatedObject)
    Object.send(:remove_const, :Proxy)
  end

  describe "delete" do 
    before do
      class FooHistory < ActiveFedora::Base
        indirectly_contains :related_objects, 
          has_member_relation: ::RDF::URI.new('http://www.openarchives.org/ore/terms/aggregates'), inserted_content_relation: ::RDF::URI.new('http://www.openarchives.org/ore/terms/proxyFor'), 
          through: 'Proxy', 
          foreign_key: :proxy_for
      end
    end

    it "should delete only one object" do 
      foo = FooHistory.new
      foo.related_objects.build
      file2 = foo.related_objects.build
      foo.save
      expect(foo.related_objects.each.count).to eq(2)
      foo.related_objects.delete(file2)
      expect(foo.related_objects.each.count).to eq 1
      foo = FooHistory.find(foo.id)
      expect(foo.related_objects.each.count).to eq(1)
    end
  end

  describe "#indirectly_contains" do
    context "when the class is implied" do
      before do
        class FooHistory < ActiveFedora::Base
          # TODO inserted_content_relation can look up the predicate at options[:through].constantize.reflect_on_association(options[:foreign_key]).predicate
          indirectly_contains :related_objects, has_member_relation: ::RDF::URI.new('http://www.openarchives.org/ore/terms/aggregates'), inserted_content_relation: ::RDF::URI.new('http://www.openarchives.org/ore/terms/proxyFor'), through: 'Proxy', foreign_key: :proxy_for
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end

      let(:file) { o.related_objects.build }
      let(:reloaded) { FooHistory.find(o.id) }

      context "with no related_objects" do
        let(:o) { FooHistory.new }
        subject { o.related_objects }

        it { is_expected.to be_empty }
        it { is_expected.to eq [] }
      end

      context "when the object exists" do
        let(:o) { FooHistory.create }

        before do
          file.title = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.related_objects.first }
          it "has the content" do
            expect(subject.title).to eq 'HMMM'
          end
        end

        describe "#==" do
          subject { reloaded.related_objects }

          it "delegates to to_a" do
            expect(subject).to eq [file]
          end
        end

        describe "#append" do
          let(:file2) { o.related_objects.build }
          it "has two related_objects" do
            expect(o.related_objects).to eq [file, file2]
          end

          context "and then saved/reloaded" do
            before do
              file2.title = "Derp"
              o.save!
            end
            it "has two related_objects" do
              expect(reloaded.related_objects).to eq [file, file2]
            end
            it "has inbound triples" do
              statement = file.reload.resource.query(predicate: ::RDF::URI.new('http://www.openarchives.org/ore/terms/proxyFor')).to_a.first

              expect(statement.object).to eq file.resource.rdf_subject
            end
          end
        end
        describe "remove" do
          it "should be able to remove" do
            o.related_objects = []
            o.save!

            expect(reloaded.related_objects).to eq []
          end
        end
      end
    end

    context "when the class is provided" do
      before do
        class Different < ActiveFedora::Base
          property :title, predicate: ::RDF::DC.title, multiple: false
        end
        class FooHistory < ActiveFedora::Base
          indirectly_contains :related_objects, has_member_relation: ::RDF::URI.new('http://www.openarchives.org/ore/terms/aggregates'), inserted_content_relation: ::RDF::URI.new('http://www.openarchives.org/ore/terms/proxyFor'), class_name: 'Different', through: 'Proxy', foreign_key: :proxy_for
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
        Object.send(:remove_const, :Different)
      end

      let(:o) { FooHistory.create }
      let(:file) { o.related_objects.build }
      let(:reloaded) { FooHistory.find(o.id) }

      describe "#build" do
        subject { file }
        it { is_expected.to be_kind_of Different }
      end

      context "when the object exists" do
        before do
          file.title = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.related_objects.first }
          it "has the content" do
            expect(subject.title).to eq 'HMMM'
          end
        end
      end
    end

    context "when using is_member_of_relation" do #, skip: "As far as I can tell, FC4 doesn't support IndirectContainer with isMemberOfRelation" do
      before do
        class FooHistory < ActiveFedora::Base
          indirectly_contains :related_objects, is_member_of_relation: ::RDF::URI.new("http://example.com/isWithin"), inserted_content_relation: ::RDF::URI.new('http://www.openarchives.org/ore/terms/proxyFor'), through: 'Proxy', foreign_key: :proxy_for
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end

      let(:file) { o.related_objects.build }
      let(:reloaded) { FooHistory.find(o.id) }

      context "with no related_objects" do
        let(:o) { FooHistory.new }
        subject { o.related_objects }

        it { is_expected.to be_empty }
        it { is_expected.to eq [] }
      end

      context "when the object exists" do
        let(:o) { FooHistory.create }

        before do
          file.title = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.related_objects.first }
          it "has the content" do
            expect(subject.title).to eq 'HMMM'
          end
        end
      end
    end
  end
end
