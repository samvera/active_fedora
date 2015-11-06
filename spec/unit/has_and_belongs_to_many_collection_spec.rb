require 'spec_helper'

describe ActiveFedora::Associations::HasAndBelongsToManyAssociation do
  it 'should call add_relationship' do
    subject = double('subject', :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = double(:klass => double.class, :options => {:property => 'predicate'}, :class_name => nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = double('object', :new_record? => false, :pid => 'object:b', :save => nil)

    expect(subject).to receive(:add_relationship).with('predicate', object)

    ac << object

  end

  it 'should call add_relationship on subject and object when inverse_of given' do
    subject = double('subject', :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = double(:klass => double.class, :options => {:property => 'predicate', :inverse_of => 'inverse_predicate'}, :class_name => nil)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    object = double('object', :new_record? => false, :pid => 'object:b', :save => nil)

    expect(subject).to receive(:add_relationship).with('predicate', object)

    expect(object).to receive(:add_relationship).with('inverse_predicate', subject)

    ac << object

  end

  it 'should call solr query multiple times' do

    subject = double('subject', :new_record? => false, :pid => 'subject:a', :internal_uri => 'info:fedora/subject:a', :ids_for_outbound => [])
    predicate = double(:klass => double.class, :options => {:property => 'predicate', solr_page_size: 10}, :class_name => nil)
    ids = []
    0.upto(15) {|i| ids << i.to_s}
    query1 = ids.slice(0, 10).map {|i| "_query_:\"{!raw f=id}#{i}\""}.join(' OR ')
    query2 = ids.slice(10, 10).map {|i| "_query_:\"{!raw f=id}#{i}\""}.join(' OR ')
    expect(subject).to receive(:ids_for_outbound).and_return(ids)
    expect(ActiveFedora::SolrService).to receive(:query).with(query1, {:rows => 10}).and_return([])
    expect(ActiveFedora::SolrService).to receive(:query).with(query2, {:rows => 10}).and_return([])

    ac = ActiveFedora::Associations::HasAndBelongsToManyAssociation.new(subject, predicate)
    ac.find_target
  end
end
