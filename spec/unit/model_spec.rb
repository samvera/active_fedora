require 'spec_helper'

describe ActiveFedora::Model do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end
      class Object < ActiveFedora::Base("http://projecthydra.org/foo/Object")
      end
      class Bar < SpecModel::Object("http://projecthydra.org/bar/Object")
      end
      class Foo < SpecModel::Object
      end
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  describe '.solr_query_handler' do
    subject { SpecModel::Basic.solr_query_handler }
    after do
      # reset to default
      SpecModel::Basic.solr_query_handler = 'standard'
    end

    it { should eq 'standard' }

    context "when setting to something besides the default" do
      before { SpecModel::Basic.solr_query_handler = 'search' }

      it { should eq 'search' }
    end
  end

  describe ".from_class_uri" do
    subject { ActiveFedora::Model.from_class_uri(uri) }
    context "a blank string" do
      before { expect(ActiveFedora::Base.logger).to receive(:warn) }
      let(:uri) { '' }
      it { should be_nil }
    end
    context "a kernel-level class name" do
      let(:uri) { 'String' }
      it { expect(subject).to be(String) }
    end
    context "a qualified class name" do
      context "without inheritance" do
        let(:uri) { 'SpecModel::Basic' }
        it { expect(subject).to be(SpecModel::Basic) }
      end
      context "with inheritance" do
        let(:uri) { 'SpecModel::Foo' }
        it { expect(subject).to be(SpecModel::Foo) }
      end
    end
    context "a uri" do
      let(:uri) { 'http://projecthydra.org/bar/Object' }
      it { expect(subject).to be(SpecModel::Bar) }
    end
    context "a uri for a class with kernel-level homonym" do
      let(:uri) { 'http://projecthydra.org/foo/Object' }
      it { expect(subject).to be(SpecModel::Object) }
    end
  end
end
