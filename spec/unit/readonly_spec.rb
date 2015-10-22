require 'spec_helper'

describe ActiveFedora::Base do
  it { is_expected.not_to be_readonly }

  describe "#readonly!" do
    it "makes the object readonly" do
      expect { subject.readonly! }.to change { subject.readonly? }.from(false).to(true)
    end
  end

  context "a readonly record" do
    before { subject.readonly! }

    it "does not be destroyable" do
      expect { subject.destroy }.to raise_error ActiveFedora::ReadOnlyRecord
    end

    it "does not be mutable" do
      expect { subject.save }.to raise_error ActiveFedora::ReadOnlyRecord
    end
  end
end
