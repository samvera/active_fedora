require 'spec_helper'

describe ActiveFedora::Reflection::AssociationReflection do
  describe "#derive_foreign_key" do
    let(:name) { 'dummy' }
    let(:options) { { inverse_of: :default_permissions } }
    let(:active_fedora) { double }
    let(:instance) { described_class.new(macro, name, options, active_fedora) }
    subject { instance.send :derive_foreign_key }

    context "when a has_many" do
      let(:macro) { :has_many }

      context "and the inverse is a collection association" do
        let(:inverse) { double(collection?: true) }
        before { allow(instance).to receive(:inverse_of).and_return(inverse) }
        it { is_expected.to eq 'default_permission_ids' }
      end
    end
  end
end
