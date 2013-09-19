require 'spec_helper'

describe ActiveFedora::Associations::HasAndBelongsToManyAssociation do
  it "should call add_relationship" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = double(:klass => double.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    ac.should_receive(:callback).twice
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    subject.should_receive(:add_relationship).with('predicate', object)
 
    ac << object

  end

  it "should call add_relationship on subject and object when inverse_of given" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = double(:klass => double.class, :options=>{:property=>'predicate', :inverse_of => 'inverse_predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    ac.should_receive(:callback).twice
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    subject.should_receive(:add_relationship).with('predicate', object)
 
    object.should_receive(:add_relationship).with('inverse_predicate', subject)
 
    ac << object

  end
  
end
