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
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  
  describe '#find' do
    describe "without :cast" do
      it "(:all) should query solr for all objects with :active_fedora_model_s of self.class" do
        SpecModel::Basic.expects(:find_one).with("changeme:30", nil).returns("Fake Object1")
        SpecModel::Basic.expects(:find_one).with("changeme:22", nil).returns("Fake Object2")
        mock_docs = mock('docs')
        mock_docs.expects(:each).multiple_yields([{"id" => "changeme:30"}],[{"id" => "changeme:22"}])
        mock_docs.expects(:has_next?).returns(false)
        ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1000, 'select', :params=>{:q=>'has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.find(:all).should == ["Fake Object1", "Fake Object2"]
      end
      it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
        SpecModel::Basic.any_instance.expects(:init_with).returns(SpecModel::Basic.new)
        ActiveFedora::DigitalObject.expects(:find).returns(stub("inner obj", :'new?'=>false))
        SpecModel::Basic.find("_PID_").should be_a SpecModel::Basic
      end
      it "should raise an exception if it is not found" do
        SpecModel::Basic.expects(:connection_for_pid).with("_PID_")
        lambda {SpecModel::Basic.find("_PID_")}.should raise_error ActiveFedora::ObjectNotFoundError
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
        ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1000, 'select', :params=>{:q=>'has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic AND foo:"bar" AND baz:"quix" AND baz:"quack"', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
        SpecModel::Basic.find({:foo=>'bar', :baz=>['quix','quack']}).should == ["Fake Object1", "Fake Object2"]
      end
    end
  end

  describe '#find_each' do
    it "should query solr for all objects with :active_fedora_model_s of self.class" do
      mock_docs = mock('docs')
      mock_docs.expects(:each).multiple_yields([{"id" => "changeme:30"}],[{"id" => "changeme:22"}])
      mock_docs.expects(:has_next?).returns(false)
      ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1000, 'select', :params=>{:q=>'has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
      
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
        ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1000, 'select', :params=>{:q=>'has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic AND foo:"bar" AND baz:"quix" AND baz:"quack"', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
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
        ActiveFedora::SolrService.instance.conn.expects(:paginate).with(1, 1002, 'select', :params=>{:q=>'has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic AND foo:"bar" AND baz:"quix" AND baz:"quack"', :sort => ['system_create_dt asc'], :fl=> 'id', }).returns('response'=>{'docs'=>mock_docs})
        yielded = mock("yielded method")
        yielded.expects(:run).with(mock_docs)
        SpecModel::Basic.find_in_batches({:foo=>'bar', :baz=>['quix','quack']}, {:batch_size=>1002, :fl=>'id'}){|group| yielded.run group }.should
      end
    end
  end

  describe '#count' do
    
    it "should return a count" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.expects(:query).with('has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic', :rows=>0, :raw=>true).returns(mock_result)
      SpecModel::Basic.count.should == 7
    end
    it "should allow conditions" do
      mock_result = {'response'=>{'numFound'=>7}}
      ActiveFedora::SolrService.expects(:query).with('has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic AND foo:bar', :rows=>0, :raw=>true).returns(mock_result)
      SpecModel::Basic.count(:conditions=>'foo:bar').should == 7
    end
  end
  
  describe '#find_by_solr' do
    it "(:all) should query solr for all objects with :active_fedora_model_s of self.class and return a Solr result" do
      mock_response = mock("SolrResponse")
      ActiveFedora::SolrService.expects(:query).with('active_fedora_model_s:SpecModel\:\:Basic', {}).returns(mock_response)
    
      SpecModel::Basic.find_by_solr(:all).should equal(mock_response)
    end
    it "(String) should query solr for an object with the given id and return the Solr Result" do
      mock_response = mock("SolrResponse")
      ActiveFedora::SolrService.expects(:query).with('id:changeme\:30', {}).returns(mock_response)
    
      SpecModel::Basic.find_by_solr("changeme:30").should equal(mock_response)
    end
  end

  describe '#find_with_conditions' do
    it "should make a query to solr and return the results" do
      mock_result = stub('Result')
      ActiveFedora::SolrService.expects(:query).with('has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic AND foo:"bar" AND baz:"quix" AND baz:"quack"', {:sort => ['system_create_dt asc']}).returns(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'bar', :baz=>['quix','quack']).should == mock_result
      
    end
    it "should escape quotes" do
      mock_result = stub('Result')
      ActiveFedora::SolrService.expects(:query).with('has_model_s:info\\:fedora/afmodel\\:SpecModel_Basic AND foo:"9\\" Nails" AND baz:"7\\" version" AND baz:"quack"', {:sort => ['system_create_dt asc']}).returns(mock_result)
      SpecModel::Basic.find_with_conditions(:foo=>'9" Nails', :baz=>['7" version','quack']).should == mock_result
      
    end
  end
  
  describe "load_instance" do
    it "should use SpecModel::Basic.allocate.init_with to instantiate an object" do
      ActiveSupport::Deprecation.expects(:warn).with("load_instance is deprecated.  Use find instead")
      SpecModel::Basic.expects(:find).with("_PID_")
      SpecModel::Basic.load_instance("_PID_")
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
