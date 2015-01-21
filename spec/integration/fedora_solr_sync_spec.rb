require 'spec_helper'
require 'timeout'

describe "fedora_solr_sync_issues" do
  before :all do
    class ParentThing < ActiveFedora::Base
      has_many :things, :class_name=>'ChildThing', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end

    class ChildThing < ActiveFedora::Base
      belongs_to :parent, :class_name=>'ParentThing', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
    end
  end

  after :all do
    Object.send(:remove_const, :ChildThing)
    Object.send(:remove_const, :ParentThing)
  end

  let(:parent) { ParentThing.create }
  subject { ChildThing.create parent: parent }

  before { Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, subject.uri).delete }

  it "should not go into an infinite loop" do
    parent.reload
    expect(ActiveFedora::Base.logger).to receive(:error).with("Solr and Fedora may be out of sync:\n")
    expect(parent.things).to eq []
  end
end
