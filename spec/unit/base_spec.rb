require 'spec_helper'
@@last_pid = 0  

describe ActiveFedora::Base do
  it_behaves_like "An ActiveModel"

  describe 'descendants' do
    it "should record the decendants" do
      ActiveFedora::Base.descendants.should include(ModsArticle, SpecialThing)
    end
  end

  describe "reindex_everything" do
    it "should call update_index on every object except for the fedora-system objects" do
       # TODO redo these expectations when we reimplement reindex_everything
       # Rubydora::Repository.any_instance.should_receive(:search).
       #      and_yield(double(pid:'XXX')).and_yield(double(pid:'YYY')).and_yield(double(pid:'ZZZ')).
       #      and_yield(double(pid:'fedora-system:ServiceDeployment-3.0')).
       #      and_yield(double(pid:'fedora-system:ServiceDefinition-3.0')).
       #      and_yield(double(pid:'fedora-system:FedoraObject-3.0'))

       mock_update = double(:mock_obj)
       mock_update.should_receive(:update_index).exactly(3).times
       ActiveFedora::Base.should_receive(:find).with('XXX').and_return(mock_update)
       ActiveFedora::Base.should_receive(:find).with('YYY').and_return(mock_update)
       ActiveFedora::Base.should_receive(:find).with('ZZZ').and_return(mock_update)
       ActiveFedora::Base.reindex_everything
    end

    it "should accept a query param for the search" do
       query_string = "pid~*"
       # TODO redo these expectations when we reimplement reindex_everything
       # Rubydora::Repository.any_instance.should_receive(:search).with(query_string).
            # and_yield(double(pid:'XXX')).and_yield(double(pid:'YYY')).and_yield(double(pid:'ZZZ'))
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
        has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"withText2", :autocreate => true do |m|
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
      ActiveFedora::Base.stub(:assign_pid).and_return(@this_pid)

      @test_object = ActiveFedora::Base.new
    end


    describe '#new' do
      it "should not get a pid on init" do
        ActiveFedora::Base.should_receive(:assign_pid).never
        FooHistory.new
      end

      it "should be able to create with a custom pid" do
        f = FooHistory.new('/baz:1')
        f.pid.should == 'baz:1'
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

    ### Methods for ActiveModel::Conversions
    it "should have to_param once it's saved" do
      @test_object.to_param.should be_nil
      @test_object.stub(new_record?: false, pid: 'foo:123')
      @test_object.to_param.should == 'foo:123'
    end

    it "should have to_key once it's saved" do
      @test_object.to_key.should be_nil
      @test_object.stub(new_record?: false, pid: 'foo:123')
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

    describe '.save' do
      it "should create a new record" do
        @test_object.stub(:new_record? => true)
        @test_object.should_receive(:assign_pid)
        @test_object.should_receive(:serialize_datastreams)
        @test_object.should_receive(:create_record)
        @test_object.should_receive(:update_index)
        @test_object.save
      end

      it "should update an existing record" do
        @test_object.stub(:new_record? => false)
        @test_object.should_receive(:serialize_datastreams)
        @test_object..should_receive(:update_record)
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

    describe ".to_solr" do
      it "should provide .to_solr" do
        @test_object.should respond_to(:to_solr)
      end

      it "should add pid, system_create_date, system_modified_date from object attributes" do
        @test_object.should_receive(:create_date).and_return("2012-03-04T03:12:02Z")
        @test_object.should_receive(:modified_date).and_return("2012-03-07T03:12:02Z")
        @test_object.stub(pid: 'changeme:123')
        solr_doc = @test_object.to_solr
        solr_doc[ActiveFedora::SolrService.solr_name("system_create", :stored_sortable, type: :date)].should eql("2012-03-04T03:12:02Z")
        solr_doc[ActiveFedora::SolrService.solr_name("system_modified", :stored_sortable, type: :date)].should eql("2012-03-07T03:12:02Z")
        solr_doc[:id].should eql("changeme:123")
      end

      it "should add self.class as the :active_fedora_model" do
        @test_history = FooHistory.new()
        solr_doc = @test_history.to_solr
        solr_doc[ActiveFedora::SolrService.solr_name("active_fedora_model", :stored_sortable)].should eql("FooHistory")
      end

      it "should call .to_solr on all datastreams, passing the resulting document to solr" do
        mock1 = double("ds1")
        mock1.should_receive(:to_solr).and_return({})
        mock2 = double("ds2")
        mock2.should_receive(:to_solr).and_return({})

        @test_object.stub(datastreams: {:ds1 => mock1, :ds2 => mock2})
        @test_object.should_receive(:solrize_relationships)
        @test_object.to_solr
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
