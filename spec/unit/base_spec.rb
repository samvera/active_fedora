require 'spec_helper'
@@last_pid = 0  

describe ActiveFedora::Base do
  describe "sharding" do
    it "should have a shard_index" do
      ActiveFedora::Base.shard_index(@this_pid).should == 0
    end

    context "When the repository is NOT sharded" do
      subject {ActiveFedora::Base.connection_for_pid('foo:bar')}
      before(:each) do
        ActiveFedora.config.stubs(:sharded?).returns(false)
        ActiveFedora::Base.fedora_connection = {}
        ActiveFedora.config.stubs(:credentials).returns(:url=>'myfedora')
      end
      it { should be_kind_of Rubydora::Repository}
      it "should be the standard connection" do
        subject.client.url.should == 'myfedora'
      end
      describe "assign_pid" do
        after do
          ActiveFedora::RubydoraConnection.unstub(:new)
        end
        it "should use fedora to generate pids" do
          # TODO: This juggling of Fedora credentials & establishing connections should be handled by an establish_fedora_connection method, 
          # possibly wrap it all into a fedora_connection method - MZ 06-05-2012
          stubfedora = mock("Fedora")
          stubfedora.expects(:connection).returns(mock("Connection", :next_pid =>"<pid>sample:newpid</pid>"))
          # Should use ActiveFedora.config.credentials as a single hash rather than an array of shards
          ActiveFedora::RubydoraConnection.expects(:new).with(ActiveFedora.config.credentials).returns(stubfedora)
          ActiveFedora::Base.assign_pid(ActiveFedora::Base.new.inner_object)
        end
      end
      describe "shard_index" do
        it "should always return zero (the first and only connection)" do
          ActiveFedora::Base.shard_index('foo:bar').should == 0
        end
      end
    end
    context "When the repository is sharded" do
      before :each do
        ActiveFedora.config.stubs(:sharded?).returns(true)
        ActiveFedora::Base.fedora_connection = {}
        ActiveFedora.config.stubs(:credentials).returns([{:url=>'shard1'}, {:url=>'shard2'} ])
      end
      describe "assign_pid" do
        it "should always use the first shard to generate pids" do
          stubshard1 = mock("Shard")
          stubshard2 = mock("Shard")
          stubshard1.expects(:connection).returns(mock("Connection", :next_pid =>"<pid>sample:newpid</pid>"))
          stubshard2.expects(:connection).never
          ActiveFedora::Base.fedora_connection = {0 => stubshard1, 1 => stubshard2}
          ActiveFedora::Base.assign_pid(ActiveFedora::Base.new.inner_object)
        end
      end
      describe "shard_index" do
        it "should use modulo of md5 of the pid to distribute objects across shards" do
          ActiveFedora::Base.shard_index('foo:bar').should == 0
          ActiveFedora::Base.shard_index('foo:nanana').should == 1
        end
      end
      describe "the repository" do
        describe "for foo:bar" do
          subject {ActiveFedora::Base.connection_for_pid('foo:bar')}
          it "should be shard1" do
            subject.client.url.should == 'shard1'
          end
        end
        describe "for foo:baz" do
          subject {ActiveFedora::Base.connection_for_pid('foo:nanana')}
          it "should be shard1" do
            subject.client.url.should == 'shard2'
          end
        end
      end
    end

  end

  describe "With a test class" do
    before :all do
      class FooHistory < ActiveFedora::Base
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
          m.field "fubar", :string
          m.field "swank", :text
        end
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText" do |m|
          m.field "fubar", :text
        end
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText2", :label=>"withLabel" do |m|
          m.field "fubar", :text
        end 
        delegate :fubar, :to=>'withText'
        delegate :swank, :to=>'someData'
      end
      class FooAdaptation < ActiveFedora::Base
        has_metadata :type=>ActiveFedora::NokogiriDatastream, :name=>'someData'
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
      Rubydora::Repository.any_instance.stubs(:client).returns(@mock_client)
      ActiveFedora::Base.stubs(:assign_pid).returns(@this_pid)

      @test_object = ActiveFedora::Base.new
    end

    after(:each) do
      begin
      ActiveFedora::SolrService.stubs(:instance)
      #@test_object.delete
      rescue
      end
    end


    describe '#new' do
      it "should create an inner object" do  
        # for doing AFObject.new(params[:foo]) when nothing is in params[:foo]
        Rubydora::DigitalObject.any_instance.expects(:save).never
        result = ActiveFedora::Base.new(nil)  
        result.inner_object.should be_kind_of(ActiveFedora::UnsavedDigitalObject)    
      end

      it "should not save or get an pid on init" do
        Rubydora::DigitalObject.any_instance.expects(:save).never
        ActiveFedora::Base.expects(:assign_pid).never
        f = FooHistory.new
      end

      it "should be able to create with a custom pid" do
        f = FooHistory.new(:pid=>'numbnuts:1')
        f.pid.should == 'numbnuts:1'
      end
    end

    describe ".datastream_class_for_name" do
      it "should return the specifed class" do
        FooAdaptation.datastream_class_for_name('someData').should == ActiveFedora::NokogiriDatastream
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
      @test_object.inner_object.expects(:new?).returns(false).at_least_once
      @test_object.to_param.should == @test_object.pid
    end

    it "should have to_key once it's saved" do 
      @test_object.to_key.should be_nil
      @test_object.inner_object.expects(:new?).returns(false).at_least_once
      @test_object.to_key.should == [@test_object.pid]
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
      before do
        @test_history = FooHistory.new
      end
      it "should create dynamic accessors" do
        @test_history.withText.should == @test_history.datastreams['withText']
      end
      it "dynamic accessors should convert dashes to underscores" do
        ds = stub('datastream', :dsid=>'eac-cpf')
        @test_history.add_datastream(ds)
        @test_history.eac_cpf.should == ds
      end
      it "dynamic accessors should not convert datastreams named with underscore" do
        ds = stub('datastream', :dsid=>'foo_bar')
        @test_history.add_datastream(ds)
        @test_history.foo_bar.should == ds
      end
    end



    describe ".fields" do
      it "should provide fields" do
        @test_object.should respond_to(:fields)
      end
      it "should add pid, system_create_date and system_modified_date from object attributes" do
        cdate = "2008-07-02T05:09:42.015Z"
        mdate = "2009-07-07T23:37:18.991Z"
        @test_object.expects(:create_date).returns(cdate)
        @test_object.expects(:modified_date).returns(mdate)
        fields = @test_object.fields
        fields[:system_create_date][:values].should eql([cdate])
        fields[:system_modified_date][:values].should eql([mdate])
        fields[:id][:values].should eql([@test_object.pid])
      end
      
      it "should add self.class as the :active_fedora_model" do
        fields = @test_object.fields
        fields[:active_fedora_model][:values].should eql([@test_object.class.inspect])
      end
      
      it "should call .fields on all SimpleDatastreams and return the resulting document" do
        mock1 = mock("ds1", :fields => {}, :class=>ActiveFedora::SimpleDatastream)
        mock2 = mock("ds2", :fields => {}, :class=>ActiveFedora::SimpleDatastream)

        @test_object.expects(:datastreams).returns({:ds1 => mock1, :ds2 => mock2})
        @test_object.fields
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
        @test_object.expects(:datastreams).returns({"RELS-EXT" => "foo"}).at_least_once
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
        mock_ds = mock("Rels-Ext")
        mock_ds.expects(:dirty=).with(true).times(2)
        @test_object.datastreams["RELS-EXT"] = mock_ds
        @test_object.add_relationship(:is_member_of, "info:fedora/demo:5")
        @test_object.add_relationship(:is_member_of, "info:fedora/demo:10")
      end
      
      it 'should add a relationship to an object only if it does not exist already' do
        next_pid = increment_pid.to_s
        ActiveFedora::Base.stubs(:assign_pid).returns(next_pid)
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
        @test_object3.stubs(:pid=>'7')
        @test_object4 = ActiveFedora::Base.new()
        @test_object4.stubs(:pid=>'8')
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
      it "should return true and set persisted if object and datastreams all save successfully" do
        stub_get(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT'])
        @test_object.persisted?.should be false
        @test_object.expects(:update_index)
        stub_get(@this_pid, nil, true)
        @test_object.save.should == true
        @test_object.persisted?.should be true
      end

      it "should call assert_content_model" do
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT'])
        @test_object.expects(:assert_content_model)
        @test_object.save.should == true
        
        
      end
      
      it "should call .save on any datastreams that are dirty" do
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['withText2', 'withText', 'RELS-EXT'])
        to = FooHistory.new
        to.expects(:update_index)

        to.datastreams["someData"].stubs(:changed?).returns(true)
        to.datastreams["someData"].stubs(:new_object?).returns(true)
        to.datastreams["someData"].expects(:save)
        to.expects(:refresh)
        FooHistory.expects(:assign_pid).with(to.inner_object).returns(@this_pid)
        to.save
      end
      it "should call .save on any datastreams that are new" do
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['RELS-EXT'])
        ds = ActiveFedora::Datastream.new(@test_object.inner_object, 'ds_to_add')
        ds.content = "DS CONTENT"
        @test_object.add_datastream(ds)
        ds.expects(:save)
        @test_object.instance_variable_set(:@new_object, false)
        @test_object.expects(:refresh)
        @test_object.expects(:update_index)
        @test_object.save
      end
      it "should not call .save on any datastreams that are not dirty" do
        stub_ingest(@this_pid)
        @test_object = FooHistory.new
        @test_object.expects(:update_index)
        @test_object.expects(:refresh)

        @test_object.datastreams["someData"].should_not be_nil
        @test_object.datastreams['someData'].stubs(:changed?).returns(false)
        @test_object.datastreams['someData'].stubs(:new?).returns(false)
        @test_object.datastreams['someData'].expects(:save).never
        @test_object.datastreams['withText2'].expects(:save)
        @test_object.datastreams['withText'].expects(:save)
        @test_object.datastreams['RELS-EXT'].expects(:save)
        FooHistory.expects(:assign_pid).with(@test_object.inner_object).returns(@this_pid)
        @test_object.save
      end
      it "should update solr index with all metadata if any SimpleDatastreams have changed" do
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['ds1', 'RELS-EXT'])

        dirty_ds = ActiveFedora::SimpleDatastream.new(@test_object.inner_object, 'ds1')
        rels_ds = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
        rels_ds.model = @test_object
        @test_object.add_datastream(rels_ds)
        @test_object.add_datastream(dirty_ds)
        @test_object.expects(:update_index)
        
        @test_object.save
      end
      it "should update solr index with all metadata if any RDFDatastreams have changed" do
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['ds1', 'RELS-EXT'])

        dirty_ds = ActiveFedora::NtriplesRDFDatastream.new(@test_object.inner_object, 'ds1')
        rels_ds = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
        rels_ds.model = @test_object
        @test_object.add_datastream(rels_ds)
        @test_object.add_datastream(dirty_ds)
        @test_object.expects(:update_index)
        
        @test_object.save
      end
      it "should NOT update solr index if no SimpleDatastreams have changed" do
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['ds1', 'RELS-EXT'])
        @test_object.save
        @test_object.expects(:new_object?).returns(false).twice
        ActiveFedora::DigitalObject.any_instance.stubs(:save)
        mock1 = mock("ds1")
        mock1.expects( :changed?).returns(false).at_least_once
        mock1.expects(:serialize!)
        mock2 = mock("ds2")
        mock2.expects( :changed?).returns(false).at_least_once
        mock2.expects(:serialize!)
        @test_object.stubs(:datastreams).returns({:ds1 => mock1, :ds2 => mock2})
        @test_object.expects(:update_index).never
        @test_object.expects(:refresh)
        @test_object.instance_variable_set(:@new_object, false)

        @test_object.save
      end
      it "should update solr index if relationships have changed" do
        stub_ingest(@this_pid)

        rels_ext = ActiveFedora::RelsExtDatastream.new(@test_object.inner_object, 'RELS-EXT')
        rels_ext.model = @test_object
        rels_ext.expects(:changed?).returns(true).twice
        rels_ext.expects(:save).returns(true)
        rels_ext.expects(:serialize!)
        clean_ds = mock("ds2", :digital_object=)
        clean_ds.stubs(:dirty? => false, :changed? => false, :new? => false)
        clean_ds.expects(:serialize!)
        @test_object.datastreams["RELS-EXT"] = rels_ext
        @test_object.datastreams[:clean_ds] = clean_ds
  #      @test_object.inner_object.stubs(:datastreams).returns({"RELS-EXT" => rels_ext, :clean_ds => clean_ds})
  #      @test_object.stubs(:datastreams).returns({"RELS-EXT" => rels_ext, :clean_ds => clean_ds})
        @test_object.instance_variable_set(:@new_object, false)
        @test_object.expects(:refresh)
        @test_object.expects(:update_index)
        
        @test_object.save
      end
    end

    describe "#create" do
      before do
        stub_ingest(@this_pid)
        stub_add_ds(@this_pid, ['someData', 'withText', 'withText2', 'RELS-EXT'])
      end
      it "should build a new record and save it" do
        FooHistory.expects(:assign_pid).returns(@this_pid)
        @hist = FooHistory.create(:fubar=>'ta', :swank=>'da')
        @hist.fubar.should == ['ta']
        @hist.swank.should == ['da']
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
        orig_ds.content="YYY"
        adapted = @test_object.adapt_to(FooAdaptation)
        adapted.datastreams.keys.should include 'someData'
        adapted.datastreams['someData'].should == orig_ds
        adapted.datastreams['someData'].content.should == "YYY"
        adapted.datastreams['someData'].changed?.should be_true
      end
      it "should use the datastream definitions from the adapted object" do
        @test_object = FooHistory.new()
        adapted = @test_object.adapt_to(FooAdaptation)
        adapted.datastreams.keys.should include 'someData'
        adapted.datastreams['someData'].class.should == ActiveFedora::NokogiriDatastream
      end
    end

    describe ".adapt_to_cmodel" do
      subject { FooHistory.new } 
      it "should cast when a cmodel is found" do
        ActiveFedora::ContentModel.expects(:known_models_for).with( subject).returns([FooAdaptation])
        subject.adapt_to_cmodel.should be_kind_of FooAdaptation
      end
      it "should not cast when a cmodel is same as the class" do
        ActiveFedora::ContentModel.expects(:known_models_for).with( subject).returns([FooHistory])
        subject.adapt_to_cmodel.should === subject
      end
    end

    describe ".to_xml" do
      it "should provide .to_xml" do
        @test_object.should respond_to(:to_xml)
      end

      it "should add pid, system_create_date and system_modified_date from object attributes" do
        @test_object.expects(:create_date).returns("2012-03-06T03:12:02Z")
        @test_object.expects(:modified_date).returns("2012-03-07T03:12:02Z")
        solr_doc = @test_object.to_solr
        solr_doc["system_create_dt"].should eql("2012-03-06T03:12:02Z")
        solr_doc["system_modified_dt"].should eql("2012-03-07T03:12:02Z")
        solr_doc[:id].should eql("#{@test_object.pid}")
      end

      it "should call .to_xml on all SimpleDatastreams and return the resulting document" do
        ds1 = ActiveFedora::SimpleDatastream.new(@test_object.inner_object, 'ds1')
        ds2 = ActiveFedora::SimpleDatastream.new(@test_object.inner_object, 'ds2')
        [ds1,ds2].each {|ds| ds.expects(:to_xml)}

        @test_object.expects(:datastreams).returns({:ds1 => ds1, :ds2 => ds2})
        @test_object.to_xml
      end
    end
    
    describe ".to_solr" do
      after(:all) do
        # Revert to default mappings after running tests
        ActiveFedora::SolrService.load_mappings
      end
      
      it "should provide .to_solr" do
        @test_object.should respond_to(:to_solr)
      end

      it "should add pid, system_create_date and system_modified_date from object attributes" do
        @test_object.expects(:create_date).returns("2012-03-04T03:12:02Z")
        @test_object.expects(:modified_date).returns("2012-03-07T03:12:02Z")
        solr_doc = @test_object.to_solr
        solr_doc["system_create_dt"].should eql("2012-03-04T03:12:02Z")
        solr_doc["system_modified_dt"].should eql("2012-03-07T03:12:02Z")
        solr_doc[:id].should eql("#{@test_object.pid}")
      end

      it "should omit base metadata and RELS-EXT if :model_only==true" do
        @test_object.add_relationship(:has_part, "foo", true)
        solr_doc = @test_object.to_solr(Hash.new, :model_only => true)
        solr_doc["system_create_dt"].should be_nil
        solr_doc["system_modified_dt"].should be_nil
        solr_doc["id"].should be_nil
        solr_doc["has_part_s"].should be_nil
      end
      
      it "should add self.class as the :active_fedora_model" do
        stub_get(@this_pid)
        stub_get_content(@this_pid, ['RELS-EXT', 'someData', 'withText2', 'withText'])
        @test_history = FooHistory.new()
        solr_doc = @test_history.to_solr
        solr_doc["active_fedora_model_s"].should eql("FooHistory")
      end

      it "should use mappings.yml to decide names of solr fields" do      
        cdate = "2008-07-02T05:09:42Z"
        mdate = "2009-07-07T23:37:18Z"
        @test_object.stubs(:create_date).returns(cdate)
        @test_object.stubs(:modified_date).returns(mdate)
        solr_doc = @test_object.to_solr
        solr_doc["system_create_dt"].should eql(cdate)
        solr_doc["system_modified_dt"].should eql(mdate)
        solr_doc[:id].should eql("#{@test_object.pid}")
        solr_doc["active_fedora_model_s"].should eql(@test_object.class.inspect)
        
        ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
        solr_doc = @test_object.to_solr
        [:system_create_dt, :system_modified_dt, :active_fedora_model_s].each do |fn|
          solr_doc[fn].should == nil
        end
        solr_doc["system_create_date"].should eql(cdate)
        solr_doc["system_modified_date"].should eql(mdate)
        solr_doc[:id].should eql("#{@test_object.pid}")
        solr_doc["active_fedora_model_field"].should eql(@test_object.class.inspect)
      end
      
      it "should call .to_solr on all SimpleDatastreams and NokogiriDatastreams, passing the resulting document to solr" do
        mock1 = mock("ds1", :to_solr)
        mock2 = mock("ds2", :to_solr)
        ngds = mock("ngds", :to_solr)
        ngds.expects(:solrize_profile)
        mock1.expects(:solrize_profile)
        mock2.expects(:solrize_profile)
        
        @test_object.expects(:datastreams).twice.returns({:ds1 => mock1, :ds2 => mock2, :ngds => ngds})
        @test_object.expects(:solrize_relationships)
        @test_object.to_solr
      end
      it "should call .to_solr on all RDFDatastreams, passing the resulting document to solr" do
        mock = mock("ds1", :to_solr)
        mock.expects(:solrize_profile)
        
        @test_object.expects(:datastreams).twice.returns({:ds1 => mock})
        @test_object.expects(:solrize_relationships)
        @test_object.to_solr
      end

      it "should call .to_solr on the relationships rels-ext is dirty" do
        @test_object.add_relationship(:has_collection_member, "info:fedora/foo:member")
        rels_ext = @test_object.rels_ext
        rels_ext.dirty?.should == true
        @test_object.expects(:solrize_relationships)
        @test_object.to_solr
      end
      
    end

    describe ".label" do
      it "should return the label of the inner object" do 
        @test_object.inner_object.expects(:label).returns("foo label")
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
    
    
    describe "get_values_from_datastream" do
      it "should look up the named datastream and call get_values with the given pointer/field_name" do
        mock_ds = mock("Datastream", :get_values=>["value1", "value2"])
        @test_object.stubs(:datastreams).returns({"ds1"=>mock_ds})
        @test_object.get_values_from_datastream("ds1", "--my xpath--").should == ["value1", "value2"]
      end
    end
    
    describe "update_datastream_attributes" do
      it "should look up any datastreams specified as keys in the given hash and call update_attributes on the datastream" do
        mock_desc_metadata = mock("descMetadata")
        mock_properties = mock("properties")
        mock_ds_hash = {'descMetadata'=>mock_desc_metadata, 'properties'=>mock_properties}
        
        ds_values_hash = {
          "descMetadata"=>{ [{:person=>0}, :role]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} },
          "properties"=>{ "notes"=>"foo" }
        }
        m = FooHistory.new
        m.stubs(:datastreams).returns(mock_ds_hash)
        mock_desc_metadata.expects(:update_indexed_attributes).with( ds_values_hash['descMetadata'] )
        mock_properties.expects(:update_indexed_attributes).with( ds_values_hash['properties'] )
        m.update_datastream_attributes( ds_values_hash )
      end
      it "should not do anything and should return an empty hash if the specified datastream does not exist" do
