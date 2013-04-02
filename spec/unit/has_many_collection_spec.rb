require 'spec_helper'

describe ActiveFedora::Associations::HasManyAssociation do
  it "should call add_relationship" do
    subject = stub("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = stub(:klass => mock.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasManyAssociation.new(subject, predicate)
    object = stub("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    object.should_receive(:add_relationship).with('predicate', subject)
 
    ac << object

  end
  
  it "should call remove_relationship" do
    subject = stub("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = stub(:klass => mock.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasManyAssociation.new(subject, predicate)
    object = stub("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    object.should_receive(:remove_relationship).with('predicate', subject)
 
    ac.delete(object)

  end

  it "should be able to replace the collection" do
    @owner = stub(:new_record? => false, :to_ary => nil, :internal_uri => 'info:fedora/changeme:99')
    @reflection = stub(:klass => mock.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ac = ActiveFedora::Associations::HasManyAssociation.new(@owner, @reflection)
    @target = [stub(:to_ary => nil, :new_record? => false, :remove_relationship=>true), stub(:to_ary => nil, :new_record? => false, :remove_relationship=>true), stub(:to_ary => nil, :new_record? => false, :remove_relationship=>true)]
    ac.target = @target 

    @expected1 = stub(:new_record? => false, :add_relationship=>true, :save=>true, :to_ary => nil)
    @expected2 = stub(:new_record? => false, :add_relationship=>true, :save=>true, :to_ary => nil)
    ac.replace([@expected1, @expected2])
    ac.target.should == [@expected1, @expected2]

  end


end
