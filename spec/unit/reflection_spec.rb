require 'spec_helper'

describe ActiveFedora::Reflection::AssociationReflection do
  describe "#derive_foreign_key" do
    subject { instance.send :derive_foreign_key }
    let(:name) { 'dummy' }
    let(:options) { { inverse_of: :default_permissions } }
    let(:active_fedora) { instance_double(ActiveFedora::Base) }

    context "when a has_many" do
      let(:instance) { ActiveFedora::Reflection::HasManyReflection.new(name, nil, options, active_fedora) }

      context "and the inverse is a collection association" do
        let(:inverse) { instance_double(ActiveFedora::Reflection::HasAndBelongsToManyReflection, collection?: true) }
        before { allow(instance).to receive(:inverse_of).and_return(inverse) }
        it { is_expected.to eq 'default_permission_ids' }
      end
    end
  end

  describe "#automatic_inverse_of" do
    before do
      class Dummy < ActiveFedora::Base
        belongs_to :foothing, predicate: ::RDF::Vocab::DC.extent
      end
    end

    after { Object.send(:remove_const, :Dummy) }
    subject { instance.send :automatic_inverse_of }
    let(:name) { 'dummy' }
    let(:options) { { as: 'foothing' } }
    let(:active_fedora) { instance_double(ActiveFedora::Base) }

    context "when a has_many" do
      let(:instance) { ActiveFedora::Reflection::HasManyReflection.new(name, nil, options, active_fedora) }

      context "and the inverse is a collection association" do
        it { is_expected.to eq :foothing }
      end
    end
  end
end
