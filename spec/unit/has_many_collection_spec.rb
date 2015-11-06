require 'spec_helper'

describe ActiveFedora::Associations::HasManyAssociation do
  it 'should call add_relationship' do
    subject = double('subject', :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a')
    predicate = double(:klass => double.class, :options => {:property => 'predicate'}, :class_name => nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasManyAssociation.new(subject, predicate)
    object = double('object', :new_record? => false, :pid => 'object:b', :save => nil)

    expect(object).to receive(:add_relationship).with('predicate', subject)

    ac << object

  end

end
