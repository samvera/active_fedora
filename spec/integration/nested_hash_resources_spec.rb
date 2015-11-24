require 'spec_helper'

describe "nested hash resources" do
  before do
    class NestedResource < ActiveTriples::Resource
      property :title, predicate: ::RDF::Vocab::DC.title
      ## Necessary to get AT to create hash URIs.
      def initialize(uri, parent)
        if uri.try(:node?)
          uri = RDF::URI("#nested_#{uri.to_s.gsub('_:', '')}")
        elsif uri.start_with?("#")
          uri = RDF::URI(uri)
        end
        super
      end

      def final_parent
        parent
      end
    end
    class ExampleOwner < ActiveFedora::Base
      property :relation, predicate: ::RDF::Vocab::DC.relation, class_name: NestedResource
      accepts_nested_attributes_for :relation
    end
  end
  after do
    Object.send(:remove_const, :NestedResource)
    Object.send(:remove_const, :ExampleOwner)
  end
  it "is able to nest resources" do
    obj = ExampleOwner.new
    obj.attributes = {
      relation_attributes: [
        {
          title: "Test"
        }
      ]
    }
    obj.save!

    expect(obj.reload.relation.first.title).to eq ["Test"]
  end
end
