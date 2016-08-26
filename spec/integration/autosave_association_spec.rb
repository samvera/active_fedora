require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class MockAFBaseRelationship < ActiveFedora::Base
    end
  end
  after :all do
    Object.send(:remove_const, :MockAFBaseRelationship)
  end

  subject(:relationship) { MockAFBaseRelationship.new }

  context '#changed_for_autosave?' do
    before do
      expect(relationship).to receive(:new_record?).and_return(false)
      expect(relationship).to receive(:changed?).and_return(false)
      expect(relationship).to receive(:marked_for_destruction?).and_return(false)
    end
    it {
      expect { relationship.changed_for_autosave? }.to_not raise_error
    }
  end
end
