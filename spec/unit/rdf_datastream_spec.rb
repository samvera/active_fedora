require 'spec_helper'

describe ActiveFedora::RDFDatastream do
  describe '#metadata?' do
    subject { super().metadata? }
    it { is_expected.to be_truthy}
  end
end
