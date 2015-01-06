require 'spec_helper'

describe ActiveFedora::Associations::HasManyAssociation do
  it "should call add_relationship" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = double(:klass => double.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasManyAssociation.new(subject, predicate)
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)

    expect(object).to receive(:add_relationship).with('predicate', subject)

    ac << object
  end

  it "should call remove_relationship" do
    subject = double("subject", :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = double(:klass => double.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasManyAssociation.new(subject, predicate)
    object = double("object", :new_record? => false, :pid => 'object:b', :save => nil)

    expect(object).to receive(:remove_relationship).with('predicate', subject)

    ac.delete(object)
  end

  it "should be able to replace the collection" do
    @owner = double(:new_record? => false, :to_ary => nil, :internal_uri => 'info:fedora/changeme:99')
    @reflection = double(:klass => double.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ac = ActiveFedora::Associations::HasManyAssociation.new(@owner, @reflection)
    @target = [double(:to_ary => nil, :new_record? => false, :remove_relationship=>true), double(:to_ary => nil, :new_record? => false, :remove_relationship=>true), double(:to_ary => nil, :new_record? => false, :remove_relationship=>true)]
    ac.target = @target

    @expected1 = double(:new_record? => false, :add_relationship=>true, :save=>true, :to_ary => nil)
    @expected2 = double(:new_record? => false, :add_relationship=>true, :save=>true, :to_ary => nil)
    ac.replace([@expected1, @expected2])
    expect(ac.target).to eq([@expected1, @expected2])
  end

end
