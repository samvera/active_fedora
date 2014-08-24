require 'spec_helper'

describe "Writing to the same node concurrently" do
  before do
    class GenericFile < ActiveFedora::Base
      property :title, predicate: RDF::DC.title
    end
  end

  after { Object.send(:remove_const, :GenericFile) }

  subject { GenericFile.create }

  let(:f1) { GenericFile.find(subject.id) }
  let(:f2) { GenericFile.find(subject.id) }

  it "raises an error" do
    skip "waiting on https://github.com/fcrepo4/fcrepo4/issues/442"

    f1.title = "foo"
    f2.title = "bar"
    f1.save
    expect {
      f2.save
    }.to raise_error # ConcurrentModificationError
  end

end
