require 'spec_helper'
@@last_id = 0

describe ActiveFedora::Base do
  it_behaves_like "An ActiveModel"

  describe "id=" do
    before do
      class FooHistory < ActiveFedora::Base
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end
    after do
      Object.send(:remove_const, :FooHistory)
    end

    subject(:history) { FooHistory.new(title: ["A good title"]) }
    before { history.id = 9 }

    it "is settable" do
      expect(history.id).to eq '9'
      expect(history.title).to eq ["A good title"]
    end

    it "is only settable once" do
      expect { history.id = 10 }.to raise_error "ID has already been set to 9"
      expect(history.id).to eq '9'
    end
  end

  describe ".type" do
    before do
      class FooHistory < ActiveFedora::Base
        type ::RDF::URI.new('http://example.com/foo')
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end
    after do
      Object.send(:remove_const, :FooHistory)
    end

    subject(:history) { FooHistory.new.type }

    it { is_expected.to eq [RDF::URI('http://example.com/foo')] }

    context "when type is called before propertes" do
      subject(:history) { FooHistory.resource_class.reflect_on_property(:title) }
      it "does not wipe out the properties" do
        expect(history).to be_kind_of ActiveTriples::NodeConfig
      end
    end
  end

  describe ".rdf_label" do
    context "on a concrete class" do
      before do
        class FooHistory < ActiveFedora::Base
          rdf_label ::RDF::Vocab::DC.title
          property :title, predicate: ::RDF::Vocab::DC.title
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end

      subject { instance.rdf_label }
      let(:instance) { FooHistory.new(title: ['A label']) }

      it { is_expected.to eq ['A label'] }
    end

    context "on an inherited class" do
      before do
        class Agent < ActiveFedora::Base
          rdf_label ::RDF::Vocab::FOAF.name
          property :foaf_name, predicate: ::RDF::Vocab::FOAF.name
        end
        class Person < Agent
          rdf_label ::RDF::URI('http://example.com/foo')
          property :job, predicate: ::RDF::URI('http://example.com/foo')
        end
        class Creator < Person
        end
      end
      after do
        Object.send(:remove_const, :Person)
        Object.send(:remove_const, :Agent)
        Object.send(:remove_const, :Creator)
      end

      subject { instance.rdf_label }
      let(:instance) { Creator.new(foaf_name: ['Carolyn'], job: ['Developer']) }

      it { is_expected.to eq ['Developer'] }
    end
  end

  describe 'descendants' do
    before do
      class SpecialThing < ActiveFedora::Base
      end
    end

    after do
      Object.send(:remove_const, :SpecialThing)
    end

    it "records the decendants" do
      expect(described_class.descendants).to include(SpecialThing)
    end
  end

  describe "With a test class" do
    before do
      class FooHistory < ActiveFedora::Base
        property :fubar, predicate: ::RDF::URI('http://example.com/fubar')
      end
    end

    after do
      Object.send(:remove_const, :FooHistory)
    end

    def increment_id
      @@last_id += 1
    end

    before do
      @this_id = increment_id.to_s
      @test_object = described_class.new
      allow(@test_object).to receive(:assign_id).and_return(@this_id)
    end

    describe '#new' do
      before do
        allow_any_instance_of(FooHistory).to receive(:assign_id).and_return(@this_id)
      end

      context "with no arguments" do
        it "does not get an id on init" do
          expect(FooHistory.new.id).to be_nil
        end
      end

      context "with a hash argument" do
        context "that has an id" do
          it "is able to create with a custom id" do
            expect(FooHistory).to receive(:id_to_uri).and_call_original
            f = FooHistory.new(id: 'baz_1')
            expect(f.id).to eq 'baz_1'
            expect(f.id).to eq 'baz_1'
          end
        end

        context "that doesn't have an id" do
          it "is able to create with a custom id" do
            f = FooHistory.new(fubar: ['baz_1'])
            expect(f.id).to be_nil
          end
        end
      end
    end

    ### Methods for ActiveModel::Conversions
    context "before saving" do
      context "#to_param" do
        subject { @test_object.to_param }
        it { is_expected.to be_nil }
      end
      context "#to_key" do
        subject { @test_object.to_key }
        it { is_expected.to be_nil }
      end
    end

    context "when its saved" do
      before do
        allow(@test_object).to receive(:new_record?).and_return(false)
        allow(@test_object).to receive(:uri).and_return("#{ActiveFedora.fedora.host}/test/one/two/three")
      end

      context "#to_param" do
        subject { @test_object.to_param }
        it { is_expected.to eq 'one/two/three' }
      end

      context "#to_key" do
        subject { @test_object.to_key }
        it { is_expected.to eq ['one/two/three'] }
      end
    end
    ### end ActiveModel::Conversions

    ### Methods for ActiveModel::Naming
    it "knows the model_name" do
      expect(FooHistory.model_name).to eq 'FooHistory'
      expect(FooHistory.model_name.human).to eq 'Foo history'
    end
    ### End ActiveModel::Naming

    it 'provides #find' do
      expect(described_class).to respond_to(:find)
    end

    it "provides .create_date" do
      expect(@test_object).to respond_to(:create_date)
    end

    it "provides .modified_date" do
      expect(@test_object).to respond_to(:modified_date)
    end

    describe '.save' do
      it "creates a new record" do
        allow(@test_object).to receive(:new_record?).and_return(true)
        expect(@test_object).to receive(:serialize_attached_files)
        expect(@test_object).to receive(:assign_rdf_subject)
        expect(@test_object.ldp_source).to receive(:create)
        expect(@test_object).to receive(:refresh)
        expect(@test_object).to receive(:update_index)
        @test_object.save
      end

      context "on an existing record" do
        it "updates" do
          allow(@test_object).to receive(:new_record?).and_return(false)
          expect(@test_object).to receive(:serialize_attached_files)
          allow_any_instance_of(Ldp::Orm).to receive(:save) { true }
          expect(@test_object).to receive(:refresh)
          expect(@test_object).to receive(:update_index)
          @test_object.save
        end
      end

      context "when assign id returns a value" do
        context "an no id has been set" do
          it "sets the id" do
            @test_object.save
            expect(@test_object.id).to eq @this_id
          end

          context "and the object has properties" do
            let(:test_object) { WithProperty.new(title: ['foo']) }
            before do
              class WithProperty < ActiveFedora::Base
                property :title, predicate: ::RDF::Vocab::DC.title
              end
              allow(test_object).to receive(:assign_id).and_return(@this_id)
              test_object.save
            end
            after do
              Object.send(:remove_const, :WithProperty)
            end

            it "updates the resource" do
              expect(test_object.resource.rdf_subject).to eq ::RDF::URI.new("#{ActiveFedora.fedora.base_uri}/#{@this_id}")
              expect(test_object.title).to eq ['foo']
            end
          end
        end

        context "when an id is set" do
          before do
            @test_object = described_class.new(id: '999')
            allow(@test_object).to receive(:assign_id).and_return(@this_id)
          end
          it "does not set the id" do
            @test_object.save
            expect(@test_object.id).to eq '999'
          end
        end
      end
    end

    describe "#create" do
      it "builds a new record and save it" do
        obj = instance_double(FooHistory)
        expect(obj).to receive(:save)
        expect(FooHistory).to receive(:new).and_return(obj)
        FooHistory.create(fubar: 'ta')
      end
    end

    describe "update_attributes" do
      it "sets the attributes and save" do
        m = FooHistory.new
        att = { "fubar" => '1234', "baz" => 'stuff' }

        expect(m).to receive(:fubar=).with('1234')
        expect(m).to receive(:baz=).with('stuff')
        expect(m).to receive(:save)
        m.update_attributes(att)
      end
    end

    describe "update" do
      it "sets the attributes and save" do
        m = FooHistory.new
        att = { "fubar" => '1234', "baz" => 'stuff' }

        expect(m).to receive(:fubar=).with('1234')
        expect(m).to receive(:baz=).with('stuff')
        expect(m).to receive(:save)
        m.update(att)
      end
    end
  end

  describe '.dangerous_attribute_method?' do
    before do
      class FooHistory < ActiveFedora::Base
        type ::RDF::URI.new('http://example.com/foo')
        property :title, predicate: ::RDF::Vocab::DC.title
      end
    end
    after do
      Object.send(:remove_const, :FooHistory)
    end

    it 'is dangerous if it is defined by the class' do
      expect(FooHistory.dangerous_attribute_method?(:save)).to eq true
    end

    it 'is not dangerous if it is defined outside of ActiveFedora' do
      expect(FooHistory.dangerous_attribute_method?(:puts)).to eq false
    end
  end
end
