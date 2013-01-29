require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end
    end
    @model_query = ActiveFedora::SolrService.solr_name("has_model", :symbol) + ":#{solr_uri("info:fedora/afmodel:SpecModel_Basic")}"
    @sort_query = ActiveFedora::SolrService.solr_name("system_create", :date, :searchable) + ' asc'
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  describe '#find' do
    describe "without :cast" do
      describe ":all" do
        describe "called on a concrete class" do
          it "should query solr for all objects with :has_model_s of self.class" do
            SpecModel::Basic.should_receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
            SpecModel::Basic.should_receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")
            mock_docs = [{"id" => "changeme:30"}, {"id" => "changeme:22"}]
            mock_docs.should_receive(:has_next?).and_return(false)
            ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
            SpecModel::Basic.find(:all).should == ["Fake Object1", "Fake Object2"]
          end
        end
        describe "called without a specific class" do
          it "should specify a q parameter" do
            ActiveFedora::Base.should_receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
            ActiveFedora::Base.should_receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")
            mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
            mock_docs.should_receive(:has_next?).and_return(false)
            ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with(1, 1000, 'select', :params=>{:q=>'*:*', :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
            ActiveFedora::Base.find(:all).should == ["Fake Object1", "Fake Object2"]
          end
        end
      end
      describe "and a pid is specified" do
        it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
          SpecModel::Basic.any_instance.should_receive(:init_with).and_return(SpecModel::Basic.new)
          ActiveFedora::DigitalObject.should_receive(:find).and_return(stub("inner obj", :'new?'=>false))
          SpecModel::Basic.find("_PID_").should be_a SpecModel::Basic
        end
        it "should raise an exception if it is not found" do
          Rubydora::Repository.any_instance.should_receive(:object).and_raise(RestClient::ResourceNotFound)
          SpecModel::Basic.should_receive(:connection_for_pid).with("_PID_")
          lambda {SpecModel::Basic.find("_PID_")}.should raise_error ActiveFedora::ObjectNotFoundError
        end
      end
    end
    describe "with :cast" do
      it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
        SpecModel::Basic.any_instance.should_receive(:init_with).and_return(mock("Model", :adapt_to_cmodel=>SpecModel::Basic.new ))
        ActiveFedora::DigitalObject.should_receive(:find).and_return(stub("inner obj", :'new?'=>false))
        SpecModel::Basic.find("_PID_", :cast=>true)
      end
    end

    describe "with conditions" do
      it "should filter by the provided fields" do
        SpecModel::Basic.should_receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
        SpecModel::Basic.should_receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")

        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1000 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == [@sort_query] &&
            hash[:params][:fl] == 'id' && 
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:\"bar\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quix\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quack\"")
        }.and_return('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']}).should == ["Fake Object1", "Fake Object2"]
      end

      it "should add options" do
        SpecModel::Basic.should_receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
        SpecModel::Basic.should_receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")

        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1000 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == [@sort_query] &&
            hash[:params][:fl] == 'id' && 
            hash[:params][:sort] == ["system_create_dt asc"] &&
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:\"bar\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quix\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quack\"")
        }.and_return('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']}, :sort=>'title_t desc').should == ["Fake Object1", "Fake Object2"]
      end

    end
  end


  describe '#find_each' do
    it "should query solr for all objects with :active_fedora_model_s of self.class" do
      mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
      mock_docs.should_receive(:has_next?).and_return(false)
      ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
      
      SpecModel::Basic.should_receive(:find_one).with("changeme:30", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:30'))
      SpecModel::Basic.should_receive(:find_one).with("changeme:22", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:22'))
      yielded = mock("yielded method")
      yielded.should_receive(:run).with { |obj| obj.class == SpecModel::Basic}.twice
      SpecModel::Basic.find_each(){|obj| yielded.run(obj) }
    end
    describe "with conditions" do
      it "should filter by the provided fields" do
        SpecModel::Basic.should_receive(:find_one).with("changeme:30", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:30'))
        SpecModel::Basic.should_receive(:find_one).with("changeme:22", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:22'))

        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1000 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == [@sort_query] && 
            hash[:params][:fl] == 'id' && 
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:\"bar\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quix\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quack\"")
        }.and_return('response'=>{'docs'=>mock_docs})
        yielded = mock("yielded method")
        yielded.should_receive(:run).with { |obj| obj.class == SpecModel::Basic}.twice
        SpecModel::Basic.find_each({:foo=>'bar', :baz=>['quix','quack']}){|obj| yielded.run(obj) }
      end
    end
  end

  describe '#find_in_batches' do
    describe "with conditions hash" do
      it "should filter by the provided fields" do
        mock_docs = mock('docs')
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1002 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == [@sort_query] && 
            hash[:params][:fl] == 'id' && 
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:\"bar\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quix\"") &&
            hash[:params][:q].split(" AND ").include?("baz:\"quack\"")
        }.and_return('response'=>{'docs'=>mock_docs})
        yielded = mock("yielded method")
        yielded.should_receive(:run).with(mock_docs)
        SpecModel::Basic.find_in_batches({:foo=>'bar', :baz=>['quix','quack']}, {:batch_size=>1002, :fl=>'id'}){|group| yielded.run group }.should
      end
    end
  end

  describe '#count' do
    
    it "should return a count" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.should_receive(:query).with(@model_query, :rows=>0, :raw=>true).and_return(mock_result)
      SpecModel::Basic.count.should == 7
    end
    it "should allow conditions" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.should_receive(:query).with("#{@model_query} AND foo:bar", :rows=>0, :raw=>true).and_return(mock_result)
      SpecModel::Basic.count(:conditions=>'foo:bar').should == 7
    end

    it "should count without a class specified" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.should_receive(:query).with("foo:bar", :rows=>0, :raw=>true).and_return(mock_result)
      ActiveFedora::Base.count(:conditions=>'foo:bar').should == 7
    end
  end
  
  describe '#find_with_conditions' do
    it "should make a query to solr and return the results" do
      mock_result = stub('Result')
           ActiveFedora::SolrService.should_receive(:query).with() { |args|
            q = args.first if args.is_a? Array
            q ||= args
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?("foo:\"bar\"") &&
            q.split(" AND ").include?("baz:\"quix\"") &&
            q.split(" AND ").include?("baz:\"quack\"")
        }.and_return(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'bar', :baz=>['quix','quack']).should == mock_result
    end

    it "should escape quotes" do
      mock_result = stub('Result')
           ActiveFedora::SolrService.should_receive(:query).with() { |args|
            q = args.first if args.is_a? Array
            q ||= args
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?('foo:"9\\" Nails"') &&
            q.split(" AND ").include?('baz:"7\\" version"') &&
            q.split(" AND ").include?('baz:"quack"')
        }.and_return(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'9" Nails', :baz=>['7" version','quack']).should == mock_result
    end

    it "shouldn't use the class if it's called on AF:Base " do
      mock_result = stub('Result')
      ActiveFedora::SolrService.should_receive(:query).with('baz:"quack"', {:sort => [@sort_query]}).and_return(mock_result)
      ActiveFedora::Base.find_with_conditions(:baz=>'quack').should == mock_result
    end
    it "should use the query string if it's provided" do
      mock_result = stub('Result')
      ActiveFedora::SolrService.should_receive(:query).with('chunky:monkey', {:sort => [@sort_query]}).and_return(mock_result)
      ActiveFedora::Base.find_with_conditions('chunky:monkey').should == mock_result
    end
  end
end
