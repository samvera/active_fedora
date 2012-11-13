require 'spec_helper'

describe ActiveFedora::Model do
  
  before(:all) do
    module SpecModel
      class Basic
        include ActiveFedora::Model
        def initialize (args = {})
        end
      end
    end
    @model_query = "has_model_s:#{solr_uri("info:fedora/afmodel:SpecModel_Basic")}"
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  describe '.solr_query_handler' do
    after do
      # reset to default
      SpecModel::Basic.solr_query_handler = 'standard'
    end
    it "should have a default" do
      SpecModel::Basic.solr_query_handler.should == 'standard'
    end
    it "should be settable" do
      SpecModel::Basic.solr_query_handler = 'search'
      SpecModel::Basic.solr_query_handler.should == 'search'
    end
  end
  
  describe '#find' do
    describe "without :cast" do
      describe ":all" do
        describe "called on a concrete class" do
          it "should query solr for all objects with :has_model_s of self.class" do
            SpecModel::Basic.expects(:find_one).with("changeme:30", nil).returns("Fake Object1")
            SpecModel::Basic.expects(:find_one).with("changeme:22", nil).returns("Fake Object2")
            mock_docs = mock('docs')
            mock_docs.expects(:each).multiple_yields([{"id" => "changeme:30"}],[{"id" => "changeme:22"}])
            mock_docs.expects(:has_next?).returns(false)
            ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
            SpecModel::Basic.find(:all).should == ["Fake Object1", "Fake Object2"]
          end
        end
        describe "called without a specific class" do
          it "should specify a q parameter" do
            ActiveFedora::Base.expects(:find_one).with("changeme:30", nil).returns("Fake Object1")
            ActiveFedora::Base.expects(:find_one).with("changeme:22", nil).returns("Fake Object2")
            mock_docs = mock('docs')
            mock_docs.expects(:each).multiple_yields([{"id" => "changeme:30"}],[{"id" => "changeme:22"}])
            mock_docs.expects(:has_next?).returns(false)
            ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1000, 'select', :params=>{:q=>'*:*', :qt => 'standard', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
            ActiveFedora::Base.find(:all).should == ["Fake Object1", "Fake Object2"]
          end
        end
      end
      describe "and a pid is specified" do
        it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
          SpecModel::Basic.any_instance.expects(:init_with).returns(SpecModel::Basic.new)
          ActiveFedora::DigitalObject.expects(:find).returns(stub("inner obj", :'new?'=>false))
          SpecModel::Basic.find("_PID_").should be_a SpecModel::Basic
        end
        it "should raise an exception if it is not found" do
          Rubydora::Repository.any_instance.expects(:object).raises(RestClient::ResourceNotFound)
          SpecModel::Basic.expects(:connection_for_pid).with("_PID_")
          lambda {SpecModel::Basic.find("_PID_")}.should raise_error ActiveFedora::ObjectNotFoundError
        end
      end
    end
    describe "with :cast" do
      it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
        SpecModel::Basic.any_instance.expects(:init_with).returns(mock("Model", :adapt_to_cmodel=>SpecModel::Basic.new ))
        ActiveFedora::DigitalObject.expects(:find).returns(stub("inner obj", :'new?'=>false))
        SpecModel::Basic.find("_PID_", :cast=>true)
      end
    end

    describe "with conditions" do
      it "should filter by the provided fields" do
        SpecModel::Basic.expects(:find_one).with("changeme:30", nil).returns("Fake Object1")
        SpecModel::Basic.expects(:find_one).with("changeme:22", nil).returns("Fake Object2")

        mock_docs = mock('docs')
        mock_docs.expects(:each).multiple_yields([{"id" => "changeme:30"}],[{"id" => "changeme:22"}])
        mock_docs.expects(:has_next?).returns(false)
        ActiveFedora::SolrService.instance.conn.expects(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1000 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == ['system_create_dt asc'] &&
            hash[:params][:fl] == 'id' && 
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:\"bar\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quix\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quack\"")
        }.returns('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']}).should == ["Fake Object1", "Fake Object2"]
      end
    end
  end

  describe '#all' do
    it "should pass everything through to .find" do
      SpecModel::Basic.expects(:find).with(:all, {})
      SpecModel::Basic.all
    end
  end

  describe '#find_each' do
    it "should query solr for all objects with :active_fedora_model_s of self.class" do
      mock_docs = mock('docs')
      mock_docs.expects(:each).multiple_yields([{"id" => "changeme:30"}],[{"id" => "changeme:22"}])
      mock_docs.expects(:has_next?).returns(false)
      ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
      
      SpecModel::Basic.expects(:find_one).with("changeme:30", nil).returns(SpecModel::Basic.new(:pid=>'changeme:30'))
      SpecModel::Basic.expects(:find_one).with("changeme:22", nil).returns(SpecModel::Basic.new(:pid=>'changeme:22'))
      yielded = mock("yielded method")
      yielded.expects(:run).with { |obj| obj.class == SpecModel::Basic}.twice
      SpecModel::Basic.find_each(){|obj| yielded.run(obj) }
    end
    describe "with conditions" do
      it "should filter by the provided fields" do
        SpecModel::Basic.expects(:find_one).with("changeme:30", nil).returns(SpecModel::Basic.new(:pid=>'changeme:30'))
        SpecModel::Basic.expects(:find_one).with("changeme:22", nil).returns(SpecModel::Basic.new(:pid=>'changeme:22'))

        mock_docs = mock('docs')
        mock_docs.expects(:each).multiple_yields([{"id" => "changeme:30"}],[{"id" => "changeme:22"}])
        mock_docs.expects(:has_next?).returns(false)
        ActiveFedora::SolrService.instance.conn.expects(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1000 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == ['system_create_dt asc'] && 
            hash[:params][:fl] == 'id' && 
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:\"bar\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quix\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quack\"")
        }.returns('response'=>{'docs'=>mock_docs})
        yielded = mock("yielded method")
        yielded.expects(:run).with { |obj| obj.class == SpecModel::Basic}.twice
        SpecModel::Basic.find_each({:foo=>'bar', :baz=>['quix','quack']}){|obj| yielded.run(obj) }
      end
    end
  end

  describe '#find_in_batches' do
    describe "with conditions hash" do
      it "should filter by the provided fields" do
        mock_docs = mock('docs')
        mock_docs.expects(:has_next?).returns(false)
        ActiveFedora::SolrService.instance.conn.expects(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1002 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == ['system_create_dt asc'] && 
            hash[:params][:fl] == 'id' && 
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:\"bar\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quix\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quack\"")
        }.returns('response'=>{'docs'=>mock_docs})
        yielded = mock("yielded method")
        yielded.expects(:run).with(mock_docs)
        SpecModel::Basic.find_in_batches({:foo=>'bar', :baz=>['quix','quack']}, {:batch_size=>1002, :fl=>'id'}){|group| yielded.run group }.should
      end
    end
  end

  describe '#count' do
    
    it "should return a count" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.expects(:query).with(@model_query, :rows=>0, :raw=>true).returns(mock_result)
      SpecModel::Basic.count.should == 7
    end
    it "should allow conditions" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.expects(:query).with("#{@model_query} AND foo:bar", :rows=>0, :raw=>true).returns(mock_result)
      SpecModel::Basic.count(:conditions=>'foo:bar').should == 7
    end

    it "should count without a class specified" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.expects(:query).with("foo:bar", :rows=>0, :raw=>true).returns(mock_result)
      ActiveFedora::Base.count(:conditions=>'foo:bar').should == 7
    end
  end
  
  describe '#find_with_conditions' do
    it "should make a query to solr and return the results" do
      mock_result = stub('Result')
           ActiveFedora::SolrService.expects(:query).with() { |args|
            q = args.first if args.is_a? Array
            q ||= args
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?("foo:\"bar\"") &&
            q.split(" AND ").include?("baz:\"quix\"") &&
            q.split(" AND ").include?("baz:\"quack\"")
        }.returns(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'bar', :baz=>['quix','quack']).should == mock_result
    end

    it "should escape quotes" do
      mock_result = stub('Result')
           ActiveFedora::SolrService.expects(:query).with() { |args|
            q = args.first if args.is_a? Array
            q ||= args
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?('foo:"9\\" Nails"') &&
            q.split(" AND ").include?('baz:"7\\" version"') &&
            q.split(" AND ").include?('baz:"quack"')
        }.returns(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'9" Nails', :baz=>['7" version','quack']).should == mock_result
    end

    it "shouldn't use the class if it's called on AF:Base " do
      mock_result = stub('Result')
      ActiveFedora::SolrService.expects(:query).with('baz:"quack"', {:sort => ['system_create_dt asc']}).returns(mock_result)
      ActiveFedora::Base.find_with_conditions(:baz=>'quack').should == mock_result
    end
    it "should use the query string if it's provided" do
      mock_result = stub('Result')
      ActiveFedora::SolrService.expects(:query).with('chunky:monkey', {:sort => ['system_create_dt asc']}).returns(mock_result)
      ActiveFedora::Base.find_with_conditions('chunky:monkey').should == mock_result
    end
  end
  
  describe "URI translation" do
    before :all do
      module SpecModel
        class CamelCased
          include ActiveFedora::Model
        end
      end

    end
    
    after :all do
      SpecModel.send(:remove_const, :CamelCased)
    end
    subject {SpecModel::CamelCased}
    
    its(:to_class_uri) {should == 'info:fedora/afmodel:SpecModel_CamelCased' }
  
    context "with the namespace declared in the model" do
      before do
        subject.stubs(:pid_namespace).returns("test-cModel")
      end
      its(:to_class_uri) {should == 'info:fedora/test-cModel:SpecModel_CamelCased' }
    end
    context "with the suffix declared in the model" do
      before do
        subject.stubs(:pid_suffix).returns("-TEST-SUFFIX")
      end
      its(:to_class_uri) {should == 'info:fedora/afmodel:SpecModel_CamelCased-TEST-SUFFIX' }
    end
  
    describe ".classname_from_uri" do 
      it "should turn an afmodel URI into a Model class name" do
        ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:SpecModel_CamelCased').should == ['SpecModel::CamelCased', 'afmodel']
      end
      it "should not change plurality" do
        ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:MyMetadata').should == ['MyMetadata', 'afmodel']
      end
      it "should capitalize the first letter" do
        ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:image').should == ['Image', 'afmodel']
      end
    end
  end
  
end
