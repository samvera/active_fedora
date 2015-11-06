require 'spec_helper'

describe ActiveFedora::Model do

  before(:each) do
    module ModelIntegrationSpec

      class Base < ActiveFedora::Base
        include ActiveFedora::Model
        def self.pid_namespace
          'foo'
        end
        has_metadata :name => 'properties', :type => ActiveFedora::SimpleDatastream, :autocreate => true
      end
      class Basic < Base
      end
    end

    @test_instance = ModelIntegrationSpec::Basic.new
    @test_instance.save

  end

  after(:each) do
    @test_instance.delete
    Object.send(:remove_const, :ModelIntegrationSpec)
  end

  describe '#find' do
    describe 'with :all' do
      it 'should return an array of instances of the calling Class' do
        result = ModelIntegrationSpec::Basic.find(:all)
        expect(result).to be_instance_of(Array)
        # this test is meaningless if the array length is zero
        expect(result.length).to be > 0
        result.each do |obj|
          expect(obj.class).to eq(ModelIntegrationSpec::Basic)
        end
      end
    end
    describe '#find with a valid pid with cast' do
      subject { ActiveFedora::Base.find(@test_instance.pid, :cast => true) }
      it { is_expected.to be_instance_of ModelIntegrationSpec::Basic}
    end
    describe '#find with a valid pid without cast on Base' do
      subject { ActiveFedora::Base.find(@test_instance.pid) }
      before(:each) do
        expect(Deprecation).to receive(:warn).at_least(1).times
      end
      it { is_expected.to be_instance_of ActiveFedora::Base}
    end
    describe '#find with a valid pid without cast on a model extending Base' do
      subject { ModelIntegrationSpec::Basic.find(@test_instance.pid) }
      before(:each) do
        expect(Deprecation).not_to receive(:warn)
      end
      it { is_expected.to be_instance_of ModelIntegrationSpec::Basic}
    end
  end

  describe '#load_instance_from_solr' do
    describe 'with a valid pid' do
      subject { ActiveFedora::Base.load_instance_from_solr(@test_instance.pid) }
      it { is_expected.to be_instance_of ModelIntegrationSpec::Basic}
    end
    describe 'with metadata datastream spec' do
      subject { ActiveFedora::Base.load_instance_from_solr(@test_instance.pid) }
      it 'should create an xml datastream' do
        expect(subject.datastreams['properties']).to be_kind_of ActiveFedora::SimpleDatastream
      end

      it 'should know the datastreams properties' do
        expect(subject.properties.dsSize).to eq(9)
      end
    end
  end
end
