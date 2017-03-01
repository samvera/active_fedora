require 'spec_helper'

describe ActiveFedora::Associations::CollectionProxy do
  before do
    class Book < ActiveFedora::Base
    end
    class Page < ActiveFedora::Base
    end
  end

  after do
    Object.send(:remove_const, :Page)
    Object.send(:remove_const, :Book)
  end

  describe "#spawn" do
    subject { proxy.spawn }

    let(:reflection)  { ActiveFedora::Reflection.create(:has_many, :pages, nil, { predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection }, Book) }
    let(:association) { ActiveFedora::Associations::HasManyAssociation.new(Book.new, reflection) }
    let(:proxy)       { described_class.new(association) }

    it { is_expected.to be_instance_of ActiveFedora::Relation }
  end
end
