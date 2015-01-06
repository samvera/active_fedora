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
            expect(SpecModel::Basic).to receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
            expect(SpecModel::Basic).to receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")
            mock_docs = [{"id" => "changeme:30"}, {"id" => "changeme:22"}]
            expect(mock_docs).to receive(:has_next?).and_return(false)
            expect(ActiveFedora::SolrService.instance.conn).to receive(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
            expect(SpecModel::Basic.find(:all)).to eq(["Fake Object1", "Fake Object2"])
          end
        end
        describe "called without a specific class" do
          it "should specify a q parameter" do
            expect(ActiveFedora::Base).to receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
            expect(ActiveFedora::Base).to receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")
            mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
            expect(mock_docs).to receive(:has_next?).and_return(false)
            expect(ActiveFedora::SolrService.instance.conn).to receive(:paginate).with(1, 1000, 'select', :params=>{:q=>'*:*', :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})
            expect(ActiveFedora::Base.find(:all)).to eq(["Fake Object1", "Fake Object2"])
          end
        end
      end
      describe "and a pid is specified" do
        it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
          expect_any_instance_of(SpecModel::Basic).to receive(:init_with).and_return(SpecModel::Basic.new)
          expect(ActiveFedora::DigitalObject).to receive(:find).and_return(double("inner obj", :'new?'=>false))
          expect(SpecModel::Basic.find("_PID_")).to be_a SpecModel::Basic
        end
        it "should raise an exception if it is not found" do
          expect_any_instance_of(Rubydora::Repository).to receive(:object).and_raise(RestClient::ResourceNotFound)
          expect(SpecModel::Basic).to receive(:connection_for_pid).with("_PID_")
          expect {SpecModel::Basic.find("_PID_")}.to raise_error ActiveFedora::ObjectNotFoundError
        end
      end
    end
    describe "with :cast" do
      it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
        expect_any_instance_of(SpecModel::Basic).to receive(:init_with).and_return(double("Model", :adapt_to_cmodel=>SpecModel::Basic.new ))
        expect(ActiveFedora::DigitalObject).to receive(:find).and_return(double("inner obj", :'new?'=>false))
        SpecModel::Basic.find("_PID_", :cast=>true)
      end
    end

    describe "with conditions" do
      it "should filter by the provided fields" do
        expect(SpecModel::Basic).to receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
        expect(SpecModel::Basic).to receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")

        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        expect(mock_docs).to receive(:has_next?).and_return(false)
        allow(ActiveFedora::SolrService.instance.conn).to receive(:paginate) { |page, rows, method, hash|
            expect(page  ).to eq 1
            expect(rows  ).to eq 1000
            expect(method).to eq 'select'
            expect(hash[:params]).to be
            expect(hash[:params][:sort]).to eq [@sort_query]
            expect(hash[:params][:fl]  ).to eq 'id'
            qparts = hash[:params][:q].split(" AND ")
            expect(qparts).to include(@model_query, 'foo:"bar"', 'baz:"quix"', 'baz:"quack"')
        }.and_return('response'=>{'docs'=>mock_docs})
        expect(SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']})).to eq(["Fake Object1", "Fake Object2"])
      end

      it "should add options" do
        expect(SpecModel::Basic).to receive(:find_one).with("changeme:30", nil).and_return("Fake Object1")
        expect(SpecModel::Basic).to receive(:find_one).with("changeme:22", nil).and_return("Fake Object2")

        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        expect(mock_docs).to receive(:has_next?).and_return(false)
        allow(ActiveFedora::SolrService.instance.conn).to receive(:paginate) { |page, rows, method, hash|
            expect(page  ).to eq 1
            expect(rows  ).to eq 1000
            expect(method).to eq 'select'
            expect(hash[:params]).to be
            expect(hash[:params][:sort]).to eq [@sort_query]
            expect(hash[:params][:fl]  ).to eq 'id'
            qparts = hash[:params][:q].split(" AND ")
            expect(qparts).to include(@model_query, 'foo:"bar"', 'baz:"quix"', 'baz:"quack"')
        }.and_return('response'=>{'docs'=>mock_docs})
        expect(SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']}, :sort=>'title_t desc')).to eq(["Fake Object1", "Fake Object2"])
      end

    end
  end


  describe '#find_each' do
    it "should query solr for all objects with :active_fedora_model_s of self.class" do
      mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
      expect(mock_docs).to receive(:has_next?).and_return(false)
      expect(ActiveFedora::SolrService.instance.conn).to receive(:paginate).with(1, 1000, 'select', :params=>{:q=>@model_query, :qt => 'standard', :sort => [@sort_query], :fl=> 'id', }).and_return('response'=>{'docs'=>mock_docs})

      expect(SpecModel::Basic).to receive(:find_one).with("changeme:30", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:30'))
      expect(SpecModel::Basic).to receive(:find_one).with("changeme:22", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:22'))
      yielded = double("yielded method")
      allow(yielded).to receive(:run) { |obj| obj.class == SpecModel::Basic}.twice
      SpecModel::Basic.find_each(){|obj| yielded.run(obj) }
    end
    describe "with conditions" do
      it "should filter by the provided fields" do
        expect(SpecModel::Basic).to receive(:find_one).with("changeme:30", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:30'))
        expect(SpecModel::Basic).to receive(:find_one).with("changeme:22", nil).and_return(SpecModel::Basic.new(:pid=>'changeme:22'))

        mock_docs = [{"id" => "changeme:30"},{"id" => "changeme:22"}]
        expect(mock_docs).to receive(:has_next?).and_return(false)
        allow(ActiveFedora::SolrService.instance.conn).to receive(:paginate) { |page, rows, method, hash|
            expect(page).to eq 1
            expect(rows).to eq 1000
            expect(method).to eq 'select'
            expect(hash[:params]).to be
            expect(hash[:params][:sort]).to eq [@sort_query]
            expect(hash[:params][:sort]).to eq ["system_create_dt asc"]
            expect(hash[:params][:fl]).to eq 'id'
            qparts = hash[:params][:q].split(" AND ")
            expect(qparts).to include(@model_query, 'foo:"bar"', 'baz:"quix"', 'baz:"quack"')
        }.and_return('response'=>{'docs'=>mock_docs})
        yielded = double("yielded method")
        allow(yielded).to receive(:run) { |obj| obj.class == SpecModel::Basic}.twice
        SpecModel::Basic.find_each({:foo=>'bar', :baz=>['quix','quack']}){|obj| yielded.run(obj) }
      end
    end
  end

  describe '#find_in_batches' do
    describe "with conditions hash" do
      it "should filter by the provided fields" do
        mock_docs = double('docs')
        expect(mock_docs).to receive(:has_next?).and_return(false)
        allow(ActiveFedora::SolrService.instance.conn).to receive(:paginate) { |page, rows, method, hash|
            expect(page).to eq 1
            expect(rows).to eq 1002
            expect(method).to eq 'select'
            expect(hash[:params]).to be
            expect(hash[:params][:sort]).to eq [@sort_query]
            expect(hash[:params][:sort]).to eq ["system_create_dt asc"]
            expect(hash[:params][:fl]).to eq 'id'
            qparts = hash[:params][:q].split(" AND ")
            expect(qparts).to include(@model_query, 'foo:"bar"', 'baz:"quix"', 'baz:"quack"')
        }.and_return('response'=>{'docs'=>mock_docs})
        yielded = double("yielded method")
        expect(yielded).to receive(:run).with(mock_docs)
        SpecModel::Basic.find_in_batches({:foo=>'bar', :baz=>['quix','quack']}, {:batch_size=>1002, :fl=>'id'}){|group| yielded.run group }
      end
    end
  end

  describe '#count' do
    it "should return a count" do
      mock_result = {'response'=>{'numFound'=>7}}
      expect(ActiveFedora::SolrService).to receive(:query).with(@model_query, :rows=>0, :raw=>true).and_return(mock_result)
      expect(SpecModel::Basic.count).to eq(7)
    end
    it "should allow conditions" do
      mock_result = {'response'=>{'numFound'=>7}}
      expect(ActiveFedora::SolrService).to receive(:query).with("#{@model_query} AND foo:bar", :rows=>0, :raw=>true).and_return(mock_result)
      expect(SpecModel::Basic.count(:conditions=>'foo:bar')).to eq(7)
    end
    it "should count without a class specified" do
      mock_result = {'response'=>{'numFound'=>7}}
      expect(ActiveFedora::SolrService).to receive(:query).with("foo:bar", :rows=>0, :raw=>true).and_return(mock_result)
      expect(ActiveFedora::Base.count(:conditions=>'foo:bar')).to eq(7)
    end
  end

  describe '#find_with_conditions' do
    it "should make a query to solr and return the results" do
      mock_result = double('Result')
      allow(ActiveFedora::SolrService).to receive(:query) { |args|
        q = args.is_a?(Array) ? args.first : args
        expect(q).to include(@model_query, 'foo:"bar"', 'baz:"quix"', 'baz:"quack"')
      }.and_return(mock_result)
      expect(SpecModel::Basic.find_with_conditions(:foo=>'bar', :baz=>['quix','quack'])).to eq(mock_result)
    end

    it "should escape quotes" do
      mock_result = double('Result')
      allow(ActiveFedora::SolrService).to receive(:query) { |args|
        q = args.is_a?(Array) ? args.first : args
        expect(q.split(" AND ")).to include(@model_query, 'foo:"9\\" Nails"', 'baz:"7\\" version"', 'baz:"quack"')
      }.and_return(mock_result)
      expect(SpecModel::Basic.find_with_conditions(:foo=>'9" Nails', :baz=>['7" version','quack'])).to eq(mock_result)
    end

    it "shouldn't use the class if it's called on AF:Base" do
      mock_result = double('Result')
      expect(ActiveFedora::SolrService).to receive(:query).with('baz:"quack"', {:sort => [@sort_query]}).and_return(mock_result)
      expect(ActiveFedora::Base.find_with_conditions(:baz=>'quack')).to eq(mock_result)
    end
    it "should use the query string if it's provided" do
      mock_result = double('Result')
      expect(ActiveFedora::SolrService).to receive(:query).with('chunky:monkey', {:sort => [@sort_query]}).and_return(mock_result)
      expect(ActiveFedora::Base.find_with_conditions('chunky:monkey')).to eq(mock_result)
    end
  end
end
