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
  
end
