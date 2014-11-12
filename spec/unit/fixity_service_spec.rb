require 'spec_helper'

describe ActiveFedora::FixityService do

  subject { ActiveFedora::FixityService.new("http://path/to/resource") }

  it { is_expected.to respond_to(:target) }
  it { is_expected.to respond_to(:response) }

  describe "#check" do
    context "with a passing result" do
      let(:passing_response) do
        instance_double("Response", body: '<subject> <http://fedora.info/definitions/v4/repository#status> "SUCCESS"^^<http://www.w3.org/2001/XMLSchema#string> .')
      end
      before do
        subject.should_receive(:get_fixity_response_from_fedora).and_return(passing_response)
      end
      specify "returns true" do
        expect(subject.check).to be true
      end

    end

    context "with a failing result" do
      let(:failing_response) do
        instance_double("Response", body: '<subject> <http://fedora.info/definitions/v4/repository#status> "BAD_CHECKSUM"^^<http://www.w3.org/2001/XMLSchema#string> .')
      end
      before do
        subject.should_receive(:get_fixity_response_from_fedora).and_return(failing_response)
      end
      specify "returns false" do
        expect(subject.check).to be false
      end
    end
  end

end
