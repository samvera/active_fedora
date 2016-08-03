require 'spec_helper'

describe ActiveFedora::Base do
  subject(:object) { described_class.new }
  it { is_expected.not_to be_readonly }

  describe "#readonly!" do
    it "makes the object readonly" do
      expect { object.readonly! }.to change { object.readonly? }.from(false).to(true)
    end
  end

  context "a readonly record" do
    before { object.readonly! }

    it "does not be destroyable" do
      expect { object.destroy }.to raise_error ActiveFedora::ReadOnlyRecord
    end

    it "does not be mutable" do
      expect { object.save }.to raise_error ActiveFedora::ReadOnlyRecord
    end
  end
end
