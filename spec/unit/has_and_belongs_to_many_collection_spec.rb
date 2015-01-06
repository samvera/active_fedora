require 'spec_helper'

describe ActiveFedora::Associations::HasAndBelongsToManyAssociation do
  it "should call add_relationship" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = double(:klass => double.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)

    expect(subject).to receive(:add_relationship).with('predicate', object)

    ac << object

  end

  it "should call add_relationship on subject and object when inverse_of given" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = double(:klass => double.class, :options=>{:property=>'predicate', :inverse_of => 'inverse_predicate'}, :class_name=> nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)

    expect(subject).to receive(:add_relationship).with('predicate', object)

    expect(object).to receive(:add_relationship).with('inverse_predicate', subject)

    ac << object

  end

  it "should call remove_relationship" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = double(:klass => double.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)

    expect(subject).to receive(:remove_relationship).with('predicate', object)

    ac.delete(object)

  end

  it "should call remove_relationship on subject and object when inverse_of given" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = double(:klass => double.class, :options=>{:property=>'predicate', :inverse_of => 'inverse_predicate'}, :class_name=> nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)

    expect(subject).to receive(:remove_relationship).with('predicate', object)
    expect(object).to receive(:remove_relationship).with('inverse_predicate', subject)

    ac.delete(object)

  end

end
