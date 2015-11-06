require 'spec_helper'
require 'active_fedora/rubydora_connection'

describe ActiveFedora::RubydoraConnection do
  describe 'initialize' do
    it 'should pass through valid options' do
      @instance = ActiveFedora::RubydoraConnection.new :timeout => 3600, :fake_option => :missing, :force => true, :validateChecksum => true
      expect(@instance.connection.client.options[:timeout]).to eq(3600)
      expect(@instance.connection.config[:validateChecksum]).to eq(true)
      expect(@instance.connection.client.options.has_key?(:fake_option)).to be_falsey
    end
  end
end
