require 'spec_helper'

describe ActiveFedora::Base do

  before(:all) do
    class ResurrectionModel < ActiveFedora::Base
      after_destroy :eradicate
    end
  end

  after(:all) do
    Object.send(:remove_const, :ResurrectionModel)
  end

  context "when an object is has already been deleted" do
    let(:ghost) do
      obj = ActiveFedora::Base.create
      obj.destroy
      obj.id
    end
    context "in a typical sitation" do
      specify "it cannot be reused" do
        expect { ActiveFedora::Base.create(ghost) }.to raise_error(Ldp::Gone)
      end
    end
    specify "remove its tombstone" do
      expect(ActiveFedora::Base.eradicate(ghost)).to be true
    end
  end

  context "when an object has just been deleted" do
    let(:zombie) do
      obj = ActiveFedora::Base.create
      obj.destroy
      return obj
    end
    specify "remove its tombstone" do
      expect(zombie.eradicate).to be true
    end
  end

  describe "a model with no tombstones" do
    let(:lazarus) do
      body = ResurrectionModel.create
      soul = body.id
      body.destroy
      return soul
    end
    it "should allow reusing a uri" do
      expect(ResurrectionModel.create(id: lazarus)).to be_kind_of(ResurrectionModel)
    end
  end

end
