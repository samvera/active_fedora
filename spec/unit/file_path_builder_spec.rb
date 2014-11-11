require 'spec_helper'

describe ActiveFedora::FilePathBuilder do
  describe ".build" do
    let(:parent) { ActiveFedora::Base.new(id: '1234') }
    subject { ActiveFedora::FilePathBuilder.build(parent, nil, 'FOO') }

    it { should eq 'FOO1' }

    context "when some datastreams exist" do
      before do
        allow(parent).to receive(:attached_files).and_return('FOO56' => double)
      end

      it { should eq 'FOO57' }
    end
  end
end
