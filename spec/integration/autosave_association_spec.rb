require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class MockAFBaseRelationship < ActiveFedora::Base
      has_metadata :name=>'foo', :type=>Hydra::ModsArticleDatastream
    end
  end
  after :all do
    Object.send(:remove_const, :MockAFBaseRelationship)
  end

  subject { MockAFBaseRelationship.new }

  context '#changed_for_autosave?' do
    before(:each) do
      subject.stub(:new_record?).and_return(false)
      subject.stub(:changed?).and_return(false)
      subject.stub(:marked_for_destruction?).and_return(false)
    end
    it {
      expect { subject.changed_for_autosave? }.to_not raise_error
    }
  end
end
