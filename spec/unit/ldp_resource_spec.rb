require 'spec_helper'

describe ActiveFedora::LdpResource do
  let(:obj) { ActiveFedora::Base.create! }
  let!(:r1) { ActiveFedora::LdpResource.new(ActiveFedora.fedora.connection, obj.uri) }
  let!(:r2) { ActiveFedora::LdpResource.new(ActiveFedora.fedora.connection, obj.uri) }

  it "should cache requests" do
    expect_any_instance_of(Faraday::Connection).to receive(:get).once.and_call_original
    ActiveFedora::Base.cache do
      r1.get
      r2.get
    end
  end


end
