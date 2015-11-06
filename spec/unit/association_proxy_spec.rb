require 'spec_helper'

describe ActiveFedora::Associations::AssociationProxy do
  it 'should delegate to_param' do
    skip
    @owner = double(:new_record? => false)
    @assoc = ActiveFedora::Associations::AssociationProxy.new(@owner, @reflection)
    expect(@assoc).to receive(:find_target).and_return(double(:to_param => '1234'))
    @assoc.send(:load_target)
    expect(@assoc.to_param).to eq('1234')
  end
end
