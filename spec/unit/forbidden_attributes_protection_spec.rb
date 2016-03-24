require 'spec_helper'

describe ActiveFedora::Attributes, ".new" do
  before(:all) do
    class ProtectedParams < ActiveSupport::HashWithIndifferentAccess
      attr_accessor :permitted
      alias permitted? permitted

      def initialize(attributes)
        super(attributes)
        @permitted = false
      end

      def permit!
        @permitted = true
        self
      end

      def dup
        super.tap do |duplicate|
          duplicate.instance_variable_set :@permitted, @permitted
        end
      end
    end

    class Person < ActiveFedora::Base
      property :first_name, predicate: ::RDF::Vocab::FOAF.firstName, multiple: false
      property :gender, predicate: ::RDF::Vocab::FOAF.gender, multiple: false
    end
  end

  after(:all) do
    Object.send(:remove_const, :ProtectedParams)
    Object.send(:remove_const, :Person)
  end

  context "forbidden attributes" do
    let(:params) { ProtectedParams.new(first_name: 'Guille', gender: 'm') }
    it "cannot be used for mass assignment" do
      expect { Person.new(params) }.to raise_error ActiveModel::ForbiddenAttributesError
    end
  end

  context "permitted attributes" do
    let(:params) { ProtectedParams.new(first_name: 'Guille', gender: 'm').permit! }
    it "can be used for mass assignment" do
      expect { Person.new(params) }.not_to raise_error
    end
  end
end
