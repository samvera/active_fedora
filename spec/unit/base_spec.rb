require 'spec_helper'
@@last_pid = 0  

describe ActiveFedora::Base do
  it_behaves_like "An ActiveModel"

  describe 'descendants' do
    it "should record the decendants" do
      ActiveFedora::Base.descendants.should include(ModsArticle, SpecialThing)
    end
  end

  describe "sharding" do
    it "should have a shard_index" do
      ActiveFedora::Base.shard_index(@this_pid).should == 0
    end

    context "When the repository is NOT sharded" do
      subject {ActiveFedora::Base.connection_for_pid('test:bar')}
      before(:each) do
        ActiveFedora.config.stub(:sharded?).and_return(false)
        ActiveFedora::Base.fedora_connection = {}
        ActiveFedora.config.stub(:credentials).and_return(:url=>'myfedora')
        Rubydora::Fc3Service.any_instance.stub(:repository_profile)
      end
      it { should be_kind_of Rubydora::Repository}
      it "should be the standard connection" do
        subject.client.url.should == 'myfedora'
      end
      describe "assign_pid" do
        it "should use fedora to generate pids" do
          # TODO: This juggling of Fedora credentials & establishing connections should be handled by an establish_fedora_connection method,
          # possibly wrap it all into a fedora_connection method - MZ 06-05-2012
          stubfedora = double("Fedora")
          stubfedora.should_receive(:connection).and_return(double("Connection", :mint =>"sample:newpid"))
          # Should use ActiveFedora.config.credentials as a single hash rather than an array of shards
          ActiveFedora::RubydoraConnection.should_receive(:new).with(ActiveFedora.config.credentials).and_return(stubfedora)
          ActiveFedora::Base.assign_pid(ActiveFedora::Base.new.inner_object)
        end
      end
      describe "shard_index" do
        it "should always return zero (the first and only connection)" do
          ActiveFedora::Base.shard_index('test:bar').should == 0
        end
      end
    end
    context "When the repository is sharded" do
      before :each do
        ActiveFedora.config.stub(:sharded?).and_return(true)
        ActiveFedora::Base.fedora_connection = {}
        ActiveFedora.config.stub(:credentials).and_return([{:url=>'shard1'}, {:url=>'shard2'} ])
      end
      describe "assign_pid" do
        it "should always use the first shard to generate pids" do
          stubhard1 = double("Shard")
          stubhard2 = double("Shard")
          stubhard1.should_receive(:connection).and_return(double("Connection", :mint =>"sample:newpid"))
          stubhard2.should_receive(:connection).never
          ActiveFedora::Base.fedora_connection = {0 => stubhard1, 1 => stubhard2}
          ActiveFedora::Base.assign_pid(ActiveFedora::Base.new.inner_object)
        end
      end
      describe "shard_index" do
        it "should use modulo of md5 of the pid to distribute objects across shards" do
          ActiveFedora::Base.shard_index('test:bar').should == 0
          ActiveFedora::Base.shard_index('test:nanana').should == 1
        end
      end
      describe "the repository" do
        before do
          Rubydora::Fc3Service.any_instance.stub(:repository_profile)
        end
        describe "for test:bar" do
          subject {ActiveFedora::Base.connection_for_pid('test:bar')}
          it "should be shard1" do
            subject.client.url.should == 'shard1'
          end
        end
        describe "for test:baz" do
          subject {ActiveFedora::Base.connection_for_pid('test:nanana')}
          it "should be shard1" do
            subject.client.url.should == 'shard2'
          end
        end
      end
    end

  end

  describe "reindex_everything" do
    it "should call update_index on every object except for the fedora-system objects" do
       Rubydora::Repository.any_instance.should_receive(:search).
            and_yield(double(pid:'XXX')).and_yield(double(pid:'YYY')).and_yield(double(pid:'ZZZ')).
            and_yield(double(pid:'fedora-system:ServiceDeployment-3.0')).
            and_yield(double(pid:'fedora-system:ServiceDefinition-3.0')).
            and_yield(double(pid:'fedora-system:FedoraObject-3.0'))

       mock_update = double(:mock_obj)
       mock_update.should_receive(:update_index).exactly(3).times
       ActiveFedora::Base.should_receive(:find).with('XXX').and_return(mock_update)
       ActiveFedora::Base.should_receive(:find).with('YYY').and_return(mock_update)
       ActiveFedora::Base.should_receive(:find).with('ZZZ').and_return(mock_update)
       ActiveFedora::Base.reindex_everything
    end

    it "should accept a query param for the search" do
       query_string = "pid~*"
       Rubydora::Repository.any_instance.should_receive(:search).with(query_string).
            and_yield(double(pid:'XXX')).and_yield(double(pid:'YYY')).and_yield(double(pid:'ZZZ'))
       mock_update = double(:mock_obj)
       mock_update.should_receive(:update_index).exactly(3).times
       ActiveFedora::Base.should_receive(:find).with('XXX').and_return(mock_update)
       ActiveFedora::Base.should_receive(:find).with('YYY').and_return(mock_update)
       ActiveFedora::Base.should_receive(:find).with('ZZZ').and_return(mock_update)
       ActiveFedora::Base.reindex_everything(query_string)
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
        has_attributes :fubar, datastream: 'withText', multiple: true
        has_attributes :swank, datastream: 'someData', multiple: true
      end
      class FooAdaptation < ActiveFedora::Base
        has_metadata :type=>ActiveFedora::OmDatastream, :name=>'someData'
      end

      class FooInherited < FooHistory

      end
    end

    after :all do
      Object.send(:remove_const, :FooHistory)
      Object.send(:remove_const, :FooAdaptation)
      Object.send(:remove_const, :FooInherited)
    end

    def increment_pid
      @@last_pid += 1
    end

    before(:each) do
      @this_pid = increment_pid.to_s
      stub_get(@this_pid)
      Rubydora::Repository.any_instance.stub(:client).and_return(@mock_client)
      ActiveFedora::Base.stub(:assign_pid).and_return(@this_pid)

      @test_object = ActiveFedora::Base.new
    end

    after(:each) do
      begin
      ActiveFedora::SolrService.stub(:instance)
      #@test_object.delete
      rescue
      end
    end


    describe '#new' do
      it "should create an inner object" do
        # for doing AFObject.new(params[:foo]) when nothing is in params[:foo]
        Rubydora::DigitalObject.any_instance.should_receive(:save).never
        result = ActiveFedora::Base.new(nil)
        result.inner_object.should be_kind_of(ActiveFedora::UnsavedDigitalObject)
      end

      it "should not save or get an pid on init" do
        Rubydora::DigitalObject.any_instance.should_receive(:save).never
        ActiveFedora::Base.should_receive(:assign_pid).never
        f = FooHistory.new
      end

      it "should be able to create with a custom pid" do
        f = FooHistory.new(:pid=>'numbnuts:1')
        f.pid.should == 'numbnuts:1'
      end
    end

    describe ".datastream_class_for_name" do
      it "should return the specifed class" do
        FooAdaptation.datastream_class_for_name('someData').should == ActiveFedora::OmDatastream
      end
      it "should return the specifed class" do
        FooAdaptation.datastream_class_for_name('content').should == ActiveFedora::Datastream
      end
    end

    describe ".internal_uri" do
      it "should return pid as fedors uri" do
        @test_object.internal_uri.should eql("info:fedora/#{@test_object.pid}")
      end
    end

    ### Methods for ActiveModel::Conversions
    it "should have to_param once it's saved" do
      @test_object.to_param.should be_nil
      @test_object.inner_object.stub(new_record?: false, pid: 'foo:123')
      @test_object.to_param.should == 'foo:123'
    end

    it "should have to_key once it's saved" do
      @test_object.to_key.should be_nil
      @test_object.inner_object.stub(new_record?: false, pid: 'foo:123')
      @test_object.to_key.should == ['foo:123']
    end

    it "should have to_model when it's saved" do
      @test_object.to_model.should be @test_object
    end
    ### end ActiveModel::Conversions

    ### Methods for ActiveModel::Naming
    it "Should know the model_name" do
      FooHistory.model_name.should == 'FooHistory'
      FooHistory.model_name.human.should == 'Foo history'
    end
    ### End ActiveModel::Naming


    describe ".datastreams" do
      let(:test_history) { FooHistory.new }
      it "should create accessors for datastreams declared with has_metadata" do
        test_history.withText.should == test_history.datastreams['withText']
      end
      describe "dynamic accessors" do
        before do
          test_history.add_datastream(ds)
          test_history.class.build_datastream_accessor(ds.dsid)
        end
        describe "when the datastream is named with dash" do
          let(:ds) {double('datastream', :dsid=>'eac-cpf')}
          it "should convert dashes to underscores" do
            test_history.eac_cpf.should == ds
          end
        end
        describe "when the datastream is named with underscore" do
          let (:ds) { double('datastream', :dsid=>'foo_bar') }
          it "should preserve the underscore" do
            test_history.foo_bar.should == ds
          end
        end
      end
    end

    it 'should provide #find' do
      ActiveFedora::Base.should respond_to(:find)
    end

    it "should provide .create_date" do
      @test_object.should respond_to(:create_date)
    end

    it "should provide .modified_date" do
      @test_object.should respond_to(:modified_date)
    end

    it 'should respond to .rels_ext' do
      @test_object.should respond_to(:rels_ext)
    end

    describe '.rels_ext' do

      it 'should return the RelsExtDatastream object from the datastreams array' do
        @test_object.stub(:datastreams => {"RELS-EXT" => "foo"})
        @test_object.rels_ext.should == "foo"
      end
    end

    it 'should provide #add_relationship' do
      @test_object.should respond_to(:add_relationship)
    end

    describe '#add_relationship' do
      it 'should call #add_relationship on the rels_ext datastream' do
        @test_object.add_relationship("predicate", "info:fedora/object")
        pred = ActiveFedora::Predicates.vocabularies["info:fedora/fedora-system:def/relations-external#"]["predicate"]
        @test_object.relationships.should have_statement(RDF::Statement.new(RDF::URI.new(@test_object.internal_uri), pred, RDF::URI.new("info:fedora/object")))
      end

      it "should update the RELS-EXT datastream and set the datastream as dirty when relationships are added" do
        mock_ds = double("Rels-Ext")
        mock_ds.stub(:content_will_change!)
        @test_object.datastreams["RELS-EXT"] = mock_ds
        @test_object.add_relationship(:is_member_of, "info:fedora/demo:5")
        @test_object.add_relationship(:is_member_of, "info:fedora/demo:10")
      end

      it 'should add a relationship to an object only if it does not exist already' do
        next_pid = increment_pid.to_s
        ActiveFedora::Base.stub(:assign_pid).and_return(next_pid)
        stub_get(next_pid)

        @test_object3 = ActiveFedora::Base.new
        @test_object.add_relationship(:has_part,@test_object3)
        @test_object.ids_for_outbound(:has_part).should == [@test_object3.pid]
        #try adding again and make sure not there twice
        @test_object.add_relationship(:has_part,@test_object3)
        @test_object.ids_for_outbound(:has_part).should == [@test_object3.pid]
      end

      it 'should add literal relationships if requested' do
        @test_object.add_relationship(:conforms_to,"AnInterface",true)
        @test_object.ids_for_outbound(:conforms_to).should == ["AnInterface"]
      end
    end

    it 'should provide #remove_relationship' do
      @test_object.should respond_to(:remove_relationship)
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
        @test_object.ids_for_outbound(:has_part).should == [@test_object3.pid,@test_object4.pid]
        @test_object.remove_relationship(:has_part,@test_object3)
        #check only one item removed
        @test_object.ids_for_outbound(:has_part).should == [@test_object4.pid]
        @test_object.remove_relationship(:has_part,@test_object4)
        #check last item removed and predicate removed since now emtpy
        @test_object.relationships.size.should == 0
      end
    end

    it 'should provide #relationships' do
      @test_object.should respond_to(:relationships)
    end

    describe '#relationships' do
      it 'should return a graph' do
        @test_object.relationships.kind_of?(RDF::Graph).should be_true
        @test_object.relationships.size.should == 0
      end
    end

    describe '.assert_content_model' do
      it "should default to the name of the class" do
        stub_get(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT'])
        @test_object.assert_content_model
        @test_object.relationships(:has_model).should == ["info:fedora/afmodel:ActiveFedora_Base"]

      end
    end

    describe '.save' do
      it "should create a new record" do
        @test_object.stub(:new_record? => true)
        @test_object.should_receive(:assign_pid)
        @test_object.should_receive(:serialize_datastreams)
        @test_object.inner_object.should_receive(:save)
        @test_object.should_receive(:update_index)
        @test_object.save
      end

      it "should update an existing record" do
        @test_object.stub(:new_record? => false)
        @test_object.should_receive(:serialize_datastreams)
        @test_object.inner_object.should_receive(:save)
        @test_object.should_receive(:update_index)
        @test_object.save
      end
    end

    describe "#create" do
      it "should build a new record and save it" do
        obj = double()
        obj.should_receive(:save)
        FooHistory.should_receive(:new).and_return(obj)
        @hist = FooHistory.create(:fubar=>'ta', :swank=>'da')
      end

    end

    describe ".adapt_to" do
      it "should return an adapted object of the requested type" do
        @test_object = FooHistory.new()
        @test_object.adapt_to(FooAdaptation).class.should == FooAdaptation
      end
      it "should not make an additional call to fedora to create the adapted object" do
        @test_object = FooHistory.new()
        adapted = @test_object.adapt_to(FooAdaptation)
      end
      it "should propagate new datastreams to the adapted object" do
        @test_object = FooHistory.new()
        @test_object.add_file_datastream("XXX", :dsid=>'MY_DSID')
        adapted = @test_object.adapt_to(FooAdaptation)
        adapted.datastreams.keys.should include 'MY_DSID'
        adapted.datastreams['MY_DSID'].content.should == "XXX"
        adapted.datastreams['MY_DSID'].changed?.should be_true
      end
      it "should propagate modified datastreams to the adapted object" do
        @test_object = FooHistory.new()
        orig_ds = @test_object.datastreams['someData']
        orig_ds.content="<YYY/>"
        adapted = @test_object.adapt_to(FooAdaptation)
        adapted.datastreams.keys.should include 'someData'
        adapted.datastreams['someData'].should == orig_ds
        adapted.datastreams['someData'].content.strip.should == "<YYY/>"
        adapted.datastreams['someData'].changed?.should be_true
      end
      it "should use the datastream definitions from the adapted object" do
        @test_object = FooHistory.new()
        adapted = @test_object.adapt_to(FooAdaptation)
        adapted.datastreams.keys.should include 'someData'
        adapted.datastreams['someData'].class.should == ActiveFedora::OmDatastream
      end
    end

    describe ".adapt_to_cmodel with implemented (non-ActiveFedora::Base) cmodel" do
      subject { FooHistory.new }

      it "should not cast to a random first cmodel if it has a specific cmodel already" do
        ActiveFedora::ContentModel.should_receive(:known_models_for).with(subject).and_return([FooAdaptation])
        subject.adapt_to_cmodel.should be_kind_of FooHistory
      end
      it "should cast to an inherited model over a random one" do
        ActiveFedora::ContentModel.should_receive(:known_models_for).with(subject).and_return([FooAdaptation, FooInherited])
        subject.adapt_to_cmodel.should be_kind_of FooInherited
      end
      it "should not cast when a cmodel is same as the class" do
        ActiveFedora::ContentModel.should_receive(:known_models_for).with(subject).and_return([FooHistory])
        subject.adapt_to_cmodel.should === subject
      end
    end

    describe ".adapt_to_cmodel with ActiveFedora::Base" do
      subject { ActiveFedora::Base.new }

      it "should cast to the first cmodel if ActiveFedora::Base (or no specified cmodel)" do
        ActiveFedora::ContentModel.should_receive(:known_models_for).with(subject).and_return([FooAdaptation, FooHistory])
        subject.adapt_to_cmodel.should be_kind_of FooAdaptation
      end
    end


    describe ".to_solr" do
      it "should provide .to_solr" do
        @test_object.should respond_to(:to_solr)
      end

      it "should add pid, system_create_date, system_modified_date and object_state from object attributes" do
        @test_object.should_receive(:create_date).and_return("2012-03-04T03:12:02Z")
        @test_object.should_receive(:modified_date).and_return("2012-03-07T03:12:02Z")
        @test_object.stub(pid: 'changeme:123')
        @test_object.state = "D"
        solr_doc = @test_object.to_solr
        solr_doc[ActiveFedora::SolrService.solr_name("system_create", :stored_sortable, type: :date)].should eql("2012-03-04T03:12:02Z")
        solr_doc[ActiveFedora::SolrService.solr_name("system_modified", :stored_sortable, type: :date)].should eql("2012-03-07T03:12:02Z")
        solr_doc[ActiveFedora::SolrService.solr_name("object_state", :stored_sortable)].should eql("D")
        solr_doc[:id].should eql("changeme:123")
      end

      it "should omit base metadata and RELS-EXT if :model_only==true" do
        @test_object.add_relationship(:has_part, "foo", true)
        solr_doc = @test_object.to_solr(Hash.new, :model_only => true)
        solr_doc[ActiveFedora::SolrService.solr_name("system_create", type: :date)].should be_nil
        solr_doc[ActiveFedora::SolrService.solr_name("system_modified", type: :date)].should be_nil
        solr_doc["id"].should be_nil
        solr_doc[ActiveFedora::SolrService.solr_name("has_part", :symbol)].should be_nil
      end

      it "should add self.class as the :active_fedora_model" do
        stub_get(@this_pid)
        stub_get_content(@this_pid, ['RELS-EXT', 'someData', 'withText2', 'withText'])
        @test_history = FooHistory.new()
        solr_doc = @test_history.to_solr
        solr_doc[ActiveFedora::SolrService.solr_name("active_fedora_model", :stored_sortable)].should eql("FooHistory")
      end

      it "should call .to_solr on all SimpleDatastreams and OmDatastreams, passing the resulting document to solr" do
        mock1 = double("ds1", :to_solr => {})
        mock2 = double("ds2", :to_solr => {})
        ngds = double("ngds", :to_solr => {})
        ngds.should_receive(:solrize_profile)
        mock1.should_receive(:solrize_profile)
        mock2.should_receive(:solrize_profile)

        @test_object.should_receive(:datastreams).twice.and_return({:ds1 => mock1, :ds2 => mock2, :ngds => ngds})
        @test_object.should_receive(:solrize_relationships)
        @test_object.to_solr
      end
      it "should call .to_solr on all RDFDatastreams, passing the resulting document to solr" do
        mock = double("ds1", :to_solr => {})
        mock.should_receive(:solrize_profile)

        @test_object.should_receive(:datastreams).twice.and_return({:ds1 => mock})
        @test_object.should_receive(:solrize_relationships)
        @test_object.to_solr
      end

      it "should call .to_solr on the relationships rels-ext is dirty" do
        @test_object.add_relationship(:has_collection_member, "info:fedora/test:member")
        rels_ext = @test_object.rels_ext
        rels_ext.should be_changed
        @test_object.should_receive(:solrize_relationships)
        @test_object.to_solr
      end

    end

    describe ".label" do
      it "should return the label of the inner object" do
        @test_object.inner_object.should_receive(:label).and_return("foo label")
        @test_object.label.should == "foo label"
      end
    end

    describe ".label=" do
      it "should set the label of the inner object" do
        @test_object.label.should_not == "foo label"
        @test_object.label = "foo label"
        @test_object.label.should == "foo label"
      end
    end
    describe "update_attributes" do
      it "should set the attributes and save" do
        m = FooHistory.new
        att= {"fubar"=> '1234', "baz" =>'stuff'}

        m.should_receive(:fubar=).with('1234')
        m.should_receive(:baz=).with('stuff')
        m.should_receive(:save)
        m.update_attributes(att)
      end
    end

    describe "update" do
      it "should set the attributes and save" do
        m = FooHistory.new
        att= {"fubar"=> '1234', "baz" =>'stuff'}

        m.should_receive(:fubar=).with('1234')
        m.should_receive(:baz=).with('stuff')
        m.should_receive(:save)
        m.update(att)
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

        @test_object.should_receive(:relationships).and_return(graph)
        solr_doc = @test_object.solrize_relationships
        solr_doc[ActiveFedora::SolrService.solr_name("is_member_of", :symbol)].should == "info:fedora/demo:10"
        solr_doc[ActiveFedora::SolrService.solr_name("is_part_of", :symbol)].should == "info:fedora/demo:11"
        solr_doc[ActiveFedora::SolrService.solr_name("has_part", :symbol)].should == "info:fedora/demo:12"
        solr_doc[ActiveFedora::SolrService.solr_name("conforms_to", :symbol)].should == "AnInterface"
      end
    end
  end
end
