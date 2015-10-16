require 'spec_helper'

describe ActiveFedora::FinderMethods do
  let(:object_class) do
    Class.new do
      def self.delegated_attributes
        {}
      end
    end
  end

  let(:finder_class) do
    this = self
    Class.new do
      include ActiveFedora::FinderMethods
      @@klass = this.object_class
      def initialize
        @klass = @@klass
      end
    end
  end

  let(:finder) { finder_class.new }

  describe "#condition_to_clauses" do
    subject { finder.send(:condition_to_clauses, key, value) }
    let(:key) { 'library_id' }

    context "when value is nil" do
      let(:value) { nil }
      it { is_expected.to eq "-library_id:[* TO *]" }
    end

    context "when value is empty string" do
      let(:value) { '' }
      it { is_expected.to eq "-library_id:[* TO *]" }
    end

    context "when value is an id" do
      let(:value) { 'one/two/three' }
      it { is_expected.to eq "_query_:\"{!raw f=library_id}one/two/three\"" }
    end

    context "when value is an array" do
      let(:value) { ['one', 'four'] }
      it { is_expected.to eq "_query_:\"{!raw f=library_id}one\" AND " \
                             "_query_:\"{!raw f=library_id}four\"" }
    end
  end
end
