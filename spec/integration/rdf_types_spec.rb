require 'spec_helper'

describe ActiveFedora::Base do
  let(:type1) { ::RDF::URI("http://my.types.com/TypeOne") }
  let(:type2) { ::RDF::URI("http://my.types.com/TypeTwo") }

  before(:all) do
    class TypedSample < ActiveFedora::Base
      type [::RDF::URI("http://my.types.com/TypeOne")]
    end
  end

  after(:all) do
    Object.send(:remove_const, :TypedSample)
  end

  let(:sample) { TypedSample.new }

  subject { sample }

  context "before saving" do
    its(:type) { is_expected.to include(type1) }
  end

  context "after saving" do
    before do
      sample.save
      sample.reload
    end
    its(:type) { is_expected.to include(type1) }
  end

  context "when adding additional types after save" do
    before do
      sample.save
      sample.type << type2
    end
    its(:type) { is_expected.to include(type1, type2) }

    context "and then reloading" do
      before do
        sample.save
        sample.reload
      end
      its(:type) { is_expected.to include(type1, type2) }
    end
  end

  context "adding additional types at creation" do
    before do
      sample.type << type2
      sample.save
    end
    its(:type) { is_expected.to include(type1, type2) }
  end
end
