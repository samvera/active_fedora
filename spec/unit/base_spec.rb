require 'spec_helper'
@@last_pid = 0

describe ActiveFedora::Base do
  describe "sharding" do
    it "should have a shard_index" do
      expect(ActiveFedora::Base.shard_index(@this_pid)).to eq(0)
    end

    context "When the repository is NOT sharded" do
      subject {ActiveFedora::Base.connection_for_pid('foo:bar')}
      before(:each) do
        allow(ActiveFedora.config).to receive(:sharded?).and_return(false)
        ActiveFedora::Base.fedora_connection = {}
        allow(ActiveFedora.config).to receive(:credentials).and_return(:url=>'myfedora')
      end
      it { is_expected.to be_kind_of Rubydora::Repository}
      it "should be the standard connection" do
        expect(subject.client.url).to eq('myfedora')
      end
      describe "assign_pid" do
        it "should use fedora to generate pids" do
          # TODO: This juggling of Fedora credentials & establishing connections should be handled by an establish_fedora_connection method,
          # possibly wrap it all into a fedora_connection method - MZ 06-05-2012
          stubfedora = double("Fedora")
          expect(stubfedora).to receive(:connection).and_return(double("Connection", :next_pid =>"<pid>sample:newpid</pid>"))
          # Should use ActiveFedora.config.credentials as a single hash rather than an array of shards
          expect(ActiveFedora::RubydoraConnection).to receive(:new).with(ActiveFedora.config.credentials).and_return(stubfedora)
          ActiveFedora::Base.assign_pid(ActiveFedora::Base.new.inner_object)
        end
      end
      describe "shard_index" do
        it "should always return zero (the first and only connection)" do
          expect(ActiveFedora::Base.shard_index('foo:bar')).to eq(0)
        end
      end
    end
    context "When the repository is sharded" do
      before :each do
        allow(ActiveFedora.config).to receive(:sharded?).and_return(true)
        ActiveFedora::Base.fedora_connection = {}
        allow(ActiveFedora.config).to receive(:credentials).and_return([{:url=>'shard1'}, {:url=>'shard2'} ])
      end
      describe "assign_pid" do
        it "should always use the first shard to generate pids" do
          stubhard1 = double("Shard")
          stubhard2 = double("Shard")
          expect(stubhard1).to receive(:connection).and_return(double("Connection", :next_pid =>"<pid>sample:newpid</pid>"))
          expect(stubhard2).to receive(:connection).never
          ActiveFedora::Base.fedora_connection = {0 => stubhard1, 1 => stubhard2}
          ActiveFedora::Base.assign_pid(ActiveFedora::Base.new.inner_object)
        end
      end
      describe "shard_index" do
        it "should use modulo of md5 of the pid to distribute objects across shards" do
          expect(ActiveFedora::Base.shard_index('foo:bar')).to eq(0)
          expect(ActiveFedora::Base.shard_index('foo:nanana')).to eq(1)
        end
      end
      describe "the repository" do
        describe "for foo:bar" do
          subject {ActiveFedora::Base.connection_for_pid('foo:bar')}
          it "should be shard1" do
            expect(subject.client.url).to eq('shard1')
          end
        end
        describe "for foo:baz" do
          subject {ActiveFedora::Base.connection_for_pid('foo:nanana')}
          it "should be shard1" do
            expect(subject.client.url).to eq('shard2')
          end
        end
      end
    end

  end

  describe "With a test class" do
    before :all do
      class FooHistory < ActiveFedora::Base
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData", :autocreate => true do |m|
          m.field "fubar", :string
          m.field "swank", :text
        end
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText", :autocreate => true do |m|
          m.field "fubar", :text
        end
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText2", :label=>"withLabel", :autocreate => true do |m|
          m.field "fubar", :text
        end
        delegate :fubar, :to=>'withText'
        delegate :swank, :to=>'someData'
      end
      class FooAdaptation < ActiveFedora::Base
        has_metadata :type=>ActiveFedora::OmDatastream, :name=>'someData'
      end
    end

    after :all do
      Object.send(:remove_const, :FooHistory)
      Object.send(:remove_const, :FooAdaptation)
    end

    def increment_pid
      @@last_pid += 1
    end

    before(:each) do
      @this_pid = increment_pid.to_s
      stub_get(@this_pid)
      allow_any_instance_of(Rubydora::Repository).to receive(:client).and_return(@mock_client)
      allow(ActiveFedora::Base).to receive(:assign_pid).and_return(@this_pid)
      @test_object = ActiveFedora::Base.new
    end

    after(:each) do
      begin
      allow(ActiveFedora::SolrService).to receive(:instance)
      #@test_object.delete
      rescue
      end
    end


    describe '#new' do
      it "should create an inner object" do
        # for doing AFObject.new(params[:foo]) when nothing is in params[:foo]
        expect_any_instance_of(Rubydora::DigitalObject).to receive(:save).never
        result = ActiveFedora::Base.new(nil)
        expect(result.inner_object).to be_kind_of(ActiveFedora::UnsavedDigitalObject)
      end

      it "should not save or get an pid on init" do
        expect_any_instance_of(Rubydora::DigitalObject).to receive(:save).never
        expect(ActiveFedora::Base).to receive(:assign_pid).never
        f = FooHistory.new
      end

      it "should be able to create with a custom pid" do
        f = FooHistory.new(:pid=>'numbnuts:1')
        expect(f.pid).to eq('numbnuts:1')
      end
    end

    describe ".datastream_class_for_name" do
      it "should return the specifed class" do
        expect(FooAdaptation.datastream_class_for_name('someData')).to eq(ActiveFedora::OmDatastream)
      end
      it "should return the specifed class" do
        expect(FooAdaptation.datastream_class_for_name('content')).to eq(ActiveFedora::Datastream)
      end
    end

    describe ".internal_uri" do
      it "should return pid as fedors uri" do
        expect(@test_object.internal_uri).to eql("info:fedora/#{@test_object.pid}")
      end
    end

    ### Methods for ActiveModel::Conversions
    it "should have to_param once it's saved" do
      expect(@test_object.to_param).to be_nil
      @test_object.inner_object.stub(:new? => false)
      expect(@test_object.to_param).to eq(@test_object.pid)
    end

    it "should have to_key once it's saved" do
      expect(@test_object.to_key).to be_nil
      @test_object.inner_object.stub(:new? => false)
      expect(@test_object.to_key).to eq([@test_object.pid])
    end

    it "should have to_model when it's saved" do
      expect(@test_object.to_model).to be @test_object
    end
    ### end ActiveModel::Conversions

    ### Methods for ActiveModel::Naming
    it "Should know the model_name" do
      expect(FooHistory.model_name).to eq('FooHistory')
      expect(FooHistory.model_name.human).to eq('Foo history')
    end
    ### End ActiveModel::Naming

    describe ".datastreams" do
      before do
        @test_history = FooHistory.new
      end
      it "should create dynamic accessors" do
        expect(@test_history.withText).to eq(@test_history.datastreams['withText'])
      end
      it "dynamic accessors should convert dashes to underscores" do
        ds = double('datastream', :dsid=>'eac-cpf')
        @test_history.add_datastream(ds)
        expect(@test_history.eac_cpf).to eq(ds)
      end
      it "dynamic accessors should not convert datastreams named with underscore" do
        ds = double('datastream', :dsid=>'foo_bar')
        @test_history.add_datastream(ds)
        expect(@test_history.foo_bar).to eq(ds)
      end
    end

    it 'should provide #find' do
      expect(ActiveFedora::Base).to respond_to(:find)
    end

    it "should provide .create_date" do
      expect(@test_object).to respond_to(:create_date)
    end

    it "should provide .modified_date" do
      expect(@test_object).to respond_to(:modified_date)
    end

    it 'should respond to .rels_ext' do
      expect(@test_object).to respond_to(:rels_ext)
    end

    describe '.rels_ext' do
      it 'should return the RelsExtDatastream object from the datastreams array' do
        @test_object.stub(:datastreams => {"RELS-EXT" => "foo"})
        expect(@test_object.rels_ext).to eq("foo")
      end
    end

    it 'should provide #add_relationship' do
      expect(@test_object).to respond_to(:add_relationship)
    end

    describe '#add_relationship' do
      it 'should call #add_relationship on the rels_ext datastream' do
        @test_object.add_relationship("predicate", "info:fedora/object")
        pred = ActiveFedora::Predicates.vocabularies["info:fedora/fedora-system:def/relations-external#"]["predicate"]
        expect(@test_object.relationships).to have_statement(RDF::Statement.new(RDF::URI.new(@test_object.internal_uri), pred, RDF::URI.new("info:fedora/object")))
      end

      it "should update the RELS-EXT datastream and set the datastream as dirty when relationships are added" do
        mock_ds = double("Rels-Ext")
        allow(mock_ds).to receive(:content_will_change!)
        @test_object.datastreams["RELS-EXT"] = mock_ds
        @test_object.add_relationship(:is_member_of, "info:fedora/demo:5")
        @test_object.add_relationship(:is_member_of, "info:fedora/demo:10")
      end

      it 'should add a relationship to an object only if it does not exist already' do
        next_pid = increment_pid.to_s
        allow(ActiveFedora::Base).to receive(:assign_pid).and_return(next_pid)
        stub_get(next_pid)

        @test_object3 = ActiveFedora::Base.new
        @test_object.add_relationship(:has_part,@test_object3)
        expect(@test_object.ids_for_outbound(:has_part)).to eq([@test_object3.pid])
        #try adding again and make sure not there twice
        @test_object.add_relationship(:has_part,@test_object3)
        expect(@test_object.ids_for_outbound(:has_part)).to eq([@test_object3.pid])
      end

      it 'should add literal relationships if requested' do
        @test_object.add_relationship(:conforms_to,"AnInterface",true)
        expect(@test_object.ids_for_outbound(:conforms_to)).to eq(["AnInterface"])
      end
    end

    it 'should provide #remove_relationship' do
      expect(@test_object).to respond_to(:remove_relationship)
    end

    describe '#remove_relationship' do
      it 'should remove a relationship from the relationships hash' do
        @test_object3 = ActiveFedora::Base.new()
        @test_object3.stub(:pid=>'7')
        @test_object4 = ActiveFedora::Base.new()
        @test_object4.stub(:pid=>'8')
        @test_object.add_relationship(:has_part,@test_object3)
        @test_object.add_relationship(:has_part,@test_object4)
        #check both are there
        expect(@test_object.ids_for_outbound(:has_part)).to eq([@test_object3.pid,@test_object4.pid])
        @test_object.remove_relationship(:has_part,@test_object3)
        #check only one item removed
        expect(@test_object.ids_for_outbound(:has_part)).to eq([@test_object4.pid])
        @test_object.remove_relationship(:has_part,@test_object4)
        #check last item removed and predicate removed since now emtpy
        expect(@test_object.relationships.size).to eq(0)
      end
    end

    it 'should provide #relationships' do
      expect(@test_object).to respond_to(:relationships)
    end

    describe '#relationships' do
      it 'should return a graph' do
        expect(@test_object.relationships.kind_of?(RDF::Graph)).to be_truthy
        expect(@test_object.relationships.size).to eq(0)
      end
    end

    describe '.assert_content_model' do
      it "should default to the name of the class" do
        stub_get(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT'])
        @test_object.assert_content_model
        expect(@test_object.relationships(:has_model)).to eq(["info:fedora/afmodel:ActiveFedora_Base"])
      end
    end

    describe '.save' do
      it "should create a new record" do
        @test_object.stub(:new_record? => true)
        expect(@test_object).to receive(:create)
        expect(@test_object).to receive(:update_index)
        @test_object.save
      end

      it "should update an existing record" do
        @test_object.stub(:new_record? => false)
        expect(@test_object).to receive(:update)
        expect(@test_object).to receive(:update_index)
        @test_object.save
      end
    end

    describe "#create" do
      it "should build a new record and save it" do
        obj = double()
        expect(obj).to receive(:save)
        expect(FooHistory).to receive(:new).and_return(obj)
        @hist = FooHistory.create(:fubar=>'ta', :swank=>'da')
      end
    end

    describe ".adapt_to" do
      it "should return an adapted object of the requested type" do
        @test_object = FooHistory.new()
        expect(@test_object.adapt_to(FooAdaptation).class).to eq(FooAdaptation)
      end
      it "should not make an additional call to fedora to create the adapted object" do
        @test_object = FooHistory.new()
        adapted = @test_object.adapt_to(FooAdaptation)
      end
      it "should propagate new datastreams to the adapted object" do
        @test_object = FooHistory.new()
        @test_object.add_file_datastream("XXX", :dsid=>'MY_DSID')
        adapted = @test_object.adapt_to(FooAdaptation)
        expect(adapted.datastreams.keys).to include 'MY_DSID'
        expect(adapted.datastreams['MY_DSID'].content).to eq("XXX")
        expect(adapted.datastreams['MY_DSID'].changed?).to be_truthy
      end
      it "should propagate modified datastreams to the adapted object" do
        @test_object = FooHistory.new()
        orig_ds = @test_object.datastreams['someData']
        orig_ds.content="<YYY/>"
        adapted = @test_object.adapt_to(FooAdaptation)
        expect(adapted.datastreams.keys).to include 'someData'
        expect(adapted.datastreams['someData']).to eq(orig_ds)
        expect(adapted.datastreams['someData'].content.strip).to eq("<YYY/>")
        expect(adapted.datastreams['someData'].changed?).to be_truthy
      end
      it "should use the datastream definitions from the adapted object" do
        @test_object = FooHistory.new()
        adapted = @test_object.adapt_to(FooAdaptation)
        expect(adapted.datastreams.keys).to include 'someData'
        expect(adapted.datastreams['someData'].class).to eq(ActiveFedora::OmDatastream)
      end
    end

    describe ".adapt_to_cmodel" do
      subject { FooHistory.new }
      it "should cast when a cmodel is found" do
        expect(ActiveFedora::ContentModel).to receive(:known_models_for).with( subject).and_return([FooAdaptation])
        expect(subject.adapt_to_cmodel).to be_kind_of FooAdaptation
      end
      it "should not cast when a cmodel is same as the class" do
        expect(ActiveFedora::ContentModel).to receive(:known_models_for).with( subject).and_return([FooHistory])
        expect(subject.adapt_to_cmodel).to be === subject
      end
    end

    describe ".to_solr" do
      it "should provide .to_solr" do
        expect(@test_object).to respond_to(:to_solr)
      end

      it "should add pid, system_create_date and system_modified_date from object attributes" do
        expect(@test_object).to receive(:create_date).and_return("2012-03-04T03:12:02Z")
        expect(@test_object).to receive(:modified_date).and_return("2012-03-07T03:12:02Z")
        solr_doc = @test_object.to_solr
        expect(solr_doc[ActiveFedora::SolrService.solr_name("system_create", :date, :searchable)]).to eql("2012-03-04T03:12:02Z")
        expect(solr_doc[ActiveFedora::SolrService.solr_name("system_modified", :date, :searchable)]).to eql("2012-03-07T03:12:02Z")
        expect(solr_doc[:id]).to eql("#{@test_object.pid}")
      end

      it "should omit base metadata and RELS-EXT if :model_only==true" do
        @test_object.add_relationship(:has_part, "foo", true)
        solr_doc = @test_object.to_solr(Hash.new, :model_only => true)
        expect(solr_doc[ActiveFedora::SolrService.solr_name("system_create", :date, :searchable)]).to be_nil
        expect(solr_doc[ActiveFedora::SolrService.solr_name("system_modified", :date, :searchable)]).to be_nil
        expect(solr_doc["id"]).to be_nil
        expect(solr_doc[ActiveFedora::SolrService.solr_name("has_part", :symbol)]).to be_nil
      end

      it "should add self.class as the :active_fedora_model" do
        stub_get(@this_pid)
        stub_get_content(@this_pid, ['RELS-EXT', 'someData', 'withText2', 'withText'])
        @test_history = FooHistory.new()
        solr_doc = @test_history.to_solr
        expect(solr_doc[ActiveFedora::SolrService.solr_name("active_fedora_model", :symbol)]).to eql("FooHistory")
      end

      it "should call .to_solr on all SimpleDatastreams and OmDatastreams, passing the resulting document to solr" do
        mock1 = double("ds1", :to_solr => {})
        mock2 = double("ds2", :to_solr => {})
        ngds = double("ngds", :to_solr => {})
        expect(ngds).to receive(:solrize_profile)
        expect(mock1).to receive(:solrize_profile)
        expect(mock2).to receive(:solrize_profile)

        expect(@test_object).to receive(:datastreams).twice.and_return({:ds1 => mock1, :ds2 => mock2, :ngds => ngds})
        expect(@test_object).to receive(:solrize_relationships)
        @test_object.to_solr
      end

      it "should call .to_solr on all RDFDatastreams, passing the resulting document to solr" do
        mock = double("ds1", :to_solr => {})
        expect(mock).to receive(:solrize_profile)
        expect(@test_object).to receive(:datastreams).twice.and_return({:ds1 => mock})
        expect(@test_object).to receive(:solrize_relationships)
        @test_object.to_solr
      end

      it "should call .to_solr on the relationships rels-ext is dirty" do
        @test_object.add_relationship(:has_collection_member, "info:fedora/foo:member")
        rels_ext = @test_object.rels_ext
        expect(rels_ext).to be_changed
        expect(@test_object).to receive(:solrize_relationships)
        @test_object.to_solr
      end

    end

    describe ".label" do
      it "should return the label of the inner object" do
        expect(@test_object.inner_object).to receive(:label).and_return("foo label")
        expect(@test_object.label).to eq("foo label")
      end
    end

    describe ".label=" do
      it "should set the label of the inner object" do
        expect(@test_object.label).not_to eq("foo label")
        @test_object.label = "foo label"
        expect(@test_object.label).to eq("foo label")
      end
    end

    describe "get_values_from_datastream" do
      it "should look up the named datastream and call get_values with the given pointer/field_name" do
        mock_ds = double("Datastream", :get_values=>["value1", "value2"])
        allow(@test_object).to receive(:datastreams).and_return({"ds1"=>mock_ds})
        expect(@test_object.get_values_from_datastream("ds1", "--my xpath--")).to eq(["value1", "value2"])
      end
    end

    describe "update_datastream_attributes" do
      it "should look up any datastreams specified as keys in the given hash and call update_attributes on the datastream" do
        mock_desc_metadata = double("descMetadata")
        mock_properties = double("properties")
        mock_ds_hash = {'descMetadata'=>mock_desc_metadata, 'properties'=>mock_properties}

        ds_values_hash = {
          "descMetadata"=>{ [{:person=>0}, :role]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} },
          "properties"=>{ "notes"=>"foo" }
        }
        m = FooHistory.new
        allow(m).to receive(:datastreams).and_return(mock_ds_hash)
        expect(mock_desc_metadata).to receive(:update_indexed_attributes).with( ds_values_hash['descMetadata'] )
        expect(mock_properties).to receive(:update_indexed_attributes).with( ds_values_hash['properties'] )
        m.update_datastream_attributes( ds_values_hash )
      end
      it "should not do anything and should return an empty hash if the specified datastream does not exist" do
