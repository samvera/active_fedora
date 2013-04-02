require 'spec_helper'

describe ActiveFedora::Associations::HasAndBelongsToManyAssociation do
  it "should call add_relationship" do
    subject = stub("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = stub(:klass => mock.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = stub("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    subject.should_receive(:add_relationship).with('predicate', object)
 
    ac << object

  end

  it "should call add_relationship on subject and object when inverse_of given" do
    subject = stub("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = stub(:klass => mock.class, :options=>{:property=>'predicate', :inverse_of => 'inverse_predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = stub("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    subject.should_receive(:add_relationship).with('predicate', object)
 
    object.should_receive(:add_relationship).with('inverse_predicate', subject)
 
    ac << object

  end
  
  it "should call remove_relationship" do
    subject = stub("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = stub(:klass => mock.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = stub("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    subject.should_receive(:remove_relationship).with('predicate', object)
 
    ac.delete(object)

  end

  it "should call remove_relationship on subject and object when inverse_of given" do
    subject = stub("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = stub(:klass => mock.class, :options=>{:property=>'predicate', :inverse_of => 'inverse_predicate'}, :class_name=> nil)
    ActiveFedora::SolrService.stub(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = stub("object", :new_record? => false, :pid => 'object:b', :save => nil)
  
    subject.should_receive(:remove_relationship).with('predicate', object)
    object.should_receive(:remove_relationship).with('inverse_predicate', subject)
 
    ac.delete(object)

  end

end
