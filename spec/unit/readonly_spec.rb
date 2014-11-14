require 'spec_helper'

describe ActiveFedora::Base do
  it { is_expected.not_to be_readonly }

  describe "#readonly!" do
    it "should make the object readonly" do
      expect { subject.readonly! }.to change { subject.readonly? }.from(false).to(true)
    end
  end

  context "a readonly record" do
    before { subject.readonly! }

    it "should not be destroyable" do
      expect { subject.destroy }.to raise_error ActiveFedora::ReadOnlyRecord
    end

    it "should not be mutable" do
      expect { subject.save }.to raise_error ActiveFedora::ReadOnlyRecord
    end
  end
end
