require 'spec_helper'

describe ActiveFedora::Associations::AssociationProxy do
  it "should delegate to_param" do
  	pending
    @owner = stub(:new_record? => false)
    @assoc = ActiveFedora::Associations::AssociationProxy.new(@owner, @reflection)
    @assoc.should_receive(:find_target).and_return(stub(:to_param => '1234'))
    @assoc.send(:load_target)
    @assoc.to_param.should == '1234'
  
  end

end