pending "This is broken, and deprecated.  I don't want to fix it - jcoyne"
        ds_values_hash = {
          "nonexistentDatastream"=>{ "notes"=>"foo" }
        }
        m = FooHistory.new
        untouched_xml = m.to_xml
        m.update_datastream_attributes( ds_values_hash ).should == {}
        m.to_xml.should == untouched_xml
      end
    end
    
    describe "update_attributes" do

      it "should set the attributes and save" do
        m = FooHistory.new
        att= {"fubar"=> '1234', "baz" =>'stuff'}
        
        m.expects(:fubar=).with('1234')
        m.expects(:baz=).with('stuff')
        m.expects(:save)
        m.update_attributes(att)
      end
    end
    
    describe "update_indexed_attributes" do
      it "should call .update_indexed_attributes on all metadata datastreams & nokogiri datastreams" do
        m = FooHistory.new
        att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
        
        m.datastreams['someData'].expects(:update_indexed_attributes)
        m.datastreams["withText"].expects(:update_indexed_attributes)
        m.datastreams['withText2'].expects(:update_indexed_attributes)
        m.update_indexed_attributes(att)
      end
      it "should take a :datastreams argument" do 
        att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
        stub_get(@this_pid)
        stub_get_content(@this_pid, ['RELS-EXT', 'someData', 'withText2', 'withText'])
        m = FooHistory.new()
        m.update_indexed_attributes(att, :datastreams=>"withText")
        m.should_not be_nil
        m.datastreams['someData'].fubar.should == []
        m.datastreams["withText"].fubar.should == ['york', 'mangle']
        m.datastreams['withText2'].fubar.should == []
        
        att= {"fubar"=>{"-1"=>"tork", "0"=>"work", "1"=>"bork"}}
        m.update_indexed_attributes(att, :datastreams=>["someData", "withText2"])
        m.should_not be_nil
        m.datastreams['someData'].fubar.should == ['work', 'bork']
        m.datastreams['withText2'].fubar.should == ['work', 'bork']
      end
    end

    describe '#relationships_by_name' do
      
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
        ActiveFedora::Base.stubs(:assign_pid).returns(next_pid)
        stub_get(next_pid)
        @test_object2 = MockNamedRelationships.new
        @test_object2.add_relationship(:has_model, MockNamedRelationships.to_class_uri)
        @test_object.add_relationship(:has_model, ActiveFedora::Base.to_class_uri)
        #should return expected named relationships
        @test_object2.relationships_by_name
        @test_object2.relationships_by_name[:self]["testing"].should == []
        @test_object2.relationships_by_name[:self]["testing2"].should == []
        @test_object2.relationships_by_name[:self]["parts_outbound"].should == []
        @test_object2.add_relationship_by_name("testing",@test_object)
        # @test_object2.relationships_by_name.should == {:self=>{"testing"=>[@test_object.internal_uri],"testing2"=>[],"part_of"=>[], "parts_outbound"=>[@test_object.internal_uri], "collection_members"=>[]}}

        @test_object2.relationships_by_name[:self]["testing"].should == [@test_object.internal_uri]
        @test_object2.relationships_by_name[:self]["testing2"].should == []
        @test_object2.relationships_by_name[:self]["parts_outbound"].should == [@test_object.internal_uri]
      end 
    end

    
    describe '#create_relationship_name_methods' do
      before do
        class MockCreateNamedRelationshipMethodsBase < ActiveFedora::Base
          include ActiveFedora::Relationships
          register_relationship_desc :self, "testing", :is_part_of, :type=>ActiveFedora::Base
          create_relationship_name_methods "testing"
        end
      end
        
      it 'should append and remove using helper methods for each outbound relationship' do
        next_pid = increment_pid.to_s
        ActiveFedora::Base.stubs(:assign_pid).returns(next_pid)
        stub_get(next_pid)
        @test_object2 = MockCreateNamedRelationshipMethodsBase.new 
        @test_object2.should respond_to(:testing_append)
        @test_object2.should respond_to(:testing_remove)
        #test executing each one to make sure code added is correct
        model_pid =ActiveFedora::Base.to_class_uri
        @test_object.add_relationship(:has_model,model_pid)
        @test_object2.add_relationship(:has_model,model_pid)
        @test_object2.testing_append(@test_object)
        #create relationship to access generate_uri method for an object
        @test_object2.relationships_by_name[:self]["testing"].should == [@test_object.internal_uri]
        @test_object2.testing_remove(@test_object)
        @test_object2.relationships_by_name[:self]["testing"].should == []
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

        @test_object.expects(:relationships).returns(graph)
        solr_doc = @test_object.solrize_relationships
        solr_doc["is_member_of_s"].should == ["info:fedora/demo:10"]
        solr_doc["is_part_of_s"].should == ["info:fedora/demo:11"]
        solr_doc["has_part_s"].should == ["info:fedora/demo:12"]
        solr_doc["conforms_to_s"].should == ["AnInterface"]
      end
    end
  end
end
