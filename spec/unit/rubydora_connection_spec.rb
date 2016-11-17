require 'spec_helper'
require 'active_fedora/rubydora_connection'

describe ActiveFedora::RubydoraConnection do
  describe 'initialize' do
    it "should pass through options" do
      @instance = ActiveFedora::RubydoraConnection.new :timeout => 3600, :force => true, :validateChecksum=>true
      expect(@instance.connection.client.options[:timeout]).to eq(3600)
      expect(@instance.connection.config[:validateChecksum]).to eq(true)
    end
  end
end
