require 'spec_helper'

describe ActiveFedora::Associations::HasManyAssociation do
  it "should be able to replace the collection" do
    @owner = stub(:new_record? => false)
    @reflection = stub(:klass => Mocha::Mock, :options=>{:property=>'predicate'})
    #ac = ActiveFedora::Associations::AssociationCollection.new(@owner, @reflection)
    ac = ActiveFedora::Associations::HasManyAssociation.new(@owner, @reflection)
    @target = [stub(:new_record? => false, :remove_relationship=>true), stub(:new_record? => false, :remove_relationship=>true), stub(:new_record? => false, :remove_relationship=>true)]
    ac.target = @target 

    @expected1 = stub(:new_record? => false, :add_relationship=>true, :save=>true)
    @expected2 = stub(:new_record? => false, :add_relationship=>true, :save=>true)
    ac.replace([@expected1, @expected2])
    ac.target.should == [@expected1, @expected2]

  end

end
