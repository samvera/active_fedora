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
        ActiveFedora.config.stub(:sharded?).and_return(false)
        ActiveFedora::Base.fedora_connection = {}
        ActiveFedora.config.stub(:credentials).and_return(:url=>'myfedora')
      end
      it { should be_kind_of Rubydora::Repository}
      it "should be the standard connection" do
        subject.client.url.should == 'myfedora'
      end
      describe "assign_pid" do
        it "should use fedora to generate pids" do
          # TODO: This juggling of Fedora credentials & establishing connections should be handled by an establish_fedora_connection method, 
          # possibly wrap it all into a fedora_connection method - MZ 06-05-2012
          stubfedora = mock("Fedora")
          stubfedora.should_receive(:connection).and_return(mock("Connection", :next_pid =>"<pid>sample:newpid</pid>"))
          # Should use ActiveFedora.config.credentials as a single hash rather than an array of shards
          ActiveFedora::RubydoraConnection.should_receive(:new).with(ActiveFedora.config.credentials).and_return(stubfedora)
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
        ActiveFedora.config.stub(:sharded?).and_return(true)
        ActiveFedora::Base.fedora_connection = {}
        ActiveFedora.config.stub(:credentials).and_return([{:url=>'shard1'}, {:url=>'shard2'} ])
      end
      describe "assign_pid" do
        it "should always use the first shard to generate pids" do
          stubhard1 = mock("Shard")
          stubhard2 = mock("Shard")
          stubhard1.should_receive(:connection).and_return(mock("Connection", :next_pid =>"<pid>sample:newpid</pid>"))
          stubhard2.should_receive(:connection).never
          ActiveFedora::Base.fedora_connection = {0 => stubhard1, 1 => stubhard2}
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
      @test_object.inner_object.stub(:new? => false)
      @test_object.to_param.should == @test_object.pid
    end

    it "should have to_key once it's saved" do 
      @test_object.to_key.should be_nil
      @test_object.inner_object.stub(:new? => false)
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
        mock_ds = mock("Rels-Ext")
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
        @test_object.should_receive(:create)
        @test_object.should_receive(:update_index)
        @test_object.save     
      end

      it "should update an existing record" do
        @test_object.stub(:new_record? => false)
        @test_object.should_receive(:update)
        @test_object.should_receive(:update_index)
        @test_object.save     
      end
    end

    describe "#create" do
      it "should build a new record and save it" do
        obj = mock()
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
        adapted.datastreams['someData'].class.should == ActiveFedora::NokogiriDatastream
      end
    end

    describe ".adapt_to_cmodel" do
      subject { FooHistory.new } 
      it "should cast when a cmodel is found" do
        ActiveFedora::ContentModel.should_receive(:known_models_for).with( subject).and_return([FooAdaptation])
        subject.adapt_to_cmodel.should be_kind_of FooAdaptation
      end
      it "should not cast when a cmodel is same as the class" do
        ActiveFedora::ContentModel.should_receive(:known_models_for).with( subject).and_return([FooHistory])
        subject.adapt_to_cmodel.should === subject
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
        @test_object.should_receive(:create_date).and_return("2012-03-04T03:12:02Z")
        @test_object.should_receive(:modified_date).and_return("2012-03-07T03:12:02Z")
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
        @test_object.stub(:create_date).and_return(cdate)
        @test_object.stub(:modified_date).and_return(mdate)
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
        mock1 = mock("ds1", :to_solr => {})
        mock2 = mock("ds2", :to_solr => {})
        ngds = mock("ngds", :to_solr => {})
        ngds.should_receive(:solrize_profile)
        mock1.should_receive(:solrize_profile)
        mock2.should_receive(:solrize_profile)
        
        @test_object.should_receive(:datastreams).twice.and_return({:ds1 => mock1, :ds2 => mock2, :ngds => ngds})
        @test_object.should_receive(:solrize_relationships)
        @test_object.to_solr
      end
      it "should call .to_solr on all RDFDatastreams, passing the resulting document to solr" do
        mock = mock("ds1", :to_solr => {})
        mock.should_receive(:solrize_profile)
        
        @test_object.should_receive(:datastreams).twice.and_return({:ds1 => mock})
        @test_object.should_receive(:solrize_relationships)
        @test_object.to_solr
      end

      it "should call .to_solr on the relationships rels-ext is dirty" do
        @test_object.add_relationship(:has_collection_member, "info:fedora/foo:member")
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
    
    
    describe "get_values_from_datastream" do
      it "should look up the named datastream and call get_values with the given pointer/field_name" do
        mock_ds = mock("Datastream", :get_values=>["value1", "value2"])
        @test_object.stub(:datastreams).and_return({"ds1"=>mock_ds})
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
        m.stub(:datastreams).and_return(mock_ds_hash)
        mock_desc_metadata.should_receive(:update_indexed_attributes).with( ds_values_hash['descMetadata'] )
        mock_properties.should_receive(:update_indexed_attributes).with( ds_values_hash['properties'] )
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
        
        m.should_receive(:fubar=).with('1234')
        m.should_receive(:baz=).with('stuff')
        m.should_receive(:save)
        m.update_attributes(att)
      end
    end
    
    describe "update_indexed_attributes" do
      it "should call .update_indexed_attributes on all metadata datastreams & nokogiri datastreams" do
        m = FooHistory.new
        att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
        
        m.datastreams['someData'].should_receive(:update_indexed_attributes)
        m.datastreams["withText"].should_receive(:update_indexed_attributes)
        m.datastreams['withText2'].should_receive(:update_indexed_attributes)
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
        ActiveFedora::Base.stub(:assign_pid).and_return(next_pid)
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
        ActiveFedora::Base.stub(:assign_pid).and_return(next_pid)
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

        @test_object.should_receive(:relationships).and_return(graph)
        solr_doc = @test_object.solrize_relationships
        solr_doc["is_member_of_s"].should == ["info:fedora/demo:10"]
        solr_doc["is_part_of_s"].should == ["info:fedora/demo:11"]
        solr_doc["has_part_s"].should == ["info:fedora/demo:12"]
        solr_doc["conforms_to_s"].should == ["AnInterface"]
      end
    end
  end
end
