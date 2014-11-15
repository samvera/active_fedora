require 'spec_helper'
@@last_id = 0

describe ActiveFedora::Base do
  it_behaves_like "An ActiveModel"

  describe 'descendants' do
    it "should record the decendants" do
      expect(ActiveFedora::Base.descendants).to include(ModsArticle, SpecialThing)
    end
  end

  describe "reindex_everything" do
    it "should call update_index on every object represented in the sitemap" do
      allow(ActiveFedora::Base).to receive(:get_descendent_uris) { ['http://localhost/test/XXX', 'http://localhost/test/YYY', 'http://localhost/test/ZZZ'] }
      mock_update = double(:mock_obj)
      expect(mock_update).to receive(:update_index).exactly(3).times
      expect(ActiveFedora::Base).to receive(:find).with(instance_of ActiveFedora::LdpResource ).and_return(mock_update).exactly(3).times
      ActiveFedora::Base.reindex_everything
    end
  end

  describe "get_descendent_uris" do

    before :each do
      ids.each do |id|
        ActiveFedora::Base.create id: id
      end
    end

    def root_uri(ids=[])
      ActiveFedora::Base.id_to_uri(ids.first)
    end

    context 'when there there are no descendents' do

      let(:ids) { ['foo'] }

      it 'returns an array containing only the URI passed to it' do
        expect(ActiveFedora::Base.get_descendent_uris(root_uri(ids))).to eq ids.map {|id| ActiveFedora::Base.id_to_uri(id) }
      end
    end

    context 'when there are > 1 descendents' do

      let(:ids) { ['foo', 'foo/bar', 'foo/bar/chu'] }

      it 'returns an array containing the URI passed to it, as well as all descendent URIs' do
        expect(ActiveFedora::Base.get_descendent_uris(root_uri(ids))).to eq ids.map {|id| ActiveFedora::Base.id_to_uri(id) }
      end
    end
  end

  describe "With a test class" do
    before :each do
      class FooHistory < ActiveFedora::Base
        has_metadata 'someData', type: ActiveFedora::SimpleDatastream, autocreate: true do |m|
          m.field "fubar", :string
          m.field "swank", :text
        end
        has_metadata "withText", type: ActiveFedora::SimpleDatastream, autocreate: true do |m|
          m.field "fubar", :text
        end
        has_metadata "withText2", type: ActiveFedora::SimpleDatastream, autocreate: true do |m|
          m.field "fubar", :text
        end
        has_attributes :fubar, datastream: 'withText', multiple: true
        has_attributes :swank, datastream: 'someData', multiple: true
      end

      class FooAdaptation < ActiveFedora::Base
        has_metadata 'someData', type: ActiveFedora::OmDatastream
      end

      class FooInherited < FooHistory

      end
    end

    after :each do
      Object.send(:remove_const, :FooHistory)
      Object.send(:remove_const, :FooAdaptation)
      Object.send(:remove_const, :FooInherited)
    end

    def increment_id
      @@last_id += 1
    end

    before do
      @this_id = increment_id.to_s
      @test_object = ActiveFedora::Base.new
      allow(@test_object).to receive(:assign_id).and_return(@this_id)
    end


    describe '#new' do
      before do
        allow_any_instance_of(FooHistory).to receive(:assign_id).and_return(@this_id)
      end
      context "with no arguments" do
        it "should not get an id on init" do
          expect(FooHistory.new.id).to be_nil
        end
      end

      context "with an id argument" do
        it "should be able to create with a custom id" do
          expect(FooHistory).to receive(:id_to_uri).and_call_original
          f = FooHistory.new('baz_1')
          expect(f.id).to eq 'baz_1'
          expect(f.id).to eq 'baz_1'
        end
      end

      context "with a hash argument" do
        context "that has an id" do
          it "should be able to create with a custom id" do
            expect(FooHistory).to receive(:id_to_uri).and_call_original
            f = FooHistory.new(id: 'baz_1')
            expect(f.id).to eq 'baz_1'
            expect(f.id).to eq 'baz_1'
          end
        end

        context "that doesn't have an id" do
          it "should be able to create with a custom id" do
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
        it { should be_nil }
      end
      context "#to_key" do
        subject { @test_object.to_key }
        it { should be_nil }
      end
    end

    context "when its saved" do
      before do
        allow(@test_object).to receive(:new_record?).and_return(false)
        allow(@test_object).to receive(:uri).and_return('http://localhost:8983/fedora/rest/test/one/two/three')
      end

      context "#to_param" do
        subject { @test_object.to_param }
        it { should eq 'one/two/three' }
      end

      context "#to_key" do
        subject { @test_object.to_key }
        it { should eq ['one/two/three'] }
      end
    end
    ### end ActiveModel::Conversions

    ### Methods for ActiveModel::Naming
    it "Should know the model_name" do
      expect(FooHistory.model_name).to eq 'FooHistory'
      expect(FooHistory.model_name.human).to eq 'Foo history'
    end
    ### End ActiveModel::Naming

    it 'should provide #find' do
      expect(ActiveFedora::Base).to respond_to(:find)
    end

    it "should provide .create_date" do
      expect(@test_object).to respond_to(:create_date)
    end

    it "should provide .modified_date" do
      expect(@test_object).to respond_to(:modified_date)
    end

    describe '.save' do
      it "should create a new record" do
        allow(@test_object).to receive(:new_record?).and_return(true)
        expect(@test_object).to receive(:serialize_attached_files)
        expect(@test_object).to receive(:assign_rdf_subject)
        expect(@test_object.ldp_source).to receive(:create)
        expect(@test_object).to receive(:refresh)
        expect(@test_object).to receive(:update_index)
        @test_object.save
      end

      context "on an existing record" do

        it "should update" do
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

          it "should set the id" do
            @test_object.save
            expect(@test_object.id).to eq @this_id
          end

          context "and the object has properties" do
            let(:test_object) { WithProperty.new(title: 'foo') }
            before do
              class WithProperty < ActiveFedora::Base
                property :title, predicate: ::RDF::DC.title
              end
              allow(test_object).to receive(:assign_id).and_return(@this_id)
              test_object.save
            end
            after do
              Object.send(:remove_const, :WithProperty)
            end

            it "should update the resource" do
              expect(test_object.resource.rdf_subject).to eq ::RDF::URI.new("#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{@this_id}")
              expect(test_object.title).to eq ['foo']
            end
          end
        end

        context "when an id is set" do
          before do
            @test_object = ActiveFedora::Base.new(id: '999')
            allow(@test_object).to receive(:assign_id).and_return(@this_id)
          end
          it "should not set the id" do
            @test_object.save
            expect(@test_object.id).to eq '999'
          end
        end
      end
    end

    describe "#create" do
      it "should build a new record and save it" do
        obj = double()
        expect(obj).to receive(:save)
        expect(FooHistory).to receive(:new).and_return(obj)
        @hist = FooHistory.create(fubar: 'ta', swank: 'da')
      end
    end

    describe ".to_solr" do
      it "should provide .to_solr" do
        expect(@test_object).to respond_to(:to_solr)
      end

      it "should add id, system_create_date, system_modified_date from object attributes" do
        expect(@test_object).to receive(:create_date).and_return(DateTime.parse("2012-03-04T03:12:02Z")).twice
        expect(@test_object).to receive(:modified_date).and_return(DateTime.parse("2012-03-07T03:12:02Z")).twice
        allow(@test_object).to receive(:id).and_return('changeme:123')
        solr_doc = @test_object.to_solr
        expect(solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("system_create", :stored_sortable, type: :date)]).to eql("2012-03-04T03:12:02Z")
        expect(solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("system_modified", :stored_sortable, type: :date)]).to eql("2012-03-07T03:12:02Z")
        expect(solr_doc[:id]).to eql("changeme:123")
      end

      it "should add self.class as the :active_fedora_model" do
        @test_history = FooHistory.new()
        solr_doc = @test_history.to_solr
        expect(solr_doc[ActiveFedora::SolrQueryBuilder.solr_name("active_fedora_model", :stored_sortable)]).to eql("FooHistory")
      end

      it "should call .to_solr on all datastreams, passing the resulting document to solr" do
        mock1 = double("ds1")
        expect(mock1).to receive(:to_solr).and_return({})
        mock2 = double("ds2")
        expect(mock2).to receive(:to_solr).and_return({})

        allow(@test_object).to receive(:attached_files).and_return(ds1: mock1, ds2: mock2)
        expect(@test_object.indexing_service).to receive(:solrize_relationships)
        @test_object.to_solr
      end
    end

    describe "update_attributes" do
      it "should set the attributes and save" do
        m = FooHistory.new
        att= {"fubar"=> '1234', "baz" =>'stuff'}

        expect(m).to receive(:fubar=).with('1234')
        expect(m).to receive(:baz=).with('stuff')
        expect(m).to receive(:save)
        m.update_attributes(att)
      end
    end

    describe "update" do
      it "should set the attributes and save" do
        m = FooHistory.new
        att= {"fubar"=> '1234', "baz" =>'stuff'}

        expect(m).to receive(:fubar=).with('1234')
        expect(m).to receive(:baz=).with('stuff')
        expect(m).to receive(:save)
        m.update(att)
      end
    end
  end
end
