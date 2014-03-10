require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end
    end
    @model_query = "_query_:\"{!raw f=" + ActiveFedora::SolrService.solr_name("has_model", :symbol) + "}info:fedora/afmodel:SpecModel_Basic" + "\""
    @sort_query = ActiveFedora::SolrService.solr_name("system_create", :stored_sortable, type: :date) + ' asc'
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end

  describe ":all" do
    before { ActiveFedora::Base.stub(:relation => relation) }
    describe "called on a concrete class" do
      let(:relation) { ActiveFedora::Relation.new(SpecModel::Basic) }
      it "should query solr for all objects with :has_model_s of self.class" do
        relation.should_receive(:load_from_fedora).with("changeme:30", nil).and_return("Fake Object1")
        relation.should_receive(:load_from_fedora).with("changeme:22", nil).and_return("Fake Object2")
        mock_docs = [{"id" => "changeme:30"}, {"id" => "changeme:22"}]
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.all.should == ["Fake Object1", "Fake Object2"]
      end
    end
    describe "called without a specific class" do
      let(:relation) { ActiveFedora::Relation.new(ActiveFedora::Base) }
      it "should specify a q parameter" do
        relation.should_receive(:load_from_fedora).with("changeme:30", true).and_return("Fake Object1")
        relation.should_receive(:load_from_fedora).with("changeme:22", true).and_return("Fake Object2")
        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with(1, 1000, 'select', :params=>{:q=>'*:*', :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
        ActiveFedora::Base.all.should == ["Fake Object1", "Fake Object2"]
      end
    end
  end
  
  describe '#find' do
    describe "with :cast false" do
      describe "and a pid is specified" do
        it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
          SpecModel::Basic.any_instance.should_receive(:init_with).and_return(SpecModel::Basic.new )
          ActiveFedora::DigitalObject.should_receive(:find).and_return(double("inner obj", :'new?'=>false))
          SpecModel::Basic.find("_PID_", cast: false).should be_a SpecModel::Basic
        end
        it "should raise an exception if it is not found" do
          Rubydora::Fc3Service.any_instance.should_receive(:object).and_raise(RestClient::ResourceNotFound)
          SpecModel::Basic.should_receive(:connection_for_pid).with("_PID_")
          lambda {SpecModel::Basic.find("_PID_")}.should raise_error ActiveFedora::ObjectNotFoundError
        end
      end
    end
    describe "with default :cast of true" do
      it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
        SpecModel::Basic.any_instance.should_receive(:init_with).and_return(double("Model", :adapt_to_cmodel=>SpecModel::Basic.new ))
        ActiveFedora::DigitalObject.should_receive(:find).and_return(double("inner obj", :'new?'=>false))
        SpecModel::Basic.find("_PID_")
      end
    end

    describe "with conditions" do
      before do
        ActiveFedora::Base.stub(:relation => relation)
        relation.stub(clone: relation)
      end
      let(:relation) { ActiveFedora::Relation.new(SpecModel::Basic) }
      it "should filter by the provided fields" do
        relation.should_receive(:load_from_fedora).with("changeme:30", nil).and_return("Fake Object1")
        relation.should_receive(:load_from_fedora).with("changeme:22", nil).and_return("Fake Object2")

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
            hash[:params][:q].split(" AND ").include?("foo:bar") &&
            hash[:params][:q].split(" AND ").include?("baz:quix") &&
            hash[:params][:q].split(" AND ").include?("baz:quack")
        }.and_return('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']}).should == ["Fake Object1", "Fake Object2"]
      end

      it "should correctly query for empty strings" do
        SpecModel::Basic.find( :active_fedora_model_ssi => '').count.should == 0
      end

      it 'should correctly query for empty arrays' do
        SpecModel::Basic.find( :active_fedora_model_ssi => []).count.should == 0
      end

      it "should add options" do
        relation.should_receive(:load_from_fedora).with("changeme:30", nil).and_return("Fake Object1")
        relation.should_receive(:load_from_fedora).with("changeme:22", nil).and_return("Fake Object2")

        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1000 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:fl] == 'id' && 
            hash[:params][:sort] == [@sort_query] &&
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:bar") &&
            hash[:params][:q].split(" AND ").include?("baz:quix") &&
            hash[:params][:q].split(" AND ").include?("baz:quack")
        }.and_return('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']}, :sort=>'title_t desc').should == ["Fake Object1", "Fake Object2"]
      end
    end
  end


  describe '#find_each' do
    before { ActiveFedora::Base.stub(:relation => relation) }
    let(:relation) { ActiveFedora::Relation.new(SpecModel::Basic) }
    it "should query solr for all objects with :active_fedora_model_s of self.class" do
      mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
      mock_docs.should_receive(:has_next?).and_return(false)
      ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
      
      relation.should_receive(:load_from_fedora).with("changeme:30", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:30'))
      relation.should_receive(:load_from_fedora).with("changeme:22", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:22'))
      yielded = double("yielded method")
      yielded.should_receive(:run).with { |obj| obj.class == SpecModel::Basic}.twice
      SpecModel::Basic.find_each(){|obj| yielded.run(obj) }
    end
    describe "with conditions" do
      it "should filter by the provided fields" do
        relation.should_receive(:load_from_fedora).with("changeme:30", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:30'))
        relation.should_receive(:load_from_fedora).with("changeme:22", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:22'))

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
            hash[:params][:q].split(" AND ").include?("foo:bar") &&
            hash[:params][:q].split(" AND ").include?("baz:quix") &&
            hash[:params][:q].split(" AND ").include?("baz:quack")
        }.and_return('response'=>{'docs'=>mock_docs})
        yielded = double("yielded method")
        yielded.should_receive(:run).with { |obj| obj.class == SpecModel::Basic}.twice
        SpecModel::Basic.find_each({:foo=>'bar', :baz=>['quix','quack']}){|obj| yielded.run(obj) }
      end
    end
  end

  describe '#find_in_batches' do
    describe "with conditions hash" do
      it "should filter by the provided fields" do
        mock_docs = double('docs')
        mock_docs.should_receive(:has_next?).and_return(false)
        ActiveFedora::SolrService.instance.conn.should_receive(:paginate).with() { |page, rows, method, hash|
            page == 1 &&
            rows == 1002 &&
            method == 'select' &&
            hash[:params] &&
            hash[:params][:sort] == [@sort_query] && 
            hash[:params][:fl] == 'id' && 
            hash[:params][:q].split(" AND ").include?(@model_query) &&
            hash[:params][:q].split(" AND ").include?("foo:bar") &&
            hash[:params][:q].split(" AND ").include?("baz:quix") &&
            hash[:params][:q].split(" AND ").include?("baz:quack")
        }.and_return('response'=>{'docs'=>mock_docs})
        yielded = double("yielded method")
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
      ActiveFedora::SolrService.should_receive(:query).with("#{@model_query} AND (foo:bar)", :rows=>0, :raw=>true).and_return(mock_result)
      SpecModel::Basic.count(:conditions=>'foo:bar').should == 7
    end

    it "should count without a class specified" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.should_receive(:query).with("(foo:bar)", :rows=>0, :raw=>true).and_return(mock_result)
      ActiveFedora::Base.count(:conditions=>'foo:bar').should == 7 
    end
  end

  describe '#last' do
    describe 'with multiple objects' do
      before(:all) do
        (@a, @b, @c) = 3.times {SpecModel::Basic.create!}
      end
      it 'should return one object' do
        SpecModel::Basic.class == SpecModel::Basic
      end
      it 'should return the last object sorted by pid' do
        SpecModel::Basic.last == @c
        SpecModel::Basic.last != @a 
      end
    end
    describe 'with one object' do 
      it 'should equal the first object when there is only one' do
        a = SpecModel::Basic.create!
        SpecModel::Basic.first == SpecModel::Basic.last
      end
    end
  end

  describe '#first' do
    describe 'with multiple objects' do
      before(:all) do
        (@a, @b, @c) = 3.times {SpecModel::Basic.create!}
      end
      it 'should return one object' do
        SpecModel::Basic.class == SpecModel::Basic
      end
      it 'should return the last object sorted by pid' do
        SpecModel::Basic.first == @a
        SpecModel::Basic.first != @c 
      end
    end
    describe 'with one object' do 
      it 'should equal the first object when there is only one' do
        a = SpecModel::Basic.create!
        SpecModel::Basic.first == SpecModel::Basic.last
      end
    end
  end
  
  describe '#find_with_conditions' do
    it "should make a query to solr and return the results" do
      mock_result = double('Result')
           ActiveFedora::SolrService.should_receive(:query).with() { |args|
            q = args.first if args.is_a? Array
            q ||= args
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?("foo:bar") &&
            q.split(" AND ").include?("baz:quix") &&
            q.split(" AND ").include?("baz:quack")
        }.and_return(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'bar', :baz=>['quix','quack']).should == mock_result
    end

    it "should escape quotes" do
      mock_result = double('Result')
           ActiveFedora::SolrService.should_receive(:query).with() { |args|
            q = args.first if args.is_a? Array
            q ||= args
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?(@model_query) &&
            q.split(" AND ").include?('foo:9\\"\\ Nails') &&
            q.split(" AND ").include?('baz:7\\"\\ version') &&
            q.split(" AND ").include?('baz:quack')
        }.and_return(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'9" Nails', :baz=>['7" version','quack']).should == mock_result
    end

    it "shouldn't use the class if it's called on AF:Base " do
      mock_result = double('Result')
      ActiveFedora::SolrService.should_receive(:query).with('baz:quack', {:sort => [@sort_query]}).and_return(mock_result)
      ActiveFedora::Base.find_with_conditions(:baz=>'quack').should == mock_result
    end
    it "should use the query string if it's provided and wrap it in parentheses" do
      mock_result = double('Result')
      ActiveFedora::SolrService.should_receive(:query).with('(chunky:monkey)', {:sort => [@sort_query]}).and_return(mock_result)
      ActiveFedora::Base.find_with_conditions('chunky:monkey').should == mock_result
    end
  end
end