skip "This is broken, and deprecated.  I don't want to fix it - jcoyne"
        ds_values_hash = {
          "nonexistentDatastream"=>{ "notes"=>"foo" }
        }
        m = FooHistory.new
        untouched_xml = m.to_xml
        expect(m.update_datastream_attributes( ds_values_hash )).to eq({})
        expect(m.to_xml).to eq(untouched_xml)
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

    describe "update_indexed_attributes" do
      it "should call .update_indexed_attributes on all metadata datastreams & nokogiri datastreams" do
        m = FooHistory.new
        att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}

        expect(m.datastreams['someData']).to receive(:update_indexed_attributes)
        expect(m.datastreams["withText"]).to receive(:update_indexed_attributes)
        expect(m.datastreams['withText2']).to receive(:update_indexed_attributes)
        m.update_indexed_attributes(att)
      end
      it "should take a :datastreams argument" do
        att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
        stub_get(@this_pid)
        stub_get_content(@this_pid, ['RELS-EXT', 'someData', 'withText2', 'withText'])
        m = FooHistory.new()
        m.update_indexed_attributes(att, :datastreams=>"withText")
        expect(m).not_to be_nil
        expect(m.datastreams['someData'].fubar).to eq([])
        expect(m.datastreams["withText"].fubar).to eq(['york', 'mangle'])
        expect(m.datastreams['withText2'].fubar).to eq([])

        att= {"fubar"=>{"-1"=>"tork", "0"=>"work", "1"=>"bork"}}
        m.update_indexed_attributes(att, :datastreams=>["someData", "withText2"])
        expect(m).not_to be_nil
        expect(m.datastreams['someData'].fubar).to eq(['work', 'bork'])
        expect(m.datastreams['withText2'].fubar).to eq(['work', 'bork'])
      end
    end

    describe '#relationships_by_name' do
      before(:all) do
        @behavior = ActiveFedora::Relationships.deprecation_behavior
        @c_behavior = ActiveFedora::Relationships::ClassMethods.deprecation_behavior
        ActiveFedora::Relationships.deprecation_behavior = :silence
        ActiveFedora::Relationships::ClassMethods.deprecation_behavior = :silence
      end

      after :all do
        ActiveFedora::Relationships.deprecation_behavior = @behavior
        ActiveFedora::Relationships::ClassMethods.deprecation_behavior = @c_behavior
      end

      before do
        class MockNamedRelationships < ActiveFedora::Base
          include ActiveFedora::FileManagement
          has_relationship "testing", :has_part, :type=>ActiveFedora::Base
          has_relationship "testing2", :has_member, :type=>ActiveFedora::Base
          has_relationship "testing_inbound", :has_part, :type=>ActiveFedora::Base, :inbound=>true
        end
      end

      it 'should return current relationships by name' do
        next_pid = increment_pid.to_s
        allow(ActiveFedora::Base).to receive(:assign_pid).and_return(next_pid)
        stub_get(next_pid)
        @test_object2 = MockNamedRelationships.new
        @test_object2.add_relationship(:has_model, MockNamedRelationships.to_class_uri)
        @test_object.add_relationship(:has_model, ActiveFedora::Base.to_class_uri)
        #should return expected named relationships
        @test_object2.relationships_by_name
        expect(@test_object2.relationships_by_name[:self]["testing"]).to eq([])
        expect(@test_object2.relationships_by_name[:self]["testing2"]).to eq([])
        expect(@test_object2.relationships_by_name[:self]["parts_outbound"]).to eq([])
        @test_object2.add_relationship_by_name("testing",@test_object)
        # @test_object2.relationships_by_name.should == {:self=>{"testing"=>[@test_object.internal_uri],"testing2"=>[],"part_of"=>[], "parts_outbound"=>[@test_object.internal_uri], "collection_members"=>[]}}

        expect(@test_object2.relationships_by_name[:self]["testing"]).to eq([@test_object.internal_uri])
        expect(@test_object2.relationships_by_name[:self]["testing2"]).to eq([])
        expect(@test_object2.relationships_by_name[:self]["parts_outbound"]).to eq([@test_object.internal_uri])
      end
    end


    describe '#create_relationship_name_methods' do
      before(:all) do
        @behavior = ActiveFedora::Relationships.deprecation_behavior
        @c_behavior = ActiveFedora::Relationships::ClassMethods.deprecation_behavior
        ActiveFedora::Relationships.deprecation_behavior = :silence
        ActiveFedora::Relationships::ClassMethods.deprecation_behavior = :silence
      end

      after :all do
        ActiveFedora::Relationships.deprecation_behavior = @behavior
        ActiveFedora::Relationships::ClassMethods.deprecation_behavior = @c_behavior
      end

      before do
        class MockCreateNamedRelationshipMethodsBase < ActiveFedora::Base
          include ActiveFedora::Relationships
          register_relationship_desc :self, "testing", :is_part_of, :type=>ActiveFedora::Base
          create_relationship_name_methods "testing"
        end
      end

      it 'should append and remove using helper methods for each outbound relationship' do
        next_pid = increment_pid.to_s
        allow(ActiveFedora::Base).to receive(:assign_pid).and_return(next_pid)
        stub_get(next_pid)
        @test_object2 = MockCreateNamedRelationshipMethodsBase.new
        expect(@test_object2).to respond_to(:testing_append)
        expect(@test_object2).to respond_to(:testing_remove)
        #test executing each one to make sure code added is correct
        model_pid =ActiveFedora::Base.to_class_uri
        @test_object.add_relationship(:has_model,model_pid)
        @test_object2.add_relationship(:has_model,model_pid)
        @test_object2.testing_append(@test_object)
        #create relationship to access generate_uri method for an object
        expect(@test_object2.relationships_by_name[:self]["testing"]).to eq([@test_object.internal_uri])
        @test_object2.testing_remove(@test_object)
        expect(@test_object2.relationships_by_name[:self]["testing"]).to eq([])
      end
    end

    describe ".solrize_relationships" do
      it "should serialize the relationships into a Hash" do
        graph = RDF::Graph.new
        subject = RDF::URI.new "info:fedora/test:sample_pid"
        graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('info:fedora/demo:10'))
        graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_part_of),  RDF::URI.new('info:fedora/demo:11'))
        graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new('info:fedora/demo:12'))
        graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:conforms_to),  "AnInterface")

        expect(@test_object).to receive(:relationships).and_return(graph)
        solr_doc = @test_object.solrize_relationships
        expect(solr_doc[ActiveFedora::SolrService.solr_name("is_member_of", :symbol)]).to eq(["info:fedora/demo:10"])
        expect(solr_doc[ActiveFedora::SolrService.solr_name("is_part_of", :symbol)]).to eq(["info:fedora/demo:11"])
        expect(solr_doc[ActiveFedora::SolrService.solr_name("has_part", :symbol)]).to eq(["info:fedora/demo:12"])
        expect(solr_doc[ActiveFedora::SolrService.solr_name("conforms_to", :symbol)]).to eq(["AnInterface"])
      end
    end
  end
end
